# Changelog

All notable changes to this project will be documented in this file.

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
