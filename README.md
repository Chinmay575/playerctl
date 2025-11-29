# Playerctl for Flutter (Linux)

A Flutter plugin for Linux that provides robust media playback control using the `playerctl` command-line tool. Built with SOLID principles, Pure Dart (no FFI), and state-management-agnostic architecture.

## Features

✅ **Real-time Media Information**

- Song title, artist, album
- Playback status (Playing, Paused, Stopped)
- Player name detection (Spotify, VLC, Brave, etc.)
- Track position and length
- Shuffle and loop status

✅ **Playback Controls**

- Play/Pause/Stop
- Next/Previous track
- Volume control (0-100)
- Shuffle toggle
- Loop cycling (None → Track → Playlist)

✅ **Multi-Player Support**

- Detect all active MPRIS-compatible players
- Switch between different media players
- Automatic player switching when current player closes
- Real-time synchronization across multiple players

✅ **Robust Error Handling**

- Automatic process restart (up to 5 attempts)
- Handles playerctl crashes gracefully
- Checks if playerctl is installed
- Handles no active players gracefully
- Special character support in metadata (pipe characters, etc.)

✅ **State-Agnostic Architecture**

- Use with any state management solution (GetX, Riverpod, Bloc, Provider, etc.)
- Clean SOLID architecture
- Service-oriented design with dependency injection
- Optional GetX wrapper included

✅ **Advanced Synchronization**

- Triple-layer sync (real-time stream + periodic metadata refresh + volume sync)
- External volume changes detected automatically
- Debounced player switching to prevent glitches

## Requirements

- **Platform**: Linux only
- **playerctl**: Must be installed on the system

### Installing playerctl

```bash
# Debian/Ubuntu
sudo apt install playerctl

# Arch Linux
sudo pacman -S playerctl

# Fedora
sudo dnf install playerctl

# openSUSE
sudo zypper install playerctl
```

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  playerctl:
    git:
      url: https://github.com/yourusername/playerctl.git
```

Or if you're developing locally:

```yaml
dependencies:
  playerctl:
    path: ../playerctl
```

## Usage

### Option 1: Using the Core Manager (State-Agnostic)

```dart
import 'package:playerctl/playerctl.dart';

// Create the manager
final manager = MediaPlayerManager();

// Listen to state changes
manager.stateStream.listen((state) {
  print('Title: ${state.currentMedia.title}');
  print('Artist: ${state.currentMedia.artist}');
  print('Status: ${state.playbackStatus}');
  print('Volume: ${state.volume}');
  print('Shuffle: ${state.shuffleStatus}');
  print('Loop: ${state.loopStatus}');
});

// Initialize
await manager.initialize();

// Control playback
await manager.play();
await manager.pause();
await manager.next();
await manager.previous();
await manager.setVolume(75);
await manager.toggleShuffle();
await manager.cycleLoop();

// Switch players
await manager.switchPlayer('spotify');

// Cleanup
manager.dispose();
```

### Option 2: Using GetX Wrapper

```dart
import 'package:playerctl/playerctl.dart';
import 'package:get/get.dart';

// Initialize the controller
final MediaController controller = Get.put(MediaController());

// The controller automatically:
// - Checks if playerctl is installed
// - Detects active media players
// - Starts listening to metadata changes
// - Handles player disconnections/reconnections
// - Syncs volume and metadata periodically

### Accessing Media Information (GetX)

```dart
Obx(() {
  final media = controller.currentMedia.value;
  return Column(
    children: [
      Text('Title: ${media.title}'),
      Text('Artist: ${media.artist}'),
      Text('Album: ${media.album}'),
      Text('Status: ${media.status}'),
      Text('Player: ${media.playerName}'),
      Text('Shuffle: ${controller.shuffleStatus.value}'),
      Text('Loop: ${controller.loopStatus.value}'),
    ],
  );
});
```

### Playback Controls (GetX)

```dart
// Play/Pause toggle
ElevatedButton(
  onPressed: () => controller.playPause(),
  child: Text('Play/Pause'),
);

// Individual controls
controller.play();
controller.pause();
controller.stop();
controller.next();
controller.previous();

// Shuffle and loop
controller.toggleShuffle();
controller.cycleLoop(); // Cycles through None → Track → Playlist → None
```

### Volume Control (GetX)

```dart
Obx(() => Slider(
  value: controller.volume.value.toDouble(),
  min: 0,
  max: 100,
  onChanged: (value) => controller.setVolume(value.toInt()),
));
```

### Player Selection (GetX)

```dart
Obx(() {
  if (controller.availablePlayers.length > 1) {
    return DropdownButton<String>(
      value: controller.selectedPlayer.value,
      items: controller.availablePlayers.map((player) {
        return DropdownMenuItem(
          value: player,
          child: Text(player),
        );
      }).toList(),
      onChanged: (player) {
        if (player != null) controller.switchPlayer(player);
      },
    );
  }
  return Container();
});
```

### Error Handling

```dart
Obx(() {
  // Check if playerctl is installed
  if (!controller.isPlayerctlInstalled.value) {
    return Text('Please install playerctl');
  }
  
  // Check for active players
  if (!controller.hasActivePlayer.value) {
    return Text('No active media players');
  }
  
  // Show any error messages
  if (controller.errorMessage.value.isNotEmpty) {
    return Text('Error: ${controller.errorMessage.value}');
  }
  
  return YourMediaWidget();
});
```

## Architecture

This plugin follows SOLID principles with a clean, layered architecture:

### Core Layer (State-Agnostic)

- **MediaPlayerManager**: Main coordinator class
  - State-management-agnostic API
  - Manages player lifecycle
  - Handles automatic reconnection
  - Triple-layer synchronization (stream + metadata refresh + volume sync)
  - Debounced player switching
  
- **PlayerState**: Immutable state container
  - All player information in one place
  - Includes shuffle/loop status
  - Easy to serialize/persist

### Service Layer

- **PlayerctlService**: Main facade service
  - Combines all specialized services
  - Provides unified API

- **MetadataProvider**: Real-time metadata streaming
  - Automatic process restart on failure
  - Special character handling (triple-pipe delimiter)
  - Up to 5 restart attempts

- **PlayerDetector**: Player discovery and management
  - Lists available MPRIS players
  - Monitors player availability

- **PlaybackController**: Playback command execution
  - Play/pause/stop/next/previous
  - Shuffle toggle and status
  - Loop cycling (None/Track/Playlist)

- **VolumeController**: Volume management
  - Get/set volume (0-100)
  - Periodic sync to detect external changes

- **CommandExecutor**: Low-level command execution
  - Process management
  - Error handling

### State Management Wrappers

- **MediaController**: Optional GetX wrapper
  - Reactive observables
  - Automatic lifecycle management
  - Easy integration with GetX apps

### Models

- **MediaInfo**: Metadata container
  - Title, artist, album, status, player name
  - Track position and length

## Advanced Usage

### Direct Service Access

If you need lower-level access without GetX:

```dart
final service = PlayerctlService();

// Check installation
bool installed = await service.isPlayerctlInstalled();

// Get players
List<String> players = await service.getAvailablePlayers();

// Listen to metadata
service.listenToMetadata().listen((metadata) {
  print('Title: ${metadata['title']}');
  print('Artist: ${metadata['artist']}');
});

// Send commands
await service.play();
await service.next();
await service.setVolume(75);

// Cleanup
service.dispose();
```

### Targeting Specific Players

```dart
// Listen to specific player
service.listenToMetadata('spotify');

// Send command to specific player
await service.play('vlc');
await service.next('spotify');
```

## Example App

A complete example app is included in the `example/` directory. To run it:

```bash
cd example
flutter run -d linux
```

The example demonstrates:

- Installation checking
- Player detection and switching
- All playback controls (play/pause/next/previous)
- Volume control with external sync
- Shuffle and loop controls
- Multi-player management
- Error handling
- Real-time metadata updates
- Automatic player switching

## Troubleshooting

### "playerctl is not installed"

Install playerctl using your distribution's package manager (see Requirements section).

### "No active media players found"

Start a media player that supports MPRIS (like Spotify, VLC, Firefox, Chromium, etc.) and play some media.

### Commands not working

Some players may not support all MPRIS commands. Check the player's MPRIS implementation.

### Stream not updating

The plugin has triple-layer synchronization. If real-time updates stop, periodic refresh (every 3 seconds) will continue to update state.

### Glitching when switching players

The plugin includes debouncing to prevent rapid consecutive switches. If issues persist, check debug output for timer lifecycle messages.

## Supported Players

Any MPRIS-compatible media player, including:

- Spotify
- VLC
- Firefox
- Chromium/Chrome
- MPV
- Audacious
- Rhythmbox
- And many more...

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

Built with:

- [playerctl](https://github.com/altdesktop/playerctl) - Command-line MPRIS client
- [GetX](https://pub.dev/packages/get) - State management
- Flutter - UI framework
