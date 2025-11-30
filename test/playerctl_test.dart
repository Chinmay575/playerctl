import 'package:flutter_test/flutter_test.dart';
import 'package:playerctl/playerctl.dart';

void main() {
  group('MediaInfo Tests', () {
    test('MediaInfo creation with default values', () {
      final media = MediaInfo();
      expect(media.title, 'Unknown');
      expect(media.artist, 'Unknown');
      expect(media.status, 'Stopped');
    });

    test('MediaInfo creation with custom values', () {
      final media = MediaInfo(
        title: 'Test Song',
        artist: 'Test Artist',
        status: 'Playing',
      );
      expect(media.title, 'Test Song');
      expect(media.artist, 'Test Artist');
      expect(media.status, 'Playing');
    });

    test('MediaInfo copyWith updates only specified fields', () {
      final media = MediaInfo(title: 'Original', artist: 'Original Artist');
      final updated = media.copyWith(title: 'Updated');

      expect(updated.title, 'Updated');
      expect(updated.artist, 'Original Artist');
    });

    test('MediaInfo equality', () {
      final media1 = MediaInfo(title: 'Test', artist: 'Artist');
      final media2 = MediaInfo(title: 'Test', artist: 'Artist');
      final media3 = MediaInfo(title: 'Different', artist: 'Artist');

      expect(media1, equals(media2));
      expect(media1, isNot(equals(media3)));
    });
  });

  group('PlayerctlService Tests', () {
    late PlayerctlService service;

    setUp(() {
      service = PlayerctlService();
    });

    tearDown(() {
      service.dispose();
    });

    test('isPlayerctlInstalled returns a boolean', () async {
      final result = await service.isPlayerctlInstalled();
      expect(result, isA<bool>());
    });

    test('getAvailablePlayers returns a list', () async {
      final players = await service.getAvailablePlayers();
      expect(players, isA<List<String>>());
    });

    test('hasActivePlayer returns a boolean', () async {
      final result = await service.hasActivePlayer();
      expect(result, isA<bool>());
    });

    // Note: The following tests require playerctl to be installed
    // and may require active media players

    test('getPlayerctlVersion returns version or null', () async {
      final version = await service.getPlayerctlVersion();
      expect(version, anyOf(isNull, isA<String>()));
    });

    test('getCurrentMetadata returns a map', () async {
      final metadata = await service.getCurrentMetadata();
      expect(metadata, isA<Map<String, String>>());
    });
  });

  group('PlayerctlService Command Tests', () {
    late PlayerctlService service;

    setUp(() {
      service = PlayerctlService();
    });

    tearDown(() {
      service.dispose();
    });

    test('executeCommand returns boolean', () async {
      // This will fail if no player is active, but shouldn't throw
      final result = await service.executeCommand('status');
      expect(result, isA<bool>());
    });

    test('play returns boolean', () async {
      final result = await service.play();
      expect(result, isA<bool>());
    });

    test('pause returns boolean', () async {
      final result = await service.pause();
      expect(result, isA<bool>());
    });

    test('next returns boolean', () async {
      final result = await service.next();
      expect(result, isA<bool>());
    });

    test('previous returns boolean', () async {
      final result = await service.previous();
      expect(result, isA<bool>());
    });

    test('setVolume with valid range returns boolean', () async {
      final result = await service.setVolume(50);
      expect(result, isA<bool>());
    });

    test('setVolume with invalid range throws exception', () async {
      expect(
        () async => await service.setVolume(-10),
        throwsA(isA<InvalidVolumeException>()),
      );
      expect(
        () async => await service.setVolume(150),
        throwsA(isA<InvalidVolumeException>()),
      );
    });

    test('getVolume returns int or null', () async {
      final volume = await service.getVolume();
      expect(volume, anyOf(isNull, isA<int>()));
    });
  });

  group('Exception Tests', () {
    test('PlayerctlNotInstalledException has message', () {
      final exception = PlayerctlNotInstalledException('Test message');
      expect(exception.message, 'Test message');
      expect(exception.toString(), contains('PlayerctlNotInstalledException'));
    });

    test('NoPlayerException has message', () {
      final exception = NoPlayerException('No player found');
      expect(exception.message, 'No player found');
      expect(exception.toString(), contains('NoPlayerException'));
    });
  });

  group('Multi-Player Data Tests', () {
    late MediaPlayerManager manager;

    setUp(() {
      manager = MediaPlayerManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test(
      'fetches and prints all players metadata',
      () async {
        // Initialize the manager
        await manager.initialize();

        // Wait a moment for metadata to be fetched
        await Future.delayed(const Duration(seconds: 2));

        // Get all players' data
        final allPlayersMedia = manager.state.allPlayersMedia;
        final availablePlayers = manager.state.availablePlayers;

        print('\n=== Multi-Player Data Test ===');
        print('Total available players: ${availablePlayers.length}');
        print('Players with metadata: ${allPlayersMedia.length}');
        print('Available players list: $availablePlayers');
        print('');

        // Print detailed info for each player
        if (allPlayersMedia.isEmpty) {
          print(
            '⚠️ No player metadata available (no active players or metadata not yet fetched)',
          );
        } else {
          allPlayersMedia.forEach((playerName, mediaInfo) {
            print('🎵 Player: $playerName');
            print('   Title: ${mediaInfo.title}');
            print('   Artist: ${mediaInfo.artist}');
            print('   Album: ${mediaInfo.album}');
            print('   Status: ${mediaInfo.status}');
            print('   Position: ${mediaInfo.position ?? 'N/A'}');
            print('   Length: ${mediaInfo.length ?? 'N/A'}');
            print('   Art URL: ${mediaInfo.artUrl ?? 'N/A'}');
            print('');
          });
        }

        // Print current selected player info
        print('📍 Currently selected player: ${manager.state.selectedPlayer}');
        print('   Title: ${manager.currentMedia.title}');
        print('   Artist: ${manager.currentMedia.artist}');
        print('   Status: ${manager.currentMedia.status}');
        print('');

        // Verify the map structure
        expect(allPlayersMedia, isA<Map<String, MediaInfo>>());

        // If there are players, verify they're in the map
        for (final player in availablePlayers) {
          // Note: metadata might not be available immediately for all players
          if (allPlayersMedia.containsKey(player)) {
            expect(allPlayersMedia[player], isA<MediaInfo>());
            print('✅ Verified metadata for player: $player');
          }
        }

        print('=== Test Complete ===\n');
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
