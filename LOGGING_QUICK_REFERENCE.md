# Quick Reference: Logging Configuration

## TL;DR

```dart
// Most common: Set globally before anything else
PlayerctlLogger.level = LogLevel.info;

// Or pass to constructor
final manager = MediaPlayerManager(logLevel: LogLevel.info);

// Or change at runtime
manager.setLogLevel(LogLevel.error);
```

## Log Levels (from least to most verbose)

| Level | Value | Shows | Use Case |
|-------|-------|-------|----------|
| `none` | 0 | Nothing | Production (silent) |
| `error` | 1 | ❌ Errors only | Production (minimal) |
| `warning` | 2 | ⚠️ Warnings + Errors | Production (cautious) |
| `info` | 3 | ℹ️ Info + Warnings + Errors | **Recommended** |
| `debug` | 4 | 🔍 Everything | Development |

## 4 Configuration Methods

### 1. Global (Before creating manager) ⭐ Recommended

```dart
void main() {
  PlayerctlLogger.level = LogLevel.info;
  runApp(MyApp());
}
```

### 2. Constructor (When creating manager)

```dart
final manager = MediaPlayerManager(
  logLevel: LogLevel.info,
);
```

### 3. Runtime via Manager (User settings)

```dart
// In a settings page
manager.setLogLevel(selectedLevel);

// Check current level
print(manager.logLevel.name); // 'info'
```

### 4. Runtime via Logger (Direct access)

```dart
PlayerctlLogger.level = LogLevel.warning;
```

## Common Scenarios

### Production App
```dart
// Silent mode
PlayerctlLogger.disableAll();

// Or errors only
PlayerctlLogger.level = LogLevel.error;
```

### Development
```dart
// All logs
PlayerctlLogger.enableAll();

// Or specifically
PlayerctlLogger.level = LogLevel.debug;
```

### User Configurable
```dart
class SettingsScreen extends StatefulWidget {
  final MediaPlayerManager manager;
  
  @override
  Widget build(BuildContext context) {
    return DropdownButton<LogLevel>(
      value: manager.logLevel,
      items: LogLevel.values.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(level.name.toUpperCase()),
        );
      }).toList(),
      onChanged: (level) {
        if (level != null) {
          setState(() => manager.setLogLevel(level));
        }
      },
    );
  }
}
```

## Log Categories

| Emoji | Category | Level | Description |
|-------|----------|-------|-------------|
| 🔍 | DEBUG | debug | Verbose debugging info |
| ℹ️ | INFO | info | General information |
| ⚠️ | WARNING | warning | Warning messages |
| ❌ | ERROR | error | Error messages |
| ✅ | SUCCESS | info | Success confirmations |
| 🎵 | METADATA | debug | Metadata updates |
| 📋 | PLAYER | info | Player events |
| 🔊 | VOLUME | debug | Volume changes |
| 🔄 | SYNC | debug | Sync/timer events |
| 🌐 | NETWORK | debug | Network/server events |

## Default Behavior

- **Debug mode** (`kDebugMode = true`): `LogLevel.debug`
- **Release mode** (`kDebugMode = false`): `LogLevel.error`

## Testing Different Levels

```dart
// Generate test logs
PlayerctlLogger.debug('Debug message');
PlayerctlLogger.info('Info message');
PlayerctlLogger.warning('Warning message');
PlayerctlLogger.error('Error message');

// With context tags
PlayerctlLogger.info('Player connected', 'Connection');
PlayerctlLogger.error('Failed to connect', 'Connection', exception);
```

## Tips

1. **Production**: Use `LogLevel.error` or `LogLevel.none`
2. **Development**: Use `LogLevel.debug` or `LogLevel.info`
3. **User Settings**: Let users choose their preferred level
4. **Performance**: Lower log levels = better performance
5. **Debugging**: Start with `debug`, then reduce to `info` when stable

## Examples

See complete examples in:
- `example/lib/logging_config_example.dart` - Full interactive demo
- `example/lib/logging_example.dart` - Simple example
- `LOGGING.md` - Detailed documentation
