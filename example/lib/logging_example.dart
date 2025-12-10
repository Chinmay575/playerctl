import 'package:flutter/material.dart';
import 'package:playerctl/playerctl.dart';

void main() {
  // Configure logging level before initialization
  // Options: LogLevel.none, error, warning, info, debug
  PlayerctlLogger.level = LogLevel.info; // Show info and above (hides debug)

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playerctl with Logging',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoggingExample(),
    );
  }
}

class LoggingExample extends StatefulWidget {
  const LoggingExample({super.key});

  @override
  State<LoggingExample> createState() => _LoggingExampleState();
}

class _LoggingExampleState extends State<LoggingExample> {
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
        title: const Text('Logging Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildLogLevelTile(
                      LogLevel.none,
                      'Silent',
                      'No logs (production)',
                      Icons.volume_off,
                    ),
                    _buildLogLevelTile(
                      LogLevel.error,
                      'Errors Only',
                      'Only show errors',
                      Icons.error_outline,
                    ),
                    _buildLogLevelTile(
                      LogLevel.warning,
                      'Warnings',
                      'Show warnings and errors',
                      Icons.warning_amber,
                    ),
                    _buildLogLevelTile(
                      LogLevel.info,
                      'Info',
                      'Show info, warnings, errors',
                      Icons.info_outline,
                    ),
                    _buildLogLevelTile(
                      LogLevel.debug,
                      'Debug (Verbose)',
                      'Show all logs including debug',
                      Icons.bug_report,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _LogCategoryItem(
                      emoji: '🔍',
                      name: 'DEBUG',
                      desc: 'Verbose debugging',
                    ),
                    _LogCategoryItem(
                      emoji: 'ℹ️',
                      name: 'INFO',
                      desc: 'General information',
                    ),
                    _LogCategoryItem(
                      emoji: '⚠️',
                      name: 'WARNING',
                      desc: 'Warning messages',
                    ),
                    _LogCategoryItem(
                      emoji: '❌',
                      name: 'ERROR',
                      desc: 'Error messages',
                    ),
                    _LogCategoryItem(
                      emoji: '✅',
                      name: 'SUCCESS',
                      desc: 'Success confirmations',
                    ),
                    _LogCategoryItem(
                      emoji: '🎵',
                      name: 'METADATA',
                      desc: 'Metadata updates',
                    ),
                    _LogCategoryItem(
                      emoji: '📋',
                      name: 'PLAYER',
                      desc: 'Player events',
                    ),
                    _LogCategoryItem(
                      emoji: '🔊',
                      name: 'VOLUME',
                      desc: 'Volume changes',
                    ),
                    _LogCategoryItem(
                      emoji: '🔄',
                      name: 'SYNC',
                      desc: 'Sync/timer events',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogLevelTile(
    LogLevel level,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return RadioListTile<LogLevel>(
      value: level,
      groupValue: PlayerctlLogger.level,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            PlayerctlLogger.level = value;
          });
          // Demonstrate the new log level
          PlayerctlLogger.info('Log level changed to: ${value.name}');
        }
      },
      title: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(title)],
      ),
      subtitle: Text(subtitle),
    );
  }
}

class _LogCategoryItem extends StatelessWidget {
  final String emoji;
  final String name;
  final String desc;

  const _LogCategoryItem({
    required this.emoji,
    required this.name,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
