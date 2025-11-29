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

    test('setVolume with invalid range returns false', () async {
      final result1 = await service.setVolume(-10);
      final result2 = await service.setVolume(150);
      expect(result1, false);
      expect(result2, false);
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
}
