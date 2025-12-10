# Version 1.2.0 - Level-Wise Logging System

## Overview

This release introduces a comprehensive level-wise logging system for the playerctl package, providing developers with fine-grained control over log output for both development and production environments.

## New Features

### PlayerctlLogger Class

A new `PlayerctlLogger` class has been added to `lib/core/logger.dart` that provides:

#### Log Levels

1. **LogLevel.none** (0) - No logging (silent mode)
2. **LogLevel.error** (1) - Only error messages
3. **LogLevel.warning** (2) - Warnings and errors
4. **LogLevel.info** (3) - Info, warnings, and errors
5. **LogLevel.debug** (4) - All logs including verbose debugging

#### Log Categories

Specialized logging methods with emoji indicators:

- `debug()` - 🔍 DEBUG: Verbose debugging information
- `info()` - ℹ️ INFO: General information  
- `warning()` - ⚠️ WARNING: Warning messages
- `error()` - ❌ ERROR: Error messages with exception support
- `success()` - ✅ SUCCESS: Success confirmations
- `metadata()` - 🎵 METADATA: Metadata updates
- `player()` - 📋 PLAYER: Player events
- `volume()` - 🔊 VOLUME: Volume changes
- `network()` - 🌐 NETWORK: HTTP server events
- `sync()` - 🔄 SYNC: Synchronization/timer events

### Configuration

#### Setting Log Level

```dart
// Set specific level
PlayerctlLogger.level = LogLevel.info;

// Convenience methods
PlayerctlLogger.enableAll();  // Set to debug
PlayerctlLogger.disableAll(); // Set to none
```

#### Default Behavior

- **Debug Mode** (`kDebugMode == true`): `LogLevel.debug` (all logs)
- **Release Mode** (`kDebugMode == false`): `LogLevel.error` (errors only)

### Usage Example

```dart
import 'package:playerctl/playerctl.dart';

void main() {
  // Production app - minimal logging
  PlayerctlLogger.level = LogLevel.error;
  
  runApp(MyApp());
}
```

## Implementation Details

### Code Changes

1. **New File**: `lib/core/logger.dart`
   - 145 lines
   - Enum `LogLevel` with comparison operators
   - Class `PlayerctlLogger` with static methods
   - Context tags support for better organization

2. **Updated Files**:
   - `lib/playerctl.dart` - Export logger
   - `lib/core/media_player_manager.dart` - Use new logger
   - `lib/services/metadata_provider.dart` - Use new logger
   - All service files updated to use structured logging

3. **New Documentation**:
   - `LOGGING.md` - Comprehensive logging guide (123 lines)
   - `example/lib/logging_example.dart` - Interactive logging demo (193 lines)

4. **Updated Documentation**:
   - `README.md` - Added logging section with examples
   - `CHANGELOG.md` - Documented all logging features

### Before vs After

**Before (1.1.1):**
```dart
debugPrint('📋 Auto-selecting first player: $selected');
debugPrint('Error fetching metadata: $e');
```

**After (1.2.0):**
```dart
PlayerctlLogger.player('Auto-selecting first player: $selected');
PlayerctlLogger.error('Error fetching metadata', 'Player', e);
```

### Benefits

1. **Production Ready**: Easy to silence logs in production
2. **Better Organization**: Categorized logs with emoji indicators
3. **Runtime Configurable**: Change log level without restarting
4. **Context Tags**: Optional tags for better filtering
5. **Exception Support**: Proper error logging with exception objects
6. **No Breaking Changes**: Fully backwards compatible

## Output Examples

### Debug Level (Verbose)
```
ℹ️ INFO: [Init] Playerctl version: v2.4.1
📋 PLAYER: Auto-selecting first player: spotify
🔄 SYNC: [Volume] Starting volume sync timer
🔄 SYNC: [Metadata] Starting metadata refresh timer
🎵 METADATA: Received - Player: spotify, Title: Song Name
✅ SUCCESS: [Metadata] Updating media info: Song Name by Artist
```

### Info Level (Balanced)
```
ℹ️ INFO: [Init] Playerctl version: v2.4.1
📋 PLAYER: Auto-selecting first player: spotify
✅ SUCCESS: [Metadata] Updating media info: Song Name by Artist
```

### Error Level (Production)
```
❌ ERROR: [Player] Error fetching metadata
  Error: NoPlayerException: Player not found
```

## Testing

- ✅ All 20 existing tests pass
- ✅ No breaking changes to existing functionality
- ✅ Logger integrated throughout codebase
- ✅ Example app demonstrates logging configuration

## Files Modified

### Core
- `lib/core/logger.dart` (NEW - 145 lines)
- `lib/core/media_player_manager.dart` (updated logging calls)
- `lib/playerctl.dart` (export logger)

### Services
- `lib/services/metadata_provider.dart` (updated logging calls)

### Documentation
- `LOGGING.md` (NEW - 123 lines)
- `README.md` (added logging section)
- `CHANGELOG.md` (version 1.2.0 entry)

### Examples
- `example/lib/logging_example.dart` (NEW - 193 lines)

### Configuration
- `pubspec.yaml` (version 1.1.1 → 1.2.0)

## Migration Guide

### For Existing Users

No changes required! The logger uses sensible defaults:
- Debug builds: verbose logging
- Release builds: errors only

### To Customize Logging

Add this to your `main()` function:

```dart
void main() {
  PlayerctlLogger.level = LogLevel.info; // or your preferred level
  runApp(MyApp());
}
```

## Future Enhancements

Potential improvements for future versions:

- Log output to file
- Custom log handlers
- Log filtering by category
- Log level per category
- Structured logging with JSON output
- Integration with logging packages (logger, logging, etc.)

## Version Information

- **Version**: 1.2.0
- **Type**: Minor release (new features, no breaking changes)
- **Previous Version**: 1.1.1
- **Release Date**: December 10, 2025
