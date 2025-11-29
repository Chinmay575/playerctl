/// Base interface for all playerctl-related operations
abstract class IPlayerctlService {
  Future<bool> isPlayerctlInstalled();
  Future<String?> getPlayerctlVersion();
}

/// Interface for player detection operations
abstract class IPlayerDetector {
  Future<bool> hasActivePlayer();
  Future<List<String>> getAvailablePlayers();
}

/// Interface for metadata operations
abstract class IMetadataProvider {
  Future<Map<String, String>> getCurrentMetadata([String? player]);
  Stream<Map<String, String>> listenToMetadata([String? player]);
  Future<void> stopListening();
}

/// Interface for playback control operations
abstract class IPlaybackController {
  Future<bool> play([String? player]);
  Future<bool> pause([String? player]);
  Future<bool> stop([String? player]);
  Future<bool> playPause([String? player]);
  Future<bool> next([String? player]);
  Future<bool> previous([String? player]);
}

/// Interface for volume control operations
abstract class IVolumeController {
  Future<bool> setVolume(int volume, [String? player]);
  Future<int?> getVolume([String? player]);
}

/// Interface for executing playerctl commands
abstract class ICommandExecutor {
  Future<bool> executeCommand(String command, [String? player]);
}
