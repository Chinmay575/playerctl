import 'dart:io';
import 'package:flutter/foundation.dart';
import '../interfaces/playerctl_interfaces.dart';
import '../core/exceptions.dart';

/// System checker for playerctl installation and version
/// Follows Single Responsibility Principle
class PlayerctlSystemChecker implements IPlayerctlService {
  @override
  Future<bool> isPlayerctlInstalled() async {
    try {
      final result = await Process.run('which', ['playerctl']);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error checking playerctl installation: $e');
      return false;
    }
  }

  @override
  Future<String?> getPlayerctlVersion() async {
    try {
      final result = await Process.run('playerctl', ['--version']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting playerctl version: $e');
      return null;
    }
  }

  /// Validates that playerctl is installed, throws exception if not
  Future<void> ensurePlayerctlInstalled() async {
    final isInstalled = await isPlayerctlInstalled();
    if (!isInstalled) {
      throw PlayerctlNotInstalledException(
        'playerctl is not installed. Please install it using your package manager.'
      );
    }
  }
}
