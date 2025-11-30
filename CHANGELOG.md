# Changelog

All notable changes to this project will be documented in this file.

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
