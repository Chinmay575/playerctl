import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// HTTP server for serving album art files locally
/// This allows album art to be accessed from other devices on the network
class AlbumArtServer {
  HttpServer? _server;
  static const int defaultPort = 8765;
  final Map<String, String> _fileCache = {}; // Maps URL paths to file paths

  /// Start the HTTP server on 0.0.0.0
  Future<String?> start({int port = defaultPort}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      debugPrint('🌐 Album art server started on http://0.0.0.0:$port');

      _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });

      return 'http://0.0.0.0:$port';
    } catch (e) {
      debugPrint('❌ Failed to start album art server: $e');
      return null;
    }
  }

  /// Handle incoming HTTP requests
  void _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;

      if (path == '/') {
        // Health check endpoint
        request.response
          ..statusCode = HttpStatus.ok
          ..write('Album Art Server is running')
          ..close();
        return;
      }

      // Check if we have this file in cache
      if (_fileCache.containsKey(path)) {
        final filePath = _fileCache[path]!;
        final file = File(filePath);

        if (await file.exists()) {
          // Determine content type from file extension
          final contentType = _getContentType(filePath);

          final bytes = await file.readAsBytes();
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.parse(contentType)
            ..headers.add('Access-Control-Allow-Origin', '*') // Enable CORS
            ..headers.add(
              'Content-Disposition',
              'inline',
            ) // Display inline, not download
            ..headers.add(
              'Cache-Control',
              'public, max-age=3600',
            ) // Cache for 1 hour
            ..add(bytes)
            ..close();

          debugPrint('📤 Served: $path (${bytes.length} bytes)');
          return;
        } else {
          debugPrint('⚠️ File not found: $filePath');
        }
      }

      // File not found
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('File not found')
        ..close();
    } catch (e) {
      debugPrint('❌ Error handling request: $e');
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Internal server error')
          ..close();
      } catch (_) {
        // Ignore if response already closed
      }
    }
  }

  /// Register a file to be served and get the URL
  String? registerFile(String filePath) {
    try {
      if (_server == null) {
        debugPrint('⚠️ Server not started, cannot register file');
        return null;
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('⚠️ File does not exist: $filePath');
        return null;
      }

      // Create a unique path based on file path hash
      final hash = filePath.hashCode.abs().toRadixString(36);
      final extension = filePath.split('.').last;
      final urlPath = '/art/$hash.$extension';

      // Cache the mapping
      _fileCache[urlPath] = filePath;

      final port = _server!.port;
      final url = 'http://0.0.0.0:$port$urlPath';

      debugPrint('📝 Registered: $filePath -> $url');
      return url;
    } catch (e) {
      debugPrint('❌ Error registering file: $e');
      return null;
    }
  }

  /// Get content type from file extension
  String _getContentType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }

  /// Stop the server
  Future<void> stop() async {
    try {
      await _server?.close(force: true);
      _server = null;
      _fileCache.clear();
      debugPrint('🛑 Album art server stopped');
    } catch (e) {
      debugPrint('❌ Error stopping server: $e');
    }
  }

  /// Check if server is running
  bool get isRunning => _server != null;

  /// Get the server port
  int? get port => _server?.port;
}
