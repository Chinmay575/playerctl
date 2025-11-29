# Volume Sync Debugging Guide

## Current Implementation

Volume synchronization has been implemented with:
- **Sync Interval:** Every 2 seconds
- **Automatic Start:** When players are detected during initialization
- **Automatic Restart:** When switching players
- **Debug Logging:** Extensive logging with 🔊 emoji for easy identification

## How to Debug Volume Sync

### Step 1: Run the Example App in Debug Mode

```bash
cd example
flutter run -d linux --verbose
```

### Step 2: Watch for Debug Output

Look for these debug messages in the console:

```
🔊 Starting volume sync timer
🔊 Volume sync timer tick - hasActivePlayer: true, selectedPlayer: spotify
🔊 Calling updateCurrentVolume...
Fetching volume for player: spotify
Raw volume output from playerctl: "0.75" for player: spotify
Parsed volume: 75 (from decimal: 0.75)
Volume fetched: 75 (previous: 50)
🔊 updateCurrentVolume completed
```

### Step 3: Test Volume Sync

#### Method 1: Using System Volume Controls
1. Run the example app
2. Open a media player (Spotify, VLC, etc.)
3. Change volume using system volume controls (not the app slider)
4. **Expected:** Within 2 seconds, the app's slider should update to match

#### Method 2: Using playerctl Command
1. Run the example app
2. In a terminal, run:
   ```bash
   # Set volume to 80%
   playerctl volume 0.8
   
   # Check if app updates within 2 seconds
   ```
3. You can use the provided test script:
   ```bash
   ./test_volume.sh
   ```

#### Method 3: Using Other Apps
1. Run the example app
2. Open your media player's built-in volume control
3. Change volume there
4. **Expected:** App updates within 2 seconds

## Common Issues and Solutions

### Issue 1: Volume Sync Not Starting

**Symptoms:**
- No `🔊 Starting volume sync timer` message in logs
- No periodic `🔊 Volume sync timer tick` messages

**Possible Causes:**
1. No active player detected during initialization
2. `hasActivePlayer` is false

**Solution:**
```bash
# Check if player is detected
playerctl status

# If no output, start a media player and play something
```

**Debug Steps:**
1. Check initialization logs for: `Starting volume sync timer`
2. Verify player detection: `availablePlayers: [spotify, vlc]`
3. Verify `hasActivePlayer: true` in logs

### Issue 2: Timer Running But No Volume Updates

**Symptoms:**
- See `🔊 Volume sync timer tick` every 2 seconds
- See `🔊 Calling updateCurrentVolume...`
- But volume doesn't change in UI

**Possible Causes:**
1. playerctl command failing
2. Volume parsing issue
3. State not updating

**Debug Steps:**
1. Look for `Raw volume output from playerctl:` in logs
2. Check if it shows a valid number (e.g., "0.75")
3. Verify `Parsed volume:` shows correct percentage
4. Check if `Volume fetched:` shows the new value

**Manual Test:**
```bash
# Test playerctl volume command manually
playerctl volume

# Should output something like: 0.75
```

### Issue 3: Volume Command Returns Nothing

**Symptoms:**
- Log shows: `Volume output was null`
- Or `Raw volume output from playerctl: "" for player: spotify`

**Possible Causes:**
1. Player doesn't support volume control via MPRIS
2. Wrong player name
3. playerctl version issue

**Solutions:**
```bash
# Test if player supports volume
playerctl -p YOUR_PLAYER_NAME volume

# List available players
playerctl -l

# Check playerctl version (needs >= 2.0)
playerctl --version
```

### Issue 4: UI Not Updating Despite State Change

**Symptoms:**
- Logs show volume updated: `Volume fetched: 75 (previous: 50)`
- But UI slider doesn't move

**Possible Causes:**
1. StreamBuilder not rebuilding
2. State equality check preventing update
3. Widget disposed/unmounted

**Debug Steps:**
1. Check if StreamBuilder is receiving updates
2. Add debug print in StreamBuilder's builder method:
   ```dart
   builder: (context, snapshot) {
     print('StreamBuilder rebuild - volume: ${snapshot.data?.volume}');
     // ...
   }
   ```

### Issue 5: Player Switching Doesn't Restart Sync

**Symptoms:**
- Volume syncs for first player
- After switching, no more sync

**Debug Steps:**
1. Look for: `🔊 Starting volume sync timer` after switch
2. Verify: `Syncing volume for player: NEW_PLAYER_NAME`
3. Check switch logs for errors

## Enabling Debug Mode

### In main.dart:
Already enabled! The example runs with debug prints.

### To see even more detail:
Run with verbose flag:
```bash
flutter run -d linux --verbose
```

## Manual Testing Checklist

- [ ] Volume syncs on app start
- [ ] Volume syncs when changed externally
- [ ] Volume syncs after player switch
- [ ] Volume stops syncing when no players
- [ ] Volume resumes syncing when player appears
- [ ] App doesn't crash when player closes
- [ ] Volume updates within 2 seconds
- [ ] Slider position matches actual volume

## Expected Log Sequence (Normal Operation)

```
Starting initialization...
Playerctl version: 2.x.x
Fetching available players...
Found players: [spotify]
Has active player: true
Starting metadata listener...
🔊 Starting volume sync timer
Fetching volume for player: spotify
Raw volume output from playerctl: "0.50" for player: spotify
Parsed volume: 50 (from decimal: 0.50)
Volume fetched: 50 (previous: 50)

[... 2 seconds later ...]

🔊 Volume sync timer tick - hasActivePlayer: true, selectedPlayer: spotify
🔊 Calling updateCurrentVolume...
Fetching volume for player: spotify
Raw volume output from playerctl: "0.50" for player: spotify
Parsed volume: 50 (from decimal: 0.50)
Volume fetched: 50 (previous: 50)
🔊 updateCurrentVolume completed

[... repeat every 2 seconds ...]
```

## What to Share When Reporting Issues

If volume sync still doesn't work, please share:

1. **Full console output** from app start to problem occurrence
2. **playerctl version:**
   ```bash
   playerctl --version
   ```
3. **Test command results:**
   ```bash
   playerctl status
   playerctl volume
   playerctl metadata
   ```
4. **Players available:**
   ```bash
   playerctl -l
   ```
5. **Manual volume change test:**
   ```bash
   playerctl volume 0.8
   playerctl volume  # Should show 0.8
   ```

## Quick Fix Attempts

### Try 1: Restart the App
Sometimes the timer needs a fresh start.

### Try 2: Check Player MPRIS Compliance
Some players don't fully implement MPRIS:
```bash
# This should work for compliant players
playerctl -p YOUR_PLAYER volume 0.5
playerctl -p YOUR_PLAYER volume
```

### Try 3: Update playerctl
```bash
# Check version
playerctl --version

# Should be >= 2.0.0
# Update if needed (Ubuntu/Debian):
sudo apt update && sudo apt upgrade playerctl
```

### Try 4: Test with Known-Good Player
VLC is usually very MPRIS compliant:
```bash
sudo apt install vlc
# Open VLC, play something, test again
```

## Performance Notes

- Each volume sync makes 1 playerctl call
- Call typically takes < 50ms
- Timer runs every 2 seconds
- Minimal CPU/memory impact
- Timer stops when no players active

## Source Code Locations

- Volume sync timer: `lib/core/media_player_manager.dart` line ~150
- Volume fetching: `lib/services/volume_controller.dart` line ~28
- Volume parsing: `lib/services/volume_controller.dart` line ~35
- State updates: `lib/core/media_player_manager.dart` line ~345

---

**Pro Tip:** The 🔊 emoji in logs makes it easy to filter volume-related messages:
```bash
flutter run -d linux 2>&1 | grep "🔊"
```
