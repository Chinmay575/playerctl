import 'dart:async';
import 'package:flutter/material.dart';

import '../models/media_info.dart';
import '../services/playerctl_service.dart';
import '../core/exceptions.dart';
import '../core/player_state.dart';
import '../core/logger.dart';

/// State-management-agnostic media player manager
/// This class provides a clean API without forcing any specific state management solution
/// Users can wrap this with their preferred state management (GetX, Riverpod, Bloc, etc.)
class MediaPlayerManager {
  final PlayerctlService _service;

  // Internal state
  PlayerState _state = PlayerState.initial();

  // Stream controllers for reactive updates
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();

  StreamSubscription? _metadataSubscription;
  Timer? _playerCheckTimer;
  Timer? _volumeSyncTimer;
  Timer? _metadataRefreshTimer;
  bool _isRefreshing = false;

  /// Constructor with optional dependency injection
  ///
  /// [service] - Optional PlayerctlService instance for dependency injection
  /// [logLevel] - Optional log level (none, error, warning, info, debug).
  ///              Defaults to debug in debug mode, error in release mode.
  MediaPlayerManager({PlayerctlService? service, LogLevel? logLevel})
    : _service = service ?? PlayerctlService() {
    if (logLevel != null) {
      PlayerctlLogger.level = logLevel;
    }
  }

  /// Get current state (synchronous)
  PlayerState get state => _state;

  /// Stream of state changes (for reactive programming)
  Stream<PlayerState> get stateStream => _stateController.stream;

  /// Get current media info
  MediaInfo get currentMedia => _state.currentMedia;

  /// Check if playerctl is installed
  bool get isPlayerctlInstalled => _state.isPlayerctlInstalled;

  /// Check if there's an active player
  bool get hasActivePlayer => _state.hasActivePlayer;

  /// Get list of available players
  List<String> get availablePlayers => _state.availablePlayers;

  /// Get selected player
  String get selectedPlayer => _state.selectedPlayer;

  /// Check if loading
  bool get isLoading => _state.isLoading;

  /// Get error message
  String get errorMessage => _state.errorMessage;

  /// Get current volume
  int get volume => _state.volume;

  /// Get current log level
  LogLevel get logLevel => PlayerctlLogger.level;

  /// Set log level at runtime
  ///
  /// This allows you to change the verbosity of logs without restarting the app.
  /// Useful for user-configurable logging in settings.
  ///
  /// Example:
  /// ```dart
  /// manager.setLogLevel(LogLevel.info); // Show info and above
  /// manager.setLogLevel(LogLevel.error); // Only show errors
  /// ```
  void setLogLevel(LogLevel level) {
    PlayerctlLogger.level = level;
    PlayerctlLogger.info('Log level changed to: ${level.name}', 'Config');
  }

  /// Initialize the manager
  Future<void> initialize() async {
    try {
      _updateState(_state.copyWith(isLoading: true, errorMessage: ''));

      // Check if playerctl is installed
      final installed = await _service.isPlayerctlInstalled();
      _updateState(_state.copyWith(isPlayerctlInstalled: installed));

      if (!installed) {
        _updateState(
          _state.copyWith(
            errorMessage:
                'playerctl is not installed on this system.\n'
                'Please install it using:\n'
                'sudo apt install playerctl (Debian/Ubuntu)\n'
                'sudo pacman -S playerctl (Arch)\n'
                'sudo dnf install playerctl (Fedora)',
            isLoading: false,
          ),
        );
        return;
      }

      // Get playerctl version for debugging
      final version = await _service.getPlayerctlVersion();
      PlayerctlLogger.info('Playerctl version: $version', 'Init');

      // Check for active players
      await refreshPlayerList();

      // Start listening if we have active players
      if (_state.hasActivePlayer) {
        startListening();
        await updateCurrentVolume();
        await updateShuffleStatus();
        await updateLoopStatus();
        _startVolumeSync();
        _startMetadataRefresh();
      }

      // Start periodic player check (every 5 seconds)
      _startPlayerCheck();

      _updateState(_state.copyWith(isLoading: false));
    } catch (e) {
      _updateState(
        _state.copyWith(
          errorMessage: 'Error initializing: $e',
          isLoading: false,
        ),
      );
    }
  }

  /// Refresh the list of available players
  Future<void> refreshPlayerList() async {
    // Prevent concurrent refreshes
    if (_isRefreshing) {
      PlayerctlLogger.debug(
        'Skipping refresh - already in progress',
        'Refresh',
      );
      return;
    }

    _isRefreshing = true;
    try {
      final players = await _service.getAvailablePlayers();
      final hasPlayer = players.isNotEmpty;
      final previousSelected = _state.selectedPlayer;

      String selected = _state.selectedPlayer;
      bool needsReconnect = false;

      // Case 1: No players available
      if (players.isEmpty) {
        selected = '';
        PlayerctlLogger.player('No players available');
      }
      // Case 2: First time selecting a player
      else if (selected.isEmpty) {
        selected = players.first;
        needsReconnect = true;
        PlayerctlLogger.player('Auto-selecting first player: $selected');
      }
      // Case 3: Currently selected player no longer exists
      else if (!players.contains(selected)) {
        selected = players.first;
        needsReconnect = true;
        PlayerctlLogger.player(
          'Selected player "$previousSelected" no longer available, switching to: $selected',
        );
      }
      // Case 4: Selected player still exists (no change needed)
      else {
        PlayerctlLogger.debug(
          'Current player "$selected" still available',
          'Player',
        );
      }

      _updateState(
        _state.copyWith(
          availablePlayers: players,
          hasActivePlayer: hasPlayer,
          selectedPlayer: selected,
          currentMedia: hasPlayer ? _state.currentMedia : MediaInfo.empty(),
        ),
      );

      // If we switched to a different player, reconnect
      if (needsReconnect && hasPlayer && selected != previousSelected) {
        PlayerctlLogger.player('Reconnecting to new player: $selected');

        // Stop all current syncing
        stopListening();
        _stopVolumeSync();
        _stopMetadataRefresh();

        // Small delay to ensure clean disconnect
        await Future.delayed(const Duration(milliseconds: 100));

        // Fetch metadata immediately for new player
        try {
          final metadata = await _service.getCurrentMetadata(selected);
          if (metadata.isNotEmpty) {
            _updateMediaInfo(metadata);
          }
        } catch (e) {
          PlayerctlLogger.error(
            'Error fetching metadata for player $selected',
            'Player',
            e,
          );
        }

        // Fetch current state
        await updateCurrentVolume();
        await updateShuffleStatus();
        await updateLoopStatus();

        // Start listening and all sync timers
        startListening(selected);
        _startVolumeSync();
        _startMetadataRefresh();
      }
    } catch (e) {
      PlayerctlLogger.error('Error refreshing player list', 'Player', e);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Start periodic check for player availability
  void _startPlayerCheck() {
    _playerCheckTimer?.cancel();
    _playerCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final hadPlayers = _state.hasActivePlayer;
      await refreshPlayerList();

      // If we just got a player, start listening
      if (!hadPlayers && _state.hasActivePlayer) {
        startListening();
        await updateCurrentVolume();
        _startVolumeSync();
        _startMetadataRefresh();
      }
      // If we lost all players, stop listening
      else if (hadPlayers && !_state.hasActivePlayer) {
        stopListening();
        _stopVolumeSync();
        _stopMetadataRefresh();
      }
    });
  }

  /// Start periodic volume synchronization
  void _startVolumeSync() {
    _volumeSyncTimer?.cancel();
    PlayerctlLogger.sync('Starting volume sync timer', 'Volume');
    _volumeSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      PlayerctlLogger.debug(
        'Volume sync timer tick - hasActivePlayer: ${_state.hasActivePlayer}, selectedPlayer: ${_state.selectedPlayer}',
        'Volume',
      );
      if (_state.hasActivePlayer) {
        PlayerctlLogger.debug('Calling updateCurrentVolume...', 'Volume');
        await updateCurrentVolume();
        PlayerctlLogger.debug('updateCurrentVolume completed', 'Volume');
      } else {
        PlayerctlLogger.debug(
          'Skipping volume sync - no active player',
          'Volume',
        );
      }
    });
  }

  /// Stop volume synchronization
  void _stopVolumeSync() {
    _volumeSyncTimer?.cancel();
    _volumeSyncTimer = null;
  }

  /// Start periodic metadata refresh (fallback for when stream doesn't update)
  void _startMetadataRefresh() {
    _metadataRefreshTimer?.cancel();
    PlayerctlLogger.sync('Starting metadata refresh timer', 'Metadata');
    _metadataRefreshTimer = Timer.periodic(const Duration(seconds: 3), (
      _,
    ) async {
      if (_state.hasActivePlayer) {
        PlayerctlLogger.debug(
          'Refreshing metadata for player: ${_state.selectedPlayer}',
          'Metadata',
        );
        try {
          final player = _state.selectedPlayer.isNotEmpty
              ? _state.selectedPlayer
              : null;
          final metadata = await _service.getCurrentMetadata(player);
          if (metadata.isNotEmpty) {
            _updateMediaInfo(metadata);
          }
        } catch (e) {
          PlayerctlLogger.error('Error refreshing metadata', 'Metadata', e);
        }
      }
    });
  }

  /// Stop metadata refresh
  void _stopMetadataRefresh() {
    _metadataRefreshTimer?.cancel();
    _metadataRefreshTimer = null;
  }

  /// Start listening to metadata changes
  void startListening([String? player]) {
    final targetPlayer =
        player ??
        (_state.selectedPlayer.isNotEmpty ? _state.selectedPlayer : null);

    _metadataSubscription?.cancel();
    _metadataSubscription = _service
        .listenToMetadata(targetPlayer)
        .listen(
          (metadata) {
            _updateMediaInfo(metadata);
          },
          onError: (error) {
            if (error is NoPlayerException) {
              _updateState(
                _state.copyWith(
                  currentMedia: MediaInfo.empty(),
                  hasActivePlayer: false,
                  errorMessage: 'No active media players found',
                ),
              );
            } else {
              PlayerctlLogger.error('Metadata stream error', 'Stream', error);
              _updateState(_state.copyWith(errorMessage: error.toString()));
            }
          },
          onDone: () {
            // Stream completed/closed - this might indicate process exit
            PlayerctlLogger.info(
              'Metadata stream closed, will check for active players',
              'Stream',
            );
            // The periodic player check will handle reconnection if players are still available
          },
          cancelOnError: false, // Don't cancel on errors, let it try to recover
        );
  }

  /// Stop listening to metadata changes
  void stopListening() {
    _metadataSubscription?.cancel();
    _metadataSubscription = null;
    _service.stopListening();
  }

  /// Update media info from metadata map
  void _updateMediaInfo(Map<String, String> metadata) {
    if (metadata.isEmpty) return;

    final media = MediaInfo(
      title: metadata['title'] ?? 'Unknown',
      artist: metadata['artist'] ?? 'Unknown',
      album: metadata['album'] ?? 'Unknown',
      status: metadata['status'] ?? 'Stopped',
      playerName: metadata['playerName'] ?? 'Unknown',
      position: int.tryParse(metadata['position'] ?? '0'),
      length: int.tryParse(metadata['length'] ?? '0'),
      artUrl: metadata['artUrl']?.isNotEmpty == true
          ? metadata['artUrl']
          : null,
    );

    PlayerctlLogger.metadata(
      'Received - Player: ${media.playerName}, Title: ${media.title}, Selected: ${_state.selectedPlayer}',
    );

    // Only update currentMedia if this metadata is from the selected player
    // This prevents other players' metadata from overwriting the current display
    final isSelectedPlayer =
        _state.selectedPlayer.isEmpty ||
        media.playerName == _state.selectedPlayer ||
        // Also match base player name (e.g., "brave" matches "brave.instance123")
        media.playerName.startsWith('${_state.selectedPlayer}.') ||
        // Also match if selected player starts with base name (e.g., "brave.instance123" matches "brave")
        _state.selectedPlayer.startsWith('${media.playerName}.');

    PlayerctlLogger.debug('isSelectedPlayer: $isSelectedPlayer', 'Metadata');

    if (isSelectedPlayer) {
      PlayerctlLogger.success(
        'Updating media info: ${media.title} by ${media.artist}',
        'Metadata',
      );
      _updateState(_state.copyWith(currentMedia: media, errorMessage: ''));
    } else {
      PlayerctlLogger.warning(
        'Ignoring metadata from ${media.playerName} (selected: ${_state.selectedPlayer})',
        'Metadata',
      );
    }
  }

  /// Pause all other players except the specified one
  Future<void> _pauseOtherPlayers([String? exceptPlayer]) async {
    try {
      final currentPlayer =
          exceptPlayer ??
          (_state.selectedPlayer.isNotEmpty ? _state.selectedPlayer : null);

      if (currentPlayer == null) return;

      // Get all available players
      final allPlayers = _state.availablePlayers;

      for (final player in allPlayers) {
        // Skip the current player
        if (player == currentPlayer) continue;

        // Check if this player is playing
        try {
          final metadata = await _service.getCurrentMetadata(player);
          final status = metadata['status'] ?? '';

          if (status.toLowerCase() == 'playing') {
            debugPrint('⏸️ Auto-pausing other player: $player');
            await _service.pause(player);
          }
        } catch (e) {
          debugPrint('Error checking/pausing player $player: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in _pauseOtherPlayers: $e');
    }
  }

  /// Switch to a different player
  Future<void> switchPlayer(String playerName) async {
    if (!_state.availablePlayers.contains(playerName)) {
      _updateState(
        _state.copyWith(errorMessage: 'Player $playerName is not available'),
      );
      return;
    }

    // Clear current media and set loading state immediately
    _updateState(
      _state.copyWith(
        selectedPlayer: playerName,
        isLoading: true,
        currentMedia: MediaInfo.empty(), // Clear stale data immediately
      ),
    );

    // Stop current listener and all timers
    stopListening();
    _stopVolumeSync();
    _stopMetadataRefresh();

    // Small delay to ensure clean state
    await Future.delayed(const Duration(milliseconds: 50));

    // Fetch current metadata immediately for the new player
    try {
      final metadata = await _service.getCurrentMetadata(playerName);
      if (metadata.isNotEmpty) {
        // Force update media directly, bypassing the player check
        final media = MediaInfo(
          title: metadata['title'] ?? 'Unknown',
          artist: metadata['artist'] ?? 'Unknown',
          album: metadata['album'] ?? 'Unknown',
          status: metadata['status'] ?? 'Stopped',
          playerName: metadata['playerName'] ?? 'Unknown',
          position: int.tryParse(metadata['position'] ?? '0'),
          length: int.tryParse(metadata['length'] ?? '0'),
          artUrl: metadata['artUrl']?.isNotEmpty == true
              ? metadata['artUrl']
              : null,
        );
        _updateState(_state.copyWith(currentMedia: media, errorMessage: ''));
        debugPrint('✅ Fetched initial metadata for $playerName');
      }
    } catch (e) {
      debugPrint('Error fetching metadata for player $playerName: $e');
    }

    // Fetch current volume, shuffle, and loop status for the new player
    await updateCurrentVolume();
    await updateShuffleStatus();
    await updateLoopStatus();

    // Start listening to the new player
    startListening(playerName);

    // Restart volume sync and metadata refresh for the new player
    _startVolumeSync();
    _startMetadataRefresh();

    _updateState(_state.copyWith(isLoading: false));
  }

  /// Play/Pause toggle - pauses other players when starting playback
  Future<bool> playPause() async {
    final currentPlayer = _state.selectedPlayer.isNotEmpty
        ? _state.selectedPlayer
        : null;

    // Check current status to determine if we're about to play
    final currentStatus = _state.currentMedia.status;
    final willPlay = currentStatus != 'Playing';

    // If we're about to play, pause other players first
    if (willPlay) {
      await _pauseOtherPlayers(currentPlayer);
    }

    final success = await _service.playPause(currentPlayer);
    if (!success) {
      _updateState(
        _state.copyWith(errorMessage: 'Failed to toggle play/pause'),
      );
    }
    return success;
  }

  /// Play - pauses other players when starting playback
  Future<bool> play() async {
    final currentPlayer = _state.selectedPlayer.isNotEmpty
        ? _state.selectedPlayer
        : null;

    // Pause other players before playing
    await _pauseOtherPlayers(currentPlayer);

    final success = await _service.play(currentPlayer);
    if (!success) {
      _updateState(_state.copyWith(errorMessage: 'Failed to play'));
    }
    return success;
  }

  /// Pause
  Future<bool> pause() async {
    final success = await _service.pause(
      _state.selectedPlayer.isNotEmpty ? _state.selectedPlayer : null,
    );
    if (!success) {
      _updateState(_state.copyWith(errorMessage: 'Failed to pause'));
    }
    return success;
  }

  /// Stop
  Future<bool> stop() async {
    final success = await _service.stop(
      _state.selectedPlayer.isNotEmpty ? _state.selectedPlayer : null,
    );
    if (!success) {
      _updateState(_state.copyWith(errorMessage: 'Failed to stop'));
    }
    return success;
  }

  /// Next track - pauses other players when skipping
  Future<bool> next() async {
    final currentPlayer = _state.selectedPlayer.isNotEmpty
        ? _state.selectedPlayer
        : null;

    // Pause other players before going to next track
    await _pauseOtherPlayers(currentPlayer);

    final success = await _service.next(currentPlayer);
    if (!success) {
      _updateState(
        _state.copyWith(errorMessage: 'Failed to skip to next track'),
      );
    }
    return success;
  }

  /// Previous track - pauses other players when skipping
  Future<bool> previous() async {
    final currentPlayer = _state.selectedPlayer.isNotEmpty
        ? _state.selectedPlayer
        : null;

    // Pause other players before going to previous track
    await _pauseOtherPlayers(currentPlayer);

    final success = await _service.previous(currentPlayer);
    if (!success) {
      _updateState(
        _state.copyWith(errorMessage: 'Failed to skip to previous track'),
      );
    }
    return success;
  }

  /// Get current playback position in microseconds
  Future<int?> getPosition() async {
    try {
      final player = _state.selectedPlayer.isNotEmpty
          ? _state.selectedPlayer
          : null;
      return await _service.getPosition(player);
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
    }
  }

  /// Seek to absolute position in microseconds
  Future<bool> seekTo(int positionMicroseconds) async {
    try {
      final player = _state.selectedPlayer.isNotEmpty
          ? _state.selectedPlayer
          : null;
      return await _service.seekTo(positionMicroseconds, player);
    } catch (e) {
      debugPrint('Error seeking to position: $e');
      _updateState(_state.copyWith(errorMessage: 'Failed to seek'));
      return false;
    }
  }

  /// Seek relative to current position (positive = forward, negative = backward)
  Future<bool> seek(int offsetMicroseconds) async {
    try {
      final player = _state.selectedPlayer.isNotEmpty
          ? _state.selectedPlayer
          : null;
      return await _service.seek(offsetMicroseconds, player);
    } catch (e) {
      debugPrint('Error seeking: $e');
      _updateState(_state.copyWith(errorMessage: 'Failed to seek'));
      return false;
    }
  }

  /// Skip forward by specified number of seconds
  Future<bool> seekForward(int seconds) async {
    try {
      final player = _state.selectedPlayer.isNotEmpty
          ? _state.selectedPlayer
          : null;
      return await _service.seekForward(seconds, player);
    } catch (e) {
      debugPrint('Error seeking forward: $e');
      _updateState(_state.copyWith(errorMessage: 'Failed to seek forward'));
      return false;
    }
  }

  /// Skip backward by specified number of seconds
  Future<bool> seekBackward(int seconds) async {
    try {
      final player = _state.selectedPlayer.isNotEmpty
          ? _state.selectedPlayer
          : null;
      return await _service.seekBackward(seconds, player);
    } catch (e) {
      debugPrint('Error seeking backward: $e');
      _updateState(_state.copyWith(errorMessage: 'Failed to seek backward'));
      return false;
    }
  }

  /// Toggle shuffle
  Future<bool> toggleShuffle() async {
    final player = _state.selectedPlayer.isNotEmpty
        ? _state.selectedPlayer
        : null;
    final success = await _service.toggleShuffle(player);
    if (success) {
      await updateShuffleStatus();
    } else {
      _updateState(_state.copyWith(errorMessage: 'Failed to toggle shuffle'));
    }
    return success;
  }

  /// Cycle through loop modes (None → Track → Playlist → None)
  Future<bool> cycleLoop() async {
    final player = _state.selectedPlayer.isNotEmpty
        ? _state.selectedPlayer
        : null;
    final success = await _service.cycleLoop(player);
    if (success) {
      await updateLoopStatus();
    } else {
      _updateState(_state.copyWith(errorMessage: 'Failed to cycle loop mode'));
    }
    return success;
  }

  /// Update shuffle status from player
  Future<void> updateShuffleStatus() async {
    try {
      final player = _state.selectedPlayer.isNotEmpty
          ? _state.selectedPlayer
          : null;
      final shuffleStatus = await _service.getShuffle(player);

      if (shuffleStatus != null) {
        _updateState(_state.copyWith(shuffleStatus: shuffleStatus.trim()));
      }
    } catch (e) {
      debugPrint('Error updating shuffle status: $e');
      _updateState(_state.copyWith(shuffleStatus: 'Unknown'));
    }
  }

  /// Update loop status from player
  Future<void> updateLoopStatus() async {
    try {
      final player = _state.selectedPlayer.isNotEmpty
          ? _state.selectedPlayer
          : null;
      final loopStatus = await _service.getLoop(player);

      if (loopStatus != null) {
        _updateState(_state.copyWith(loopStatus: loopStatus.trim()));
      }
    } catch (e) {
      debugPrint('Error updating loop status: $e');
      _updateState(_state.copyWith(loopStatus: 'Unknown'));
    }
  }

  /// Set volume (0-100)
  Future<bool> setVolume(int newVolume) async {
    final success = await _service.setVolume(
      newVolume,
      _state.selectedPlayer.isNotEmpty ? _state.selectedPlayer : null,
    );
    if (success) {
      _updateState(_state.copyWith(volume: newVolume));
    } else {
      _updateState(_state.copyWith(errorMessage: 'Failed to set volume'));
    }
    return success;
  }

  /// Get current volume
  Future<void> updateCurrentVolume() async {
    try {
      final player = _state.selectedPlayer.isNotEmpty
          ? _state.selectedPlayer
          : null;
      debugPrint('Fetching volume for player: $player');

      final currentVolume = await _service.getVolume(player);

      debugPrint('Volume fetched: $currentVolume (previous: ${_state.volume})');

      if (currentVolume != null) {
        _updateState(_state.copyWith(volume: currentVolume));
      }
    } catch (e) {
      debugPrint('Error updating volume: $e');
    }
  }

  /// Retry initialization if it failed
  Future<void> retry() async {
    await initialize();
  }

  /// Update state and notify listeners
  void _updateState(PlayerState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Dispose resources
  void dispose() {
    _metadataSubscription?.cancel();
    _playerCheckTimer?.cancel();
    _volumeSyncTimer?.cancel();
    _metadataRefreshTimer?.cancel();
    _service.dispose();
    _stateController.close();
  }
}
