# Playerctl for Flutter (Linux)

A Flutter plugin for Linux that provides media playback control using the `playerctl` command-line tool. Built with Pure Dart (no FFI) and GetX for state management.

## Features

✅ **Real-time Media Information**

- Song title, artist, album
- Playback status (Playing, Paused, Stopped)
- Player name detection (Spotify, VLC, etc.)
- Track position and length

✅ **Playback Controls**

- Play/Pause/Stop
- Next/Previous track
- Volume control (0-100)

✅ **Multi-Player Support**

- Detect all active MPRIS-compatible players
- Switch between different media players
- Target specific players for commands

✅ **Robust Edge Case Handling**

- Checks if playerctl is installed
- Handles no active players gracefully
- Automatic player detection
- Error messaging and recovery

✅ **GetX State Management**

- Reactive state updates
- Stream-based metadata listening
- Clean architecture separation

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

### Basic Setup

1. Import the package and GetX:

```dart
import 'package:playerctl/playerctl.dart';
import 'package:get/get.dart';
```

2. Initialize the controller:

```dart
final MediaController controller = Get.put(MediaController());
```

3. The controller automatically:
   - Checks if playerctl is installed
   - Detects active media players
   - Starts listening to metadata changes
   - Handles player disconnections/reconnections

### Accessing Media Information

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
    ],
  );
});
```

### Playback Controls

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
```

### Volume Control

```dart
Obx(() => Slider(
  value: controller.volume.value.toDouble(),
  min: 0,
  max: 100,
  onChanged: (value) => controller.setVolume(value.toInt()),
));
```

### Player Selection

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

### Models

- **MediaInfo**: Data class for media metadata

### Services

- **PlayerctlService**: Handles all subprocess interactions with playerctl
  - Command execution
  - Metadata streaming
  - Player detection
  - Error handling

### Controllers

- **MediaController**: GetX controller for state management
  - Observable state
  - User actions
  - Automatic updates
  - Lifecycle management

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
- All playback controls
- Volume control
- Error handling
- Real-time metadata updates

## Troubleshooting

### "playerctl is not installed"
Install playerctl using your distribution's package manager (see Requirements section).

### "No active media players found"
Start a media player that supports MPRIS (like Spotify, VLC, Firefox, Chromium, etc.) and play some media.

### Commands not working
Some players may not support all MPRIS commands. Check the player's MPRIS implementation.

### Stream not updating
Ensure the player is actively playing and supports metadata broadcasting.

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
