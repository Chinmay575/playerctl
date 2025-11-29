# State Management Independence

This package is designed to work with **any state management solution** or **no state management at all**. The core functionality is completely independent of GetX or any other state management framework.

## Architecture Layers

```dart
┌─────────────────────────────────────────────┐
│   Your Choice of State Management          │
│   (GetX, Riverpod, Bloc, Provider, etc.)   │
│   or NO state management (StatefulWidget)   │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│       MediaPlayerManager (Core)             │
│   - State-management-agnostic               │
│   - Provides Stream<PlayerState>            │
│   - Synchronous state access                │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│       PlayerctlService (SOLID)              │
│   - Follows SOLID principles                │
│   - Separate responsibilities               │
└─────────────────────────────────────────────┘
```

## Usage Examples

### 1. Without Any State Management (Vanilla Flutter)

```dart
import 'package:flutter/material.dart';
import 'package:playerctl/playerctl.dart';

class MediaPlayerPage extends StatefulWidget {
  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  late final MediaPlayerManager manager;

  @override
  void initState() {
    super.initState();
    manager = MediaPlayerManager();
    manager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<PlayerState>(
        stream: manager.stateStream,
        initialData: manager.state,
        builder: (context, snapshot) {
          final state = snapshot.data!;
          return Text('Now playing: ${state.currentMedia.title}');
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => manager.playPause(),
        child: Icon(Icons.play_arrow),
      ),
    );
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }
}
```

### 2. With GetX (Provided Wrapper)

```dart
import 'package:get/get.dart';
import 'package:playerctl/playerctl.dart';

class MediaPlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MediaController());
    
    return Scaffold(
      body: Obx(() => Text('Now playing: ${controller.currentMedia.value.title}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.playPause(),
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
```

### 3. With Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playerctl/playerctl.dart';

// Create a provider
final mediaManagerProvider = Provider((ref) {
  final manager = MediaPlayerManager();
  manager.initialize();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final manager = ref.watch(mediaManagerProvider);
  return manager.stateStream;
});

// Use in widgets
class MediaPlayerPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(playerStateProvider);
    final manager = ref.read(mediaManagerProvider);
    
    return stateAsync.when(
      data: (state) => Text('Now playing: ${state.currentMedia.title}'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### 4. With Bloc

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playerctl/playerctl.dart';

// Create a Cubit
class MediaPlayerCubit extends Cubit<PlayerState> {
  final MediaPlayerManager _manager;
  StreamSubscription? _subscription;

  MediaPlayerCubit(this._manager) : super(PlayerState.initial()) {
    _subscription = _manager.stateStream.listen(emit);
    _manager.initialize();
  }

  void playPause() => _manager.playPause();
  void next() => _manager.next();
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    _manager.dispose();
    return super.close();
  }
}

// Use in widgets
class MediaPlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MediaPlayerCubit(MediaPlayerManager()),
      child: BlocBuilder<MediaPlayerCubit, PlayerState>(
        builder: (context, state) {
          return Text('Now playing: ${state.currentMedia.title}');
        },
      ),
    );
  }
}
```

### 5. With Provider

```dart
import 'package:provider/provider.dart';
import 'package:playerctl/playerctl.dart';

// Create a ChangeNotifier wrapper
class MediaPlayerNotifier extends ChangeNotifier {
  final MediaPlayerManager _manager = MediaPlayerManager();
  StreamSubscription? _subscription;
  
  PlayerState get state => _manager.state;

  MediaPlayerNotifier() {
    _subscription = _manager.stateStream.listen((_) => notifyListeners());
    _manager.initialize();
  }

  void playPause() => _manager.playPause();
  
  @override
  void dispose() {
    _subscription?.cancel();
    _manager.dispose();
    super.dispose();
  }
}

// Use in widgets
class MediaPlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MediaPlayerNotifier(),
      child: Consumer<MediaPlayerNotifier>(
        builder: (context, notifier, child) {
          return Text('Now playing: ${notifier.state.currentMedia.title}');
        },
      ),
    );
  }
}
```

## Core API: MediaPlayerManager

The `MediaPlayerManager` is the heart of the package and is completely state-management-agnostic.

### Properties

```dart
// Synchronous state access
PlayerState get state;

// Reactive stream
Stream<PlayerState> get stateStream;

// Convenient getters
MediaInfo get currentMedia;
bool get isPlayerctlInstalled;
bool get hasActivePlayer;
List<String> get availablePlayers;
String get selectedPlayer;
bool get isLoading;
String get errorMessage;
int get volume;
```

### Methods

```dart
// Initialization
Future<void> initialize();
Future<void> refreshPlayerList();

// Playback control
Future<bool> play();
Future<bool> pause();
Future<bool> playPause();
Future<bool> stop();
Future<bool> next();
Future<bool> previous();

// Volume control
Future<bool> setVolume(int volume);
Future<void> updateCurrentVolume();

// Player selection
Future<void> switchPlayer(String playerName);

// Metadata listening
void startListening([String? player]);
void stopListening();

// Lifecycle
void dispose();
```

## PlayerState Model

Immutable state object that represents the complete player state:

```dart
class PlayerState {
  final MediaInfo currentMedia;
  final bool isPlayerctlInstalled;
  final bool hasActivePlayer;
  final List<String> availablePlayers;
  final String selectedPlayer;
  final bool isLoading;
  final String errorMessage;
  final int volume;

  // Immutable updates
  PlayerState copyWith({...});
}
```

## Benefits

### ✅ Freedom of Choice

- Use any state management solution you prefer
- Or use none at all with vanilla Flutter
- No forced dependencies

### ✅ Easy Migration

- Switch state management solutions without changing core logic
- Package updates won't break your state management

### ✅ Testability

- Test core logic without state management
- Mock `MediaPlayerManager` easily
- No framework-specific testing tools needed

### ✅ Learning Curve

- New to state management? Use vanilla Flutter
- Team uses Bloc? Wrap it in a Bloc
- Prefer GetX? We provide a wrapper

### ✅ Bundle Size

- Don't use GetX? It won't be in your bundle
- Tree-shaking removes unused code
- Minimal dependencies

## Migration Guide

### From GetX-only version

**Before:**

```dart
final controller = Get.put(MediaController());
// Tightly coupled to GetX
```

**After (still using GetX):**

```dart
final controller = Get.put(MediaController());
// Works exactly the same!
// But now you can switch if needed
```

**After (switching to vanilla):**

```dart
final manager = MediaPlayerManager();
// No GetX dependency needed!
```

## Best Practices

1. **Initialize once**: Create `MediaPlayerManager` at app startup or screen init
2. **Dispose properly**: Always call `dispose()` in cleanup
3. **Use streams**: Subscribe to `stateStream` for reactive updates
4. **Handle errors**: Check `state.errorMessage` and `state.isPlayerctlInstalled`
5. **State snapshots**: Use `state` getter for synchronous access

## Conclusion

This package follows the principle: **"Don't force your architecture on users"**

- Core functionality is framework-agnostic
- State management is a user choice
- Provides convenience wrappers but doesn't mandate them
- Clean, maintainable, and flexible architecture
