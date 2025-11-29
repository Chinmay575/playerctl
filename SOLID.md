# SOLID Principles Implementation

This document explains how the playerctl package follows SOLID principles.

## 1. Single Responsibility Principle (SRP)

Each class has one well-defined responsibility:

### **PlayerctlCommandExecutor**
- **Responsibility**: Execute playerctl commands via subprocess
- **Location**: `lib/services/command_executor.dart`

### **PlayerctlSystemChecker**
- **Responsibility**: Check if playerctl is installed and get version info
- **Location**: `lib/services/system_checker.dart`

### **PlayerDetector**
- **Responsibility**: Detect and list available media players
- **Location**: `lib/services/player_detector.dart`

### **MetadataProvider**
- **Responsibility**: Fetch and stream media metadata
- **Location**: `lib/services/metadata_provider.dart`

### **PlaybackController**
- **Responsibility**: Handle playback commands (play, pause, next, etc.)
- **Location**: `lib/services/playback_controller.dart`

### **VolumeController**
- **Responsibility**: Manage volume operations
- **Location**: `lib/services/volume_controller.dart`

### **MediaController** (GetX)
- **Responsibility**: Manage application state and coordinate services
- **Location**: `lib/controllers/media_controller.dart`

## 2. Open/Closed Principle (OCP)

The system is **open for extension** but **closed for modification**:

- All services implement **interfaces** (`IPlayerctlService`, `IPlaybackController`, etc.)
- New implementations can be added without modifying existing code
- The `PlayerctlService` facade can be extended with new functionality

**Example**: Adding a new playback feature
```dart
class AdvancedPlaybackController extends PlaybackController {
  Future<bool> shuffle([String? player]) async {
    return _executor.executeCommand('shuffle', player);
  }
}
```

## 3. Liskov Substitution Principle (LSP)

All implementations can be substituted with their interfaces without breaking functionality:

```dart
// Any IPlaybackController can be used interchangeably
IPlaybackController controller1 = PlaybackController(executor);
IPlaybackController controller2 = AdvancedPlaybackController(executor);

// Both work the same way
await controller1.play();
await controller2.play();
```

## 4. Interface Segregation Principle (ISP)

Clients aren't forced to depend on interfaces they don't use. We have **specific, focused interfaces**:

- `IPlayerctlService` - System checks only
- `IPlayerDetector` - Player detection only
- `IMetadataProvider` - Metadata operations only
- `IPlaybackController` - Playback commands only
- `IVolumeController` - Volume operations only
- `ICommandExecutor` - Raw command execution only

**Example**: If you only need playback control, depend on `IPlaybackController`:
```dart
class SimplePlayer {
  final IPlaybackController _playback;
  
  SimplePlayer(this._playback);
  
  void playMusic() => _playback.play();
}
```

## 5. Dependency Inversion Principle (DIP)

High-level modules don't depend on low-level modules. Both depend on abstractions:

### **Before** (violates DIP):
```dart
class MediaController {
  final PlayerctlCommandExecutor executor = PlayerctlCommandExecutor(); // Direct dependency
}
```

### **After** (follows DIP):
```dart
class MediaController {
  final IPlaybackController _playback; // Depends on abstraction
  final IMetadataProvider _metadata;   // Depends on abstraction
  
  MediaController(this._playback, this._metadata); // Injected
}
```

### **Dependency Injection**

The `PlayerctlService` supports dependency injection for testing:

```dart
// Production
final service = PlayerctlService();

// Testing with mocks
final service = PlayerctlService.withDependencies(
  commandExecutor: MockCommandExecutor(),
  systemChecker: MockSystemChecker(),
  playerDetector: MockPlayerDetector(),
  metadataProvider: MockMetadataProvider(),
  playbackController: MockPlaybackController(),
  volumeController: MockVolumeController(),
);
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│           MediaController (GetX State)              │
│                                                     │
└───────────────────┬─────────────────────────────────┘
                    │ depends on
                    ▼
┌─────────────────────────────────────────────────────┐
│            PlayerctlService (Facade)                │
│                                                     │
│  Implements: IPlayerctlService, IPlayerDetector,   │
│  IMetadataProvider, IPlaybackController,            │
│  IVolumeController, ICommandExecutor                │
└───────────────────┬─────────────────────────────────┘
                    │ delegates to
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│SystemChecker │ │PlayerDetector│ │MetadataProvi-│
│              │ │              │ │    der       │
└──────────────┘ └──────────────┘ └──────────────┘
        │           │           │
        └───────────┼───────────┘
                    │ uses
                    ▼
        ┌──────────────────────┐
        │ CommandExecutor      │
        │ (subprocess runner)  │
        └──────────────────────┘
                    │
                    ▼
            ┌───────────────┐
            │  playerctl    │
            │ (CLI tool)    │
            └───────────────┘
```

## Benefits of SOLID Implementation

### 1. **Testability**
- Each component can be tested in isolation
- Easy to mock dependencies
- Clear boundaries for unit tests

### 2. **Maintainability**
- Changes to one component don't affect others
- Easy to locate and fix bugs
- Clear responsibilities

### 3. **Extensibility**
- Add new features without modifying existing code
- Support multiple implementations
- Easy to add new player types

### 4. **Readability**
- Each file has a single, clear purpose
- Easy for new developers to understand
- Self-documenting code structure

### 5. **Flexibility**
- Swap implementations without breaking code
- Support different testing strategies
- Easy to add caching, logging, or error handling

## Usage Examples

### Basic Usage (High-level)
```dart
final service = PlayerctlService();
await service.play();
await service.setVolume(75);
```

### Advanced Usage (Direct service access)
```dart
final executor = PlayerctlCommandExecutor();
final playback = PlaybackController(executor);
final volume = VolumeController(executor);

await playback.play();
await volume.setVolume(75);
```

### Testing with Mocks
```dart
class MockPlaybackController implements IPlaybackController {
  @override
  Future<bool> play([String? player]) async => true;
  
  // ... implement other methods
}

void main() {
  test('play command works', () async {
    final mock = MockPlaybackController();
    final result = await mock.play();
    expect(result, true);
  });
}
```

## Design Patterns Used

1. **Facade Pattern**: `PlayerctlService` provides a simple interface to complex subsystems
2. **Strategy Pattern**: Different implementations of interfaces can be swapped
3. **Dependency Injection**: Dependencies are injected rather than created internally
4. **Observer Pattern**: `MetadataProvider` uses streams for real-time updates
5. **Command Pattern**: `PlaybackController` encapsulates commands as methods

## Conclusion

This architecture ensures:
- ✅ Easy to test
- ✅ Easy to maintain
- ✅ Easy to extend
- ✅ Clear separation of concerns
- ✅ Follows industry best practices
- ✅ Production-ready code quality
