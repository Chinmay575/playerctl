import 'package:flutter/material.dart';
import 'package:playerctl/playerctl.dart';

/// This example demonstrates all the ways to configure logging in playerctl
void main() {
  // ============================================
  // METHOD 1: Global Configuration (Recommended)
  // ============================================
  // Set log level globally before creating any managers
  PlayerctlLogger.level = LogLevel.info;

  // Or use convenience methods:
  // PlayerctlLogger.enableAll();  // LogLevel.debug - verbose
  // PlayerctlLogger.disableAll(); // LogLevel.none - silent

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playerctl Logging Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoggingConfigPage(),
    );
  }
}

class LoggingConfigPage extends StatefulWidget {
  const LoggingConfigPage({super.key});

  @override
  State<LoggingConfigPage> createState() => _LoggingConfigPageState();
}

class _LoggingConfigPageState extends State<LoggingConfigPage> {
  late MediaPlayerManager manager;
  LogLevel currentLogLevel = PlayerctlLogger.level;

  @override
  void initState() {
    super.initState();

    // ============================================
    // METHOD 2: Constructor Configuration
    // ============================================
    // Pass log level when creating the manager
    manager = MediaPlayerManager(
      logLevel: LogLevel.info, // Set initial log level
    );

    manager.initialize();
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  void _changeLogLevel(LogLevel newLevel) {
    setState(() {
      currentLogLevel = newLevel;
    });

    // ============================================
    // METHOD 3: Runtime Change via Manager
    // ============================================
    manager.setLogLevel(newLevel);

    // ============================================
    // METHOD 4: Runtime Change via Logger (Alternative)
    // ============================================
    // PlayerctlLogger.level = newLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Logging Configuration Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Log Level Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Current Log Level',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentLogLevel.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getColorForLevel(currentLogLevel),
                      ),
                    ),
                    Text(
                      _getDescriptionForLevel(currentLogLevel),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Log Level Options
            const Text(
              'Choose Log Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildLogLevelCard(
              LogLevel.none,
              'Silent Mode',
              'No logs at all. Best for production.',
              Icons.volume_off,
              Colors.grey,
            ),

            _buildLogLevelCard(
              LogLevel.error,
              'Errors Only',
              'Only show critical errors. Production default.',
              Icons.error_outline,
              Colors.red,
            ),

            _buildLogLevelCard(
              LogLevel.warning,
              'Warnings',
              'Show warnings and errors.',
              Icons.warning_amber,
              Colors.orange,
            ),

            _buildLogLevelCard(
              LogLevel.info,
              'Info',
              'Show info, warnings, and errors. Recommended.',
              Icons.info_outline,
              Colors.blue,
            ),

            _buildLogLevelCard(
              LogLevel.debug,
              'Debug (Verbose)',
              'Show all logs. Development default.',
              Icons.bug_report,
              Colors.purple,
            ),

            const SizedBox(height: 24),

            // Test Buttons
            const Text(
              'Test Logging',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => PlayerctlLogger.debug('Test debug message'),
                  icon: const Text('🔍'),
                  label: const Text('Debug'),
                ),
                ElevatedButton.icon(
                  onPressed: () => PlayerctlLogger.info('Test info message'),
                  icon: const Text('ℹ️'),
                  label: const Text('Info'),
                ),
                ElevatedButton.icon(
                  onPressed: () => PlayerctlLogger.warning('Test warning'),
                  icon: const Text('⚠️'),
                  label: const Text('Warning'),
                ),
                ElevatedButton.icon(
                  onPressed: () => PlayerctlLogger.error('Test error'),
                  icon: const Text('❌'),
                  label: const Text('Error'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Code Examples Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration Examples',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCodeExample(
                      'Method 1: Global',
                      'PlayerctlLogger.level = LogLevel.info;',
                    ),
                    _buildCodeExample(
                      'Method 2: Constructor',
                      'MediaPlayerManager(logLevel: LogLevel.info)',
                    ),
                    _buildCodeExample(
                      'Method 3: Runtime',
                      'manager.setLogLevel(LogLevel.error);',
                    ),
                    _buildCodeExample(
                      'Method 4: Direct',
                      'PlayerctlLogger.level = LogLevel.debug;',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Log Categories Info
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
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
                    _LogCategoryRow(emoji: '🔍', name: 'DEBUG', level: 'debug'),
                    _LogCategoryRow(emoji: 'ℹ️', name: 'INFO', level: 'info'),
                    _LogCategoryRow(
                      emoji: '⚠️',
                      name: 'WARNING',
                      level: 'warning',
                    ),
                    _LogCategoryRow(emoji: '❌', name: 'ERROR', level: 'error'),
                    _LogCategoryRow(emoji: '✅', name: 'SUCCESS', level: 'info'),
                    _LogCategoryRow(
                      emoji: '🎵',
                      name: 'METADATA',
                      level: 'debug',
                    ),
                    _LogCategoryRow(emoji: '📋', name: 'PLAYER', level: 'info'),
                    _LogCategoryRow(
                      emoji: '🔊',
                      name: 'VOLUME',
                      level: 'debug',
                    ),
                    _LogCategoryRow(emoji: '🔄', name: 'SYNC', level: 'debug'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogLevelCard(
    LogLevel level,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = currentLogLevel == level;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(description),
        trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
        onTap: () => _changeLogLevel(level),
      ),
    );
  }

  Widget _buildCodeExample(String title, String code) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.none:
        return Colors.grey;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.debug:
        return Colors.purple;
    }
  }

  String _getDescriptionForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.none:
        return 'Silent - No logs';
      case LogLevel.error:
        return 'Errors only';
      case LogLevel.warning:
        return 'Warnings + Errors';
      case LogLevel.info:
        return 'Info + Warnings + Errors';
      case LogLevel.debug:
        return 'All logs (verbose)';
    }
  }
}

class _LogCategoryRow extends StatelessWidget {
  final String emoji;
  final String name;
  final String level;

  const _LogCategoryRow({
    required this.emoji,
    required this.name,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          Chip(
            label: Text(level, style: const TextStyle(fontSize: 10)),
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    );
  }
}
