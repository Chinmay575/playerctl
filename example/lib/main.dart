import 'package:flutter/material.dart';
import 'package:playerctl/playerctl.dart';

/// Example of using playerctl WITHOUT any state management
/// This uses vanilla Flutter with StatefulWidget and StreamBuilder
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playerctl - No State Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MediaPlayerPage(),
    );
  }
}

class MediaPlayerPage extends StatefulWidget {
  const MediaPlayerPage({super.key});

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  // Create the manager - no state management framework needed!
  late final MediaPlayerManager manager;

  @override
  void initState() {
    super.initState();
    manager = MediaPlayerManager();
    manager.initialize();
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Media Controller (No State Management)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => manager.refreshPlayerList(),
            tooltip: 'Refresh Players',
          ),
        ],
      ),
      // Use StreamBuilder to listen to state changes
      body: StreamBuilder<PlayerState>(
        stream: manager.stateStream,
        initialData: manager.state,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;

          // Show loading
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error if playerctl not installed
          if (!state.isPlayerctlInstalled) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => manager.retry(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show message if no players
          if (!state.hasActivePlayer) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No active media players found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start playing media in Spotify, VLC, or any MPRIS-compatible player',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show player UI
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Player selector
                  if (state.availablePlayers.length > 1) ...[
                    const Text(
                      'Active Players',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: state.availablePlayers.map((player) {
                        final isSelected = state.selectedPlayer == player;
                        return ChoiceChip(
                          label: Text(player),
                          selected: isSelected,
                          onSelected: (_) => manager.switchPlayer(player),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Album art placeholder
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 128,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Song info
                  Text(
                    state.currentMedia.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.currentMedia.artist,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.currentMedia.album,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(state.currentMedia.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      state.currentMedia.status,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Playback controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => manager.previous(),
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 48,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => manager.playPause(),
                          icon: Icon(
                            state.currentMedia.status == 'Playing'
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          color: Colors.white,
                          iconSize: 48,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => manager.next(),
                        icon: const Icon(Icons.skip_next),
                        iconSize: 48,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Volume control
                  const Text(
                    'Volume',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: state.volume.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${state.volume}%',
                          onChanged: (value) =>
                              manager.setVolume(value.toInt()),
                        ),
                      ),
                      const Icon(Icons.volume_up),
                      const SizedBox(width: 8),
                      Text('${state.volume}%'),
                    ],
                  ),

                  // Error message
                  if (state.errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'playing':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'stopped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
