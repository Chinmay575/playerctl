# Changelog

All notable changes to this project will be documented in this file.

## 1.1.0

* **Major Features**:
  * **Seek/scrub functionality** for playback position control
    * `getPosition()` - Get current playback position in microseconds
    * `seekTo(int positionMicroseconds)` - Seek to absolute position
    * `seek(int offsetMicroseconds)` - Seek relative to current position (supports positive/negative offset)
    * `seekForward(int seconds)` - Convenience method to skip forward by seconds
    * `seekBackward(int seconds)` - Convenience method to skip backward by seconds
    * All seek methods support optional player parameter for multi-player control
    * Position values in microseconds for precision (MPRIS standard)
    * Returns `true` on success, `false` on failure
    * Error handling with try-catch blocks
    * Added seek operations across all layers: `PlaybackController`, `PlayerctlService`, and `MediaPlayerManager`
  * **Local HTTP server for album art**
    * Added `AlbumArtServer` - HTTP server running on `0.0.0.0:8765`
    * Automatically converts file:// URLs to local HTTP URLs (e.g., `http://0.0.0.0:8765/art/935c12.jpg`)
    * Access album art from other devices by replacing `0.0.0.0` with your machine's IP address
    * Example: `http://0.0.0.0:8765/art/abc123.jpg` → `http://192.168.1.100:8765/art/abc123.jpg`
    * Spotify and other online URLs (https://) remain unchanged
    * Server starts automatically when metadata is fetched
    * Server stops automatically when metadata provider is disposed
    * Supports JPEG, PNG, GIF, WebP, BMP, and SVG formats
    * CORS enabled for cross-origin requests
    * File caching for efficient serving
    * Health check endpoint at `/`
  * **Multi-player data streaming**
    * New `allPlayersMedia` map in `PlayerState` containing `MediaInfo` for all active players
    * Automatically fetches metadata for all available players simultaneously
    * Updates all players' data every 3 seconds (along with selected player's real-time stream)
    * Access any player's media info via `state.allPlayersMedia['playerName']`
    * Useful for displaying multiple players' status in UI
    * Updated `PlayerState` with `allPlayersMedia` field
    * Included in JSON serialization/deserialization and equality comparisons
    * Backward compatible - defaults to empty map
    * Enhanced `_refreshAllPlayersMetadata()` method for batch metadata fetching
  * **Auto-pause other players feature**
    * When calling `play()`, `playPause()`, `next()`, or `previous()`, all other playing players are automatically paused
    * Prevents audio conflicts and glitching when multiple players are active
    * Added `_pauseOtherPlayers()` helper method
    * Only pauses players that are currently in "Playing" status
* **Bug Fixes**:
  * Fixed album art images trying to download instead of displaying inline
    * Added `Content-Disposition: inline` header to HTTP server
    * Added cache control headers for better performance
  * Fixed glitching when switching to inactive players
    * Clear stale media data immediately on player switch
    * Stop all sync timers before switching
    * Reduced delay and improved state transitions
  * Fixed metadata from other players overwriting current display
    * Added player name filtering in `_updateMediaInfo`
    * Matches player instance names (e.g., "brave.instance123")
  * Fixed multiple players playing simultaneously
    * Automatically pauses other players when starting playback
    * Applied to `play()`, `playPause()`, `next()`, and `previous()` methods
  * Added missing seek methods to `MediaPlayerManager`
    * Full seek functionality now available in manager API
* **Testing**:
  * Added comprehensive test case for multi-player data verification
  * All tests passing (20 tests)

## 1.0.4

* Added album cover/art URL support (`artUrl` field in `MediaInfo`)
  * Fetches `mpris:artUrl` from playerctl metadata
  * Included in JSON serialization/deserialization
  * Included in equality comparisons and change detection
  * Available for displaying album artwork in UI
* All tests passing (19 tests)

## 1.0.3

* **Breaking Change**: Implemented Equatable for all models (`PlayerState` and `MediaInfo`)
  * Removed manual `==` operator and `hashCode` implementations
  * More efficient and reliable equality comparisons
  * Better performance for state management solutions
  * Added `equatable` package as dependency
* Added stream optimization: metadata changes only emit when actual changes occur (ignores position updates)
  * Significantly reduces unnecessary UI updates
  * Ignores position changes that happen constantly during playback
  * Only emits when title, artist, album, status, player, or length changes
* Fixed test for invalid volume range to expect exception instead of false
* All tests passing (19 tests)

## 1.0.2

* **Breaking Change**: Implemented Equatable for all models (`PlayerState` and `MediaInfo`)
  * Removed manual `==` operator and `hashCode` implementations
  * More efficient and reliable equality comparisons
  * Better performance for state management solutions
* Added stream optimization: metadata changes only emit when actual changes occur (ignores position updates)
* Added JSON serialization support (`toJson` and `fromJson`) to `PlayerState` and `MediaInfo`
* Added platform specification to pubspec.yaml (Linux only)
* Fixed test for invalid volume range to expect exception instead of false
* Code formatting improvements and cleanup
* Enhanced type safety in JSON parsing with null checks

## 1.0.1

* Updated package description for better clarity
* Refined documentation and LICENSE file
* Minor cleanup and improvements

## 1.0.0

* Initial stable release
* State-agnostic core architecture with SOLID principles
* Real-time metadata streaming with automatic process restart (up to 5 attempts)
* Triple-layer synchronization (stream + metadata refresh + volume sync)
* Multi-player support with automatic player switching
* Shuffle and loop controls with cycle support
* Volume synchronization detects external changes
* Robust error handling and automatic recovery
* Optional GetX wrapper for reactive state management
* Special character support in metadata (handles pipe characters correctly)
* Debounced player switching prevents glitches during rapid changes
