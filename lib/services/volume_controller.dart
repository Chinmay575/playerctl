import 'package:flutter/foundation.dart';
import '../interfaces/playerctl_interfaces.dart';
import '../core/exceptions.dart';
import 'command_executor.dart';

/// Volume controller for managing player volume
/// Follows Single Responsibility Principle
class VolumeController implements IVolumeController {
  final PlayerctlCommandExecutor _executor;

  VolumeController(this._executor);

  @override
  Future<bool> setVolume(int volume, [String? player]) async {
    // Validate volume range
    if (volume < 0 || volume > 100) {
      debugPrint('Volume must be between 0 and 100');
      throw InvalidVolumeException(volume);
    }

    final volumeDecimal = volume / 100;

    final args = player != null
        ? ['--player=$player', 'volume', volumeDecimal.toString()]
        : ['volume', volumeDecimal.toString()];

    return _executor.executeCommandWithArgs(args);
  }

  @override
  Future<int?> getVolume([String? player]) async {
    try {
      final output = await _executor.executeCommandWithOutput('volume', player);
      debugPrint(
        'Raw volume output from playerctl: "$output" for player: $player',
      );

      if (output != null) {
        final volumeDecimal = double.tryParse(output);
        final volumePercent = volumeDecimal != null
            ? (volumeDecimal * 100).round()
            : null;
        debugPrint(
          'Parsed volume: $volumePercent (from decimal: $volumeDecimal)',
        );
        return volumePercent;
      }
      debugPrint('Volume output was null');
      return null;
    } catch (e) {
      debugPrint('Error getting volume: $e');
      return null;
    }
  }

  /// Increase volume by percentage
  Future<bool> increaseVolume(int percentage, [String? player]) async {
    try {
      final currentVolume = await getVolume(player);
      if (currentVolume == null) return false;

      final newVolume = (currentVolume + percentage).clamp(0, 100);
      return setVolume(newVolume, player);
    } catch (e) {
      debugPrint('Error increasing volume: $e');
      return false;
    }
  }

  /// Decrease volume by percentage
  Future<bool> decreaseVolume(int percentage, [String? player]) async {
    try {
      final currentVolume = await getVolume(player);
      if (currentVolume == null) return false;

      final newVolume = (currentVolume - percentage).clamp(0, 100);
      return setVolume(newVolume, player);
    } catch (e) {
      debugPrint('Error decreasing volume: $e');
      return false;
    }
  }

  /// Mute the player (set volume to 0)
  Future<bool> mute([String? player]) async {
    return setVolume(0, player);
  }
}
