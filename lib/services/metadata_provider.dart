import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../interfaces/playerctl_interfaces.dart';
import '../core/exceptions.dart';

/// Metadata provider for fetching and streaming media metadata
/// Follows Single Responsibility Principle
class MetadataProvider implements IMetadataProvider {
  Process? _metadataProcess;
  StreamController<Map<String, String>>? _metadataController;
  bool _isListening = false;
  String? _currentPlayer;
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 5;
  static const Duration _restartDelay = Duration(seconds: 2);
  Timer? _restartTimer;

  // Use a delimiter unlikely to appear in song titles/metadata
  static const String _delimiter = '|||';

  @override
  Future<Map<String, String>> getCurrentMetadata([String? player]) async {
    try {
      final args = player != null
          ? ['--player=$player', 'metadata', '--format', '{{title}}$_delimiter{{artist}}$_delimiter{{album}}$_delimiter{{status}}$_delimiter{{playerName}}$_delimiter{{position}}$_delimiter{{mpris:length}}']
          : ['metadata', '--format', '{{title}}$_delimiter{{artist}}$_delimiter{{album}}$_delimiter{{status}}$_delimiter{{playerName}}$_delimiter{{position}}$_delimiter{{mpris:length}}'];

      final result = await Process.run('playerctl', args, runInShell: true);

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        return _parseMetadata(output);
      }
      return {};
    } catch (e) {
      debugPrint('Error getting current metadata: $e');
      throw MetadataParsingException('Failed to get current metadata', e);
    }
  }

  @override
  Stream<Map<String, String>> listenToMetadata([String? player]) {
    if (_isListening && _metadataController != null) {
      return _metadataController!.stream;
    }

    _metadataController = StreamController<Map<String, String>>.broadcast(
      onCancel: () => stopListening(),
    );

    _startMetadataProcess(player);
    return _metadataController!.stream;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _restartTimer?.cancel();
    _restartTimer = null;
    _metadataProcess?.kill();
    _metadataProcess = null;
    await _metadataController?.close();
    _metadataController = null;
    _currentPlayer = null;
    _restartAttempts = 0;
  }

  /// Start the metadata streaming process
  Future<void> _startMetadataProcess([String? player]) async {
    try {
      _isListening = true;
      _currentPlayer = player;

      final args = player != null
          ? ['--player=$player', 'metadata', '--follow', '--format', '{{title}}$_delimiter{{artist}}$_delimiter{{album}}$_delimiter{{status}}$_delimiter{{playerName}}$_delimiter{{position}}$_delimiter{{mpris:length}}']
          : ['metadata', '--follow', '--format', '{{title}}$_delimiter{{artist}}$_delimiter{{album}}$_delimiter{{status}}$_delimiter{{playerName}}$_delimiter{{position}}$_delimiter{{mpris:length}}'];

      _metadataProcess = await Process.start('playerctl', args, runInShell: true);

      // Listen to stdout
      _metadataProcess!.stdout
          .transform(const SystemEncoding().decoder)
          .listen(
            (data) {
              final lines = data.trim().split('\n');
              for (var line in lines) {
                if (line.isNotEmpty) {
                  try {
                    final metadata = _parseMetadata(line);
                    if (metadata.isNotEmpty) {
                      // Reset restart attempts on successful data reception
                      if (_restartAttempts > 0) {
                        debugPrint('Process recovered, resetting restart attempts');
                        _restartAttempts = 0;
                      }
                      _metadataController?.add(metadata);
                    }
                  } catch (e) {
                    debugPrint('Error parsing metadata line: $e');
                  }
                }
              }
            },
            onError: (error) {
              debugPrint('Error in metadata stream: $error');
              _metadataController?.addError(
                MetadataParsingException('Stream error', error)
              );
            },
          );

      // Listen to stderr for errors
      _metadataProcess!.stderr
          .transform(const SystemEncoding().decoder)
          .listen(
            (data) {
              if (data.contains('No players found')) {
                _metadataController?.addError(
                    NoPlayerException('No active media players found'));
              } else {
                debugPrint('Playerctl stderr: $data');
              }
            },
          );

      // Listen to process exit and handle automatic restart
      _metadataProcess!.exitCode.then((exitCode) {
        debugPrint('Playerctl process exited with code: $exitCode');
        
        // If we're still listening and haven't exceeded max restart attempts, restart the process
        if (_isListening && _restartAttempts < _maxRestartAttempts) {
          _restartAttempts++;
          debugPrint('Attempting to restart playerctl process (attempt $_restartAttempts/$_maxRestartAttempts)');
          
          // Add a delay before restarting to prevent rapid restarts
          _restartTimer = Timer(_restartDelay, () {
            if (_isListening) {
              _startMetadataProcess(_currentPlayer);
            }
          });
        } else if (_restartAttempts >= _maxRestartAttempts) {
          // Max restart attempts reached
          debugPrint('Max restart attempts reached. Stopping metadata listener.');
          if (_metadataController != null && !_metadataController!.isClosed) {
            _metadataController!.addError(
              Exception('Playerctl process failed after $_maxRestartAttempts restart attempts')
            );
          }
          _isListening = false;
        } else if (exitCode != 0 && _metadataController != null && !_metadataController!.isClosed) {
          // Process exited with error and we're not listening anymore
          _metadataController!.addError(
            Exception('Playerctl process exited with code $exitCode')
          );
        }
      });
    } catch (e) {
      debugPrint('Error starting metadata process: $e');
      _metadataController?.addError(
        MetadataParsingException('Failed to start metadata process', e)
      );
      _isListening = false;
    }
  }

  /// Parse metadata output from playerctl
  Map<String, String> _parseMetadata(String output) {
    try {
      final parts = output.split(_delimiter);
      if (parts.length >= 5) {
        final metadata = {
          'title': parts[0].trim(),
          'artist': parts[1].trim(),
          'album': parts[2].trim(),
          'status': parts[3].trim(),
          'playerName': parts[4].trim(),
          'position': parts.length > 5 ? parts[5].trim() : '0',
          'length': parts.length > 6 ? parts[6].trim() : '0',
        };
        
        debugPrint('📝 Parsed metadata: title="${metadata['title']}", '
            'artist="${metadata['artist']}", status="${metadata['status']}", '
            'player="${metadata['playerName']}"');
        
        return metadata;
      }
      debugPrint('⚠️ Insufficient metadata parts: ${parts.length} (expected >= 5)');
      return {};
    } catch (e) {
      debugPrint('Error parsing metadata: $e');
      throw MetadataParsingException('Failed to parse metadata format', e);
    }
  }

  /// Cleanup resources
  void dispose() {
    _restartTimer?.cancel();
    _restartTimer = null;
    stopListening();
  }
}
