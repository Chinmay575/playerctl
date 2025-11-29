import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/exceptions.dart';
import '../interfaces/playerctl_interfaces.dart';

/// Command executor for running playerctl commands
/// Follows Single Responsibility Principle - only handles command execution
class PlayerctlCommandExecutor implements ICommandExecutor {
  @override
  Future<bool> executeCommand(String command, [String? player]) async {
    try {
      final args = player != null ? ['--player=$player', command] : [command];
      final result = await Process.run('playerctl', args, runInShell: true);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error executing command $command: $e');
      throw CommandExecutionException(command, null, e);
    }
  }

  /// Execute a command and get the output
  Future<String?> executeCommandWithOutput(
    String command, [
    String? player,
  ]) async {
    try {
      final args = player != null ? ['--player=$player', command] : [command];
      final result = await Process.run('playerctl', args, runInShell: true);

      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return null;
    } catch (e) {
      debugPrint('Error executing command $command: $e');
      return null;
    }
  }

  /// Execute a command with custom arguments
  Future<bool> executeCommandWithArgs(List<String> args) async {
    try {
      final result = await Process.run('playerctl', args, runInShell: true);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error executing command with args $args: $e');
      return false;
    }
  }
}
