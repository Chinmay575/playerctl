# Playerctl Example App

A Flutter Linux example app demonstrating the playerctl plugin features **without** any state management framework. Uses vanilla Flutter with `StatefulWidget` and `StreamBuilder`.

## Features Demonstrated

### 🎵 Real-time Media Control

- Play, pause, stop, next, previous controls
- Volume slider with real-time sync
- Player selection (when multiple players are active)
- Playback status indicator

### 🖼️ Album Art Server

- Displays album artwork from both online and local sources
- **Local HTTP Server**: Serves local album art files on `http://0.0.0.0:8765`
- **Cross-Device Access**: Replace `0.0.0.0` with your machine's IP to access from other devices
- Visual indicator showing whether art is from local server or online URL
- Shows the full album art URL for debugging

### ⏩ Seek Controls

- Skip forward/backward by 10 seconds
- Real-time position indicator with progress bar
- Duration display in MM:SS format

## How to Run

```bash
# Navigate to example directory
cd example

# Get dependencies
flutter pub get

# Run on Linux
flutter run -d linux
```

## Album Art Cross-Device Access

The example displays album art URLs in the format `http://0.0.0.0:8765/art/[hash].[ext]` for local files. To access this from another device:

1. Find your machine's IP address:

   ```bash
   ip addr show | grep "inet " | grep -v 127.0.0.1
   ```

2. Replace `0.0.0.0` in the code:

   ```dart
   // In main.dart, update the Image.network URL:
   state.currentMedia.artUrl!.replaceAll('0.0.0.0', '192.168.1.100')
   ```

3. Album art will now be accessible from any device on your network!

## Requirements

- Linux operating system
- `playerctl` installed (see main README)
- At least one active MPRIS-compatible media player (Spotify, VLC, browsers, etc.)

## Code Structure

- **No State Management**: Pure Flutter with `StatefulWidget`
- **StreamBuilder**: Listens to `manager.stateStream` for real-time updates
- **MediaPlayerManager**: Direct usage without any wrapper
- **Null-safe**: Proper handling of nullable fields
