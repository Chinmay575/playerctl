import '../interfaces/playerctl_interfaces.dart';
import 'command_executor.dart';
import 'system_checker.dart';
import 'player_detector.dart';
import 'metadata_provider.dart';
import 'playback_controller.dart';
import 'volume_controller.dart';

/// Facade service that provides a unified interface to all playerctl operations
/// Follows Facade Pattern and Dependency Inversion Principle
///
/// This class delegates to specialized services, each with a single responsibility
class PlayerctlService
    implements
        IPlayerctlService,
        IPlayerDetector,
        IMetadataProvider,
        IPlaybackController,
        IVolumeController,
        ICommandExecutor {
  late final PlayerctlCommandExecutor _commandExecutor;
  late final PlayerctlSystemChecker _systemChecker;
  late final PlayerDetector _playerDetector;
  late final MetadataProvider _metadataProvider;
  late final PlaybackController _playbackController;
  late final VolumeController _volumeController;

  /// Default constructor - creates all dependencies
  PlayerctlService() {
    _commandExecutor = PlayerctlCommandExecutor();
    _systemChecker = PlayerctlSystemChecker();
    _playerDetector = PlayerDetector();
    _metadataProvider = MetadataProvider();
    _playbackController = PlaybackController(_commandExecutor);
    _volumeController = VolumeController(_commandExecutor);
  }

  /// Constructor with dependency injection for testing
  /// Follows Dependency Inversion Principle
  PlayerctlService.withDependencies({
    required PlayerctlCommandExecutor commandExecutor,
    required PlayerctlSystemChecker systemChecker,
    required PlayerDetector playerDetector,
    required MetadataProvider metadataProvider,
    required PlaybackController playbackController,
    required VolumeController volumeController,
  }) : _commandExecutor = commandExecutor,
       _systemChecker = systemChecker,
       _playerDetector = playerDetector,
       _metadataProvider = metadataProvider,
       _playbackController = playbackController,
       _volumeController = volumeController;

  // IPlayerctlService implementation
  @override
  Future<bool> isPlayerctlInstalled() => _systemChecker.isPlayerctlInstalled();

  @override
  Future<String?> getPlayerctlVersion() => _systemChecker.getPlayerctlVersion();

  Future<void> ensurePlayerctlInstalled() =>
      _systemChecker.ensurePlayerctlInstalled();

  // IPlayerDetector implementation
  @override
  Future<bool> hasActivePlayer() => _playerDetector.hasActivePlayer();

  @override
  Future<List<String>> getAvailablePlayers() =>
      _playerDetector.getAvailablePlayers();

  Future<String?> getActivePlayerName() =>
      _playerDetector.getActivePlayerName();

  Future<bool> isPlayerAvailable(String playerName) =>
      _playerDetector.isPlayerAvailable(playerName);

  // IMetadataProvider implementation
  @override
  Future<Map<String, String>> getCurrentMetadata([String? player]) =>
      _metadataProvider.getCurrentMetadata(player);

  @override
  Stream<Map<String, String>> listenToMetadata([String? player]) =>
      _metadataProvider.listenToMetadata(player);

  @override
  Future<void> stopListening() => _metadataProvider.stopListening();

  // IPlaybackController implementation
  @override
  Future<bool> play([String? player]) => _playbackController.play(player);

  @override
  Future<bool> pause([String? player]) => _playbackController.pause(player);

  @override
  Future<bool> stop([String? player]) => _playbackController.stop(player);

  @override
  Future<bool> playPause([String? player]) =>
      _playbackController.playPause(player);

  @override
  Future<bool> next([String? player]) => _playbackController.next(player);

  @override
  Future<bool> previous([String? player]) =>
      _playbackController.previous(player);

  // Shuffle and Loop control
  Future<String?> getShuffle([String? player]) =>
      _playbackController.getShuffle(player);

  Future<bool> setShuffle(String status, [String? player]) =>
      _playbackController.setShuffle(status, player);

  Future<bool> toggleShuffle([String? player]) =>
      _playbackController.toggleShuffle(player);

  Future<String?> getLoop([String? player]) =>
      _playbackController.getLoop(player);

  Future<bool> setLoop(String status, [String? player]) =>
      _playbackController.setLoop(status, player);

  Future<bool> cycleLoop([String? player]) =>
      _playbackController.cycleLoop(player);

  // IVolumeController implementation
  @override
  Future<bool> setVolume(int volume, [String? player]) =>
      _volumeController.setVolume(volume, player);

  @override
  Future<int?> getVolume([String? player]) =>
      _volumeController.getVolume(player);

  Future<bool> increaseVolume(int percentage, [String? player]) =>
      _volumeController.increaseVolume(percentage, player);

  Future<bool> decreaseVolume(int percentage, [String? player]) =>
      _volumeController.decreaseVolume(percentage, player);

  Future<bool> mute([String? player]) => _volumeController.mute(player);

  // Seek operations
  Future<int?> getPosition([String? player]) =>
      _playbackController.getPosition(player);

  Future<bool> seekTo(int positionMicroseconds, [String? player]) =>
      _playbackController.seekTo(positionMicroseconds, player);

  Future<bool> seek(int offsetMicroseconds, [String? player]) =>
      _playbackController.seek(offsetMicroseconds, player);

  Future<bool> seekForward(int seconds, [String? player]) =>
      _playbackController.seekForward(seconds, player);

  Future<bool> seekBackward(int seconds, [String? player]) =>
      _playbackController.seekBackward(seconds, player);

  // ICommandExecutor implementation
  @override
  Future<bool> executeCommand(String command, [String? player]) =>
      _commandExecutor.executeCommand(command, player);

  /// Cleanup all resources
  void dispose() {
    _metadataProvider.dispose();
  }
}
