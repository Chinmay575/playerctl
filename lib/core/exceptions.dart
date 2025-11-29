/// Custom exceptions for playerctl operations
library;

/// Base exception for all playerctl-related errors
abstract class PlayerctlException implements Exception {
  final String message;
  final dynamic originalError;

  PlayerctlException(this.message, [this.originalError]);

  @override
  String toString() => '$runtimeType: $message${originalError != null ? ' (caused by: $originalError)' : ''}';
}

/// Exception thrown when playerctl is not installed on the system
class PlayerctlNotInstalledException extends PlayerctlException {
  PlayerctlNotInstalledException([String? message])
      : super(message ?? 'playerctl is not installed on this system');
}

/// Exception thrown when no media player is currently running
class NoPlayerException extends PlayerctlException {
  NoPlayerException([String? message])
      : super(message ?? 'No active media players found');
}

/// Exception thrown when a command execution fails
class CommandExecutionException extends PlayerctlException {
  final String command;
  
  CommandExecutionException(this.command, [String? message, dynamic error])
      : super(message ?? 'Failed to execute command: $command', error);
}

/// Exception thrown when metadata parsing fails
class MetadataParsingException extends PlayerctlException {
  MetadataParsingException([String? message, dynamic error])
      : super(message ?? 'Failed to parse metadata', error);
}

/// Exception thrown when volume value is invalid
class InvalidVolumeException extends PlayerctlException {
  final int volume;
  
  InvalidVolumeException(this.volume)
      : super('Invalid volume value: $volume. Must be between 0 and 100');
}
