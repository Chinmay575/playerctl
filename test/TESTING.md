# Integration Test Guide

To properly test the playerctl package, you'll need:

## Prerequisites

1. Install playerctl: `sudo apt install playerctl` (or equivalent for your distro)
2. Have a media player running (Spotify, VLC, Firefox with media, etc.)

### Running Tests

```bash
# Run unit tests
flutter test

# Run the example app
cd example
flutter run -d linux
```

### Manual Testing Checklist

#### Installation Check

- [ ] App detects when playerctl is NOT installed
- [ ] App shows helpful installation instructions
- [ ] App detects when playerctl IS installed

#### Player Detection

- [ ] App detects when no players are active
- [ ] App detects when a player starts
- [ ] App detects when a player stops
- [ ] App lists all active players correctly

#### Metadata Display

- [ ] Song title updates in real-time
- [ ] Artist name updates in real-time
- [ ] Album name updates in real-time
- [ ] Player status (Playing/Paused/Stopped) updates correctly
- [ ] Player name displays correctly

#### Playback Controls

- [ ] Play button works
- [ ] Pause button works
- [ ] Play/Pause toggle works
- [ ] Stop button works
- [ ] Next track button works
- [ ] Previous track button works

#### Volume Control

- [ ] Volume slider displays current volume
- [ ] Volume slider changes player volume
- [ ] Volume percentage displays correctly

#### Multi-Player Support

- [ ] Can switch between different players
- [ ] Commands target the correct player
- [ ] Metadata updates for the selected player

#### Edge Cases

- [ ] App handles player crashes gracefully
- [ ] App recovers when player restarts
- [ ] App handles rapid player switching
- [ ] App handles commands when no player is active
- [ ] Stream continues working after player pause/unpause

### Testing Different Players

Test with multiple media players to ensure compatibility:

1. **Spotify**
   - Open Spotify desktop app
   - Play a song
   - Test all controls

2. **VLC**
   - Open VLC and play a media file
   - Test all controls

3. **Firefox/Chrome**
   - Open YouTube or other media site
   - Play a video
   - Test all controls

4. **Multiple Players**
   - Run 2+ players simultaneously
   - Verify player switching works
   - Verify commands target correct player

### Expected Behaviors

#### When playerctl is not installed

```bash
Error message: "playerctl is not installed on this system..."
Install instructions displayed
Retry button available
```

#### When no players are active

```bash
Message: "No active media players found"
Hint: "Start playing media in Spotify, VLC, or any MPRIS-compatible player"
App periodically checks for new players
```

#### When player becomes active

```bash
Metadata automatically appears
Status updates to "Playing"
All controls become functional
Volume slider shows current volume
```

#### When switching players

```bash
Metadata updates to new player
Controls affect new player
Volume updates to new player's volume
```

### Performance Testing

- [ ] Stream doesn't cause memory leaks
- [ ] App remains responsive with long-running streams
- [ ] Multiple player switches don't cause issues
- [ ] App handles rapid metadata changes

### Error Recovery Testing

1. Start the app with a player running
2. Kill the player process
3. Verify app shows "No active players"
4. Restart the player
5. Verify app automatically detects and reconnects

### Debugging

Enable verbose logging in the service:

```dart
// In PlayerctlService, all debugPrint statements show:
// - Process outputs
// - Error messages
// - Metadata parsing issues
```

Check terminal output when running the example app for detailed logs.
