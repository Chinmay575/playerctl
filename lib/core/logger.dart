import 'package:flutter/foundation.dart';

/// Log levels for the playerctl package
enum LogLevel {
  /// No logging
  none(0),

  /// Only errors
  error(1),

  /// Warnings and errors
  warning(2),

  /// Info, warnings, and errors
  info(3),

  /// All logs including debug
  debug(4);

  const LogLevel(this.value);
  final int value;

  bool operator >=(LogLevel other) => value >= other.value;
  bool operator >(LogLevel other) => value > other.value;
  bool operator <=(LogLevel other) => value <= other.value;
  bool operator <(LogLevel other) => value < other.value;
}

/// Logger utility for playerctl package
class PlayerctlLogger {
  /// Current log level
  static LogLevel _level = kDebugMode ? LogLevel.debug : LogLevel.error;

  /// Get current log level
  static LogLevel get level => _level;

  /// Set log level
  static set level(LogLevel newLevel) {
    _level = newLevel;
  }

  /// Enable all logs (debug level)
  static void enableAll() {
    _level = LogLevel.debug;
  }

  /// Disable all logs
  static void disableAll() {
    _level = LogLevel.none;
  }

  /// Log a debug message (verbose/trace level)
  static void debug(String message, [String? tag]) {
    if (_level >= LogLevel.debug) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🔍 DEBUG: $prefix$message');
    }
  }

  /// Log an info message
  static void info(String message, [String? tag]) {
    if (_level >= LogLevel.info) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ INFO: $prefix$message');
    }
  }

  /// Log a warning message
  static void warning(String message, [String? tag]) {
    if (_level >= LogLevel.warning) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ WARNING: $prefix$message');
    }
  }

  /// Log an error message
  static void error(String message, [String? tag, Object? error]) {
    if (_level >= LogLevel.error) {
      final prefix = tag != null ? '[$tag] ' : '';
      final errorMsg = error != null ? '\n  Error: $error' : '';
      debugPrint('❌ ERROR: $prefix$message$errorMsg');
    }
  }

  /// Log a success message (info level)
  static void success(String message, [String? tag]) {
    if (_level >= LogLevel.info) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('✅ SUCCESS: $prefix$message');
    }
  }

  /// Log metadata updates (debug level)
  static void metadata(String message, [String? tag]) {
    if (_level >= LogLevel.debug) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🎵 METADATA: $prefix$message');
    }
  }

  /// Log player events (info level)
  static void player(String message, [String? tag]) {
    if (_level >= LogLevel.info) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('📋 PLAYER: $prefix$message');
    }
  }

  /// Log volume events (debug level)
  static void volume(String message, [String? tag]) {
    if (_level >= LogLevel.debug) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🔊 VOLUME: $prefix$message');
    }
  }

  /// Log network/server events (debug level)
  static void network(String message, [String? tag]) {
    if (_level >= LogLevel.debug) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🌐 NETWORK: $prefix$message');
    }
  }

  /// Log sync/timer events (debug level)
  static void sync(String message, [String? tag]) {
    if (_level >= LogLevel.debug) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🔄 SYNC: $prefix$message');
    }
  }
}
