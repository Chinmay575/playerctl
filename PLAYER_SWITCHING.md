# Player Switching & Volume Synchronization

This document explains the improvements made to player switching and volume synchronization in the playerctl plugin.

## Issues Fixed

### 1. Player Switching Not Updating Media
**Problem:** When switching between active players (e.g., from Spotify to VLC), the media information (title, artist, status) was not immediately updated.

**Solution:** The `switchPlayer` method now:
- Immediately fetches current metadata from the new player
- Updates the state before starting the metadata stream
- Shows loading state during the switch operation

### 2. Volume Not Synchronized
**Problem:** Volume changes made outside the app (system volume controls, other apps) were not reflected in the plugin state.

**Solution:** Added automatic periodic volume synchronization every 2 seconds that:
- Continuously syncs volume from the active player
- Starts automatically when players are detected
- Stops when no players are available
- Restarts when switching players

## Implementation Details

### Enhanced Player Switching

The `switchPlayer` method now performs these steps in order:

```dart
Future<void> switchPlayer(String playerName) async {
  // 1. Validate player exists
  if (!_state.availablePlayers.contains(playerName)) {
    _updateState(_state.copyWith(errorMessage: 'Player $playerName is not available'));
    return;
  }

  // 2. Set loading state
  _updateState(_state.copyWith(selectedPlayer: playerName, isLoading: true));
  
  // 3. Stop current metadata stream
  stopListening();
  
  // 4. Fetch current metadata immediately (NEW)
  try {
    final metadata = await _service.getCurrentMetadata(playerName);
    if (metadata.isNotEmpty) {
      _updateMediaInfo(metadata);
    }
  } catch (e) {
    debugPrint('Error fetching metadata for player $playerName: $e');
  }
  
  // 5. Fetch current volume immediately (ENHANCED)
  await updateCurrentVolume();
  
  // 6. Start new metadata stream
  startListening(playerName);
  
  // 7. Restart volume sync for new player (NEW)
  _startVolumeSync();
  
  // 8. Clear loading state
  _updateState(_state.copyWith(isLoading: false));
}
```

### Automatic Volume Synchronization

Added a new periodic timer that syncs volume every 2 seconds:

```dart
Timer? _volumeSyncTimer;

void _startVolumeSync() {
  _volumeSyncTimer?.cancel();
  _volumeSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
    if (_state.hasActivePlayer) {
      await updateCurrentVolume();
    }
  });
}

void _stopVolumeSync() {
  _volumeSyncTimer?.cancel();
  _volumeSyncTimer = null;
}
```

### Lifecycle Management

Volume sync is automatically managed throughout the player lifecycle:

| Event | Action |
|-------|--------|
| Plugin initialized with active player | Start volume sync |
| New player detected | Start volume sync |
| All players disconnected | Stop volume sync |
| Player switched | Restart volume sync |
| Plugin disposed | Cancel volume sync timer |

### Integration Points

Volume sync starts at three key points:

1. **Initial startup** (in `initialize()`)
```dart
if (_state.hasActivePlayer) {
  startListening();
  await updateCurrentVolume();
  _startVolumeSync();  // ← Added
}
```

2. **Player detection** (in `_startPlayerCheck()`)
```dart
if (!hadPlayers && _state.hasActivePlayer) {
  startListening();
  await updateCurrentVolume();
  _startVolumeSync();  // ← Added
}
```

3. **Player switching** (in `switchPlayer()`)
```dart
startListening(playerName);
_startVolumeSync();  // ← Added
```

## Performance Considerations

### Polling Intervals

The plugin uses two periodic timers:

- **Player Check:** 5 seconds - Checks for new/removed players
- **Volume Sync:** 2 seconds - Syncs volume from active player

These intervals are chosen to balance responsiveness with system resource usage.

### Resource Usage

Volume sync is lightweight:
- Only runs when players are active
- Single `playerctl volume` command every 2 seconds
- Command typically completes in <50ms
- Minimal CPU/memory impact

### Optimization Opportunities

Future optimizations could include:

1. **Event-driven volume updates** - Listen to D-Bus signals instead of polling
2. **Adaptive polling** - Increase interval when volume hasn't changed
3. **Configurable intervals** - Let users adjust sync frequency
4. **Suspend sync when minimized** - Pause sync when app is in background

## Testing

### Manual Testing Scenarios

1. **Test Player Switching:**
   ```
   - Start two media players (e.g., VLC and Spotify)
   - Play different media in each
   - Switch between players in the app
   - Verify: Media info updates immediately
   - Verify: Playback status reflects correct player
   ```

2. **Test Volume Sync:**
   ```
   - Start a media player
   - Change volume using system controls
   - Wait up to 2 seconds
   - Verify: App shows updated volume
   ```

3. **Test Volume During Switch:**
   ```
   - Start two players with different volumes
   - Switch between them
   - Verify: Volume updates immediately on switch
   - Verify: Volume continues syncing for new player
   ```

4. **Test Player Disconnect:**
   ```
   - Start player and verify volume sync
   - Close all media players
   - Verify: Volume sync stops (no unnecessary polling)
   - Restart a player
   - Verify: Volume sync resumes automatically
   ```

### Debug Logging

The implementation includes debug prints for monitoring:

```dart
debugPrint('Error fetching metadata for player $playerName: $e');
```

Enable Flutter debug mode to see these logs.

## API Changes

### Public API (No Changes)
The external API remains unchanged. All improvements are internal.

### Internal Changes

New private methods:
- `_startVolumeSync()` - Start periodic volume polling
- `_stopVolumeSync()` - Stop volume polling

New private field:
- `Timer? _volumeSyncTimer` - Timer for volume sync

Enhanced method:
- `switchPlayer()` - Now includes immediate metadata fetch and volume sync restart

## State Management Integration

These changes work seamlessly with all state management approaches:

### GetX Example
```dart
class MediaController extends GetxController {
  final manager = MediaPlayerManager();
  
  // Volume automatically syncs via manager's stream
  int? get volume => state.value.volume;
  
  // Switching updates immediately
  Future<void> switchToPlayer(String name) async {
    await manager.switchPlayer(name);
    // State automatically updates via stream
  }
}
```

### Vanilla Flutter Example
```dart
StreamBuilder<PlayerState>(
  stream: manager.stateStream,
  builder: (context, snapshot) {
    final volume = snapshot.data?.volume ?? 0;
    // Volume automatically updates every 2 seconds
    return Slider(
      value: volume.toDouble(),
      onChanged: (value) => manager.setVolume(value.toInt()),
    );
  },
)
```

## Error Handling

The implementation includes robust error handling:

1. **Invalid player switch** - Shows error message, doesn't change state
2. **Metadata fetch failure** - Logs error, continues with stream
3. **Volume fetch failure** - Silent failure, retries on next cycle
4. **Timer cleanup** - All timers properly canceled on dispose

## Backward Compatibility

All changes are backward compatible:
- No API changes
- No behavior changes for existing code
- Only improvements to data freshness

## Summary

### Before
- ❌ Player switch: Waited for first stream update (could be several seconds)
- ❌ Volume: Only updated when explicitly changed via app
- ❌ External volume changes: Not reflected in app

### After
- ✅ Player switch: Immediate metadata and volume update
- ✅ Volume: Automatically syncs every 2 seconds
- ✅ External volume changes: Reflected within 2 seconds
- ✅ Resource efficient: Sync stops when no players active
- ✅ Clean lifecycle: All timers properly managed

The plugin now provides a responsive, real-time media control experience!
