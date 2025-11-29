import 'dart:io';
import 'package:flutter/foundation.dart';
import '../interfaces/playerctl_interfaces.dart';

/// Player detector for finding and listing media players
/// Follows Single Responsibility Principle
class PlayerDetector implements IPlayerDetector {

  PlayerDetector();

  @override
  Future<bool> hasActivePlayer() async {
    try {
      final result = await Process.run('playerctl', ['status'], runInShell: true);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error checking active player: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getAvailablePlayers() async {
    try {
      final result = await Process.run('playerctl', ['--list-all'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isEmpty) return [];
        return output.split('\n').where((p) => p.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting available players: $e');
      return [];
    }
  }

  /// Get the currently active player name
  Future<String?> getActivePlayerName() async {
    final players = await getAvailablePlayers();
    return players.isNotEmpty ? players.first : null;
  }

  /// Check if a specific player is available
  Future<bool> isPlayerAvailable(String playerName) async {
    final players = await getAvailablePlayers();
    return players.contains(playerName);
  }
}
