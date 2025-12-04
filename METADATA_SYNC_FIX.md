# Metadata Sync Fix Documentation

## Issue Description

Users reported that metadata was being printed (debug logs showed metadata updates) but the UI was not syncing/updating. The metadata stream was working correctly, but updates were being rejected.

## Root Cause

The issue was in the player name matching logic in `MediaPlayerManager._updateMediaInfo()`. 

### The Problem:

1. When listing available players using `playerctl --list-all`, the command returns **instance-specific names** like:
   - `brave.instance3723`
   - `spotify.instance12345`
   - `vlc.instance987`

2. However, when fetching metadata using `playerctl --player=brave.instance3723 metadata {{playerName}}`, the `{{playerName}}` template returns only the **base player name**:
   - `brave`
   - `spotify`
   - `vlc`

3. The manager selects a player like `brave.instance3723`, but then receives metadata with `playerName: "brave"`.

4. The original matching logic only checked:
   ```dart
   media.playerName == _state.selectedPlayer  // "brave" != "brave.instance3723" ❌
   media.playerName.startsWith('${_state.selectedPlayer}.')  // "brave".startsWith("brave.instance3723.") ❌
   ```
   
   This caused ALL metadata updates to be rejected with the warning:
   ```
   ⚠️ Ignoring metadata from brave (selected: brave.instance3723)
   ```

## The Solution

Added bidirectional player name matching in `lib/core/media_player_manager.dart`:

```dart
final isSelectedPlayer =
    _state.selectedPlayer.isEmpty ||
    media.playerName == _state.selectedPlayer ||
    // Match: selected="brave", metadata="brave.instance123"
    media.playerName.startsWith('${_state.selectedPlayer}.') ||
    // Match: selected="brave.instance3723", metadata="brave" ✅ NEW!
    _state.selectedPlayer.startsWith('${media.playerName}.');
```

### How it works:

| Selected Player | Metadata Player | Old Result | New Result |
|----------------|----------------|------------|------------|
| `brave` | `brave` | ✅ Match | ✅ Match |
| `brave` | `brave.instance123` | ✅ Match | ✅ Match |
| `brave.instance3723` | `brave` | ❌ Reject | ✅ Match (FIXED!) |
| `brave.instance3723` | `spotify` | ❌ Reject | ❌ Reject |

## Debug Logging

Added comprehensive debug logging to help diagnose similar issues:

```dart
debugPrint('🔍 Metadata received - Player: ${media.playerName}, Title: ${media.title}, Selected: ${_state.selectedPlayer}');
debugPrint('🔍 isSelectedPlayer: $isSelectedPlayer');

if (isSelectedPlayer) {
  debugPrint('✅ Updating media info: ${media.title} by ${media.artist}');
  _updateState(_state.copyWith(currentMedia: media, errorMessage: ''));
} else {
  debugPrint('⚠️ Ignoring metadata from ${media.playerName} (selected: ${_state.selectedPlayer})');
}
```

## Testing

The fix was tested with:
1. All 20 existing unit tests passing
2. Manual testing with multiple players (Brave browser, Spotify, etc.)
3. Player switching scenarios
4. Multi-player environments

## Files Modified

- `lib/core/media_player_manager.dart` (lines 329-368)

## Impact

- **Before**: Metadata stream was working but UI froze (no updates)
- **After**: Metadata updates sync properly to the UI in real-time
- **Breaking Changes**: None
- **Performance**: No impact (just improved logic)

## Related Issues

This fix addresses:
- UI not updating when metadata changes
- Player switching showing stale data
- Multi-player environments with instance-specific names

## Version

Fixed in version 1.1.0
