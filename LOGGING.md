# Logging Configuration

The playerctl package includes a comprehensive logging system with different log levels.

## Log Levels

- **LogLevel.none** - No logging (silent)
- **LogLevel.error** - Only errors
- **LogLevel.warning** - Warnings and errors  
- **LogLevel.info** - Info messages, warnings, and errors
- **LogLevel.debug** - All logs including debug/verbose output (default in debug mode)

## Usage

### Setting Log Level

There are **4 ways** to configure logging in playerctl:

#### Method 1: Global Configuration (Recommended)

```dart
import 'package:playerctl/playerctl.dart';

void main() {
  // Set log level globally before creating managers
  PlayerctlLogger.level = LogLevel.info;
  
  // Or use convenience methods
  PlayerctlLogger.disableAll();  // LogLevel.none - silent
  PlayerctlLogger.enableAll();   // LogLevel.debug - verbose
  
  runApp(MyApp());
}
```

#### Method 2: Constructor Configuration

```dart
// Pass log level when creating the manager
final manager = MediaPlayerManager(
  logLevel: LogLevel.info, // Set initial log level
);
```

#### Method 3: Runtime Configuration via Manager

```dart
// Change log level at runtime using the manager
manager.setLogLevel(LogLevel.error);

// Get current log level
LogLevel current = manager.logLevel;
```

#### Method 4: Runtime Configuration via Logger

```dart
// Change log level directly via the logger
PlayerctlLogger.level = LogLevel.warning;

// Get current log level
LogLevel current = PlayerctlLogger.level;
```

### Default Behavior

- **Debug mode** (kDebugMode = true): LogLevel.debug (all logs shown)
- **Release mode** (kDebugMode = false): LogLevel.error (only errors shown)

## Log Categories

The logger includes emoji indicators for easy identification:

- 🔍 **DEBUG** - Verbose debugging information
- ℹ️ **INFO** - General information  
- ⚠️ **WARNING** - Warning messages
- ❌ **ERROR** - Error messages
- ✅ **SUCCESS** - Success confirmations
- 🎵 **METADATA** - Metadata updates
- 📋 **PLAYER** - Player events (switching, connecting)
- 🔊 **VOLUME** - Volume changes
- 🌐 **NETWORK** - Network/HTTP server events
- 🔄 **SYNC** - Synchronization/timer events

## Examples

### Production App (Minimal Logging)
```dart
void main() {
  // Only show errors in production
  PlayerctlLogger.level = LogLevel.error;
  runApp(MyApp());
}
```

### Development (Verbose Logging)
```dart
void main() {
  // Show all logs during development
  PlayerctlLogger.level = LogLevel.debug;
  runApp(MyApp());
}
```

### User-Configurable Logging (Settings Page)
```dart
class SettingsPage extends StatefulWidget {
  final MediaPlayerManager manager;
  
  const SettingsPage({required this.manager});
  
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Current: ${widget.manager.logLevel.name}'),
        DropdownButton<LogLevel>(
          value: widget.manager.logLevel,
          items: const [
            DropdownMenuItem(value: LogLevel.none, child: Text('Silent')),
            DropdownMenuItem(value: LogLevel.error, child: Text('Errors Only')),
            DropdownMenuItem(value: LogLevel.warning, child: Text('Warnings')),
            DropdownMenuItem(value: LogLevel.info, child: Text('Info')),
            DropdownMenuItem(value: LogLevel.debug, child: Text('Debug')),
          ],
          onChanged: (level) {
            if (level != null) {
              setState(() {
                widget.manager.setLogLevel(level); // Updates and logs change
              });
            }
          },
        ),
      ],
    );
  }
}
```

## Sample Output

### Debug Level
```
ℹ️ INFO: [Init] Playerctl version: v2.4.1
📋 PLAYER: Auto-selecting first player: spotify
🔊 VOLUME: Starting volume sync timer
🔄 SYNC: Starting metadata refresh timer
🎵 METADATA: Received - Player: spotify, Title: Song Name, Selected: spotify
✅ SUCCESS: [Metadata] Updating media info: Song Name by Artist Name
```

### Info Level (Less Verbose)
```
ℹ️ INFO: [Init] Playerctl version: v2.4.1
📋 PLAYER: Auto-selecting first player: spotify
✅ SUCCESS: [Metadata] Updating media info: Song Name by Artist Name
```

### Error Level (Minimal)
```
❌ ERROR: [Player] Error fetching metadata for player spotify
  Error: NoPlayerException: Player not found
```
