import '../interfaces/playerctl_interfaces.dart';
import 'command_executor.dart';

/// Playback controller for media playback operations
/// Follows Single Responsibility Principle
class PlaybackController implements IPlaybackController {
  final PlayerctlCommandExecutor _executor;

  PlaybackController(this._executor);

  @override
  Future<bool> play([String? player]) async {
    return _executor.executeCommand('play', player);
  }

  @override
  Future<bool> pause([String? player]) async {
    return _executor.executeCommand('pause', player);
  }

  @override
  Future<bool> stop([String? player]) async {
    return _executor.executeCommand('stop', player);
  }

  @override
  Future<bool> playPause([String? player]) async {
    return _executor.executeCommand('play-pause', player);
  }

  @override
  Future<bool> next([String? player]) async {
    return _executor.executeCommand('next', player);
  }

  @override
  Future<bool> previous([String? player]) async {
    return _executor.executeCommand('previous', player);
  }

  /// Get shuffle status
  Future<String?> getShuffle([String? player]) async {
    return _executor.executeCommandWithOutput('shuffle', player);
  }

  /// Set shuffle status (On/Off)
  Future<bool> setShuffle(String status, [String? player]) async {
    final args = player != null
        ? ['--player=$player', 'shuffle', status]
        : ['shuffle', status];
    return _executor.executeCommandWithArgs(args);
  }

  /// Toggle shuffle
  Future<bool> toggleShuffle([String? player]) async {
    final current = await getShuffle(player);
    if (current == null) return false;

    final newStatus = current.trim().toLowerCase() == 'on' ? 'Off' : 'On';
    return setShuffle(newStatus, player);
  }

  /// Get loop status
  Future<String?> getLoop([String? player]) async {
    return _executor.executeCommandWithOutput('loop', player);
  }

  /// Set loop status (None/Track/Playlist)
  Future<bool> setLoop(String status, [String? player]) async {
    final args = player != null
        ? ['--player=$player', 'loop', status]
        : ['loop', status];
    return _executor.executeCommandWithArgs(args);
  }

  /// Cycle through loop modes: None → Track → Playlist → None
  Future<bool> cycleLoop([String? player]) async {
    final current = await getLoop(player);
    if (current == null) return false;

    final currentTrimmed = current.trim();
    String newStatus;
    if (currentTrimmed == 'None') {
      newStatus = 'Track';
    } else if (currentTrimmed == 'Track') {
      newStatus = 'Playlist';
    } else {
      newStatus = 'None';
    }

    return setLoop(newStatus, player);
  }
}
