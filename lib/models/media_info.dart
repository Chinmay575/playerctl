import 'package:equatable/equatable.dart';

/// Represents the current media playback information
class MediaInfo extends Equatable {
  final String title;
  final String artist;
  final String album;
  final String status; // Playing, Paused, Stopped
  final String playerName; // spotify, vlc, etc.
  final int? position; // Position in microseconds
  final int? length; // Length in microseconds
  final String? artUrl; // Album art/cover URL

  const MediaInfo({
    this.title = 'Unknown',
    this.artist = 'Unknown',
    this.album = 'Unknown',
    this.status = 'Stopped',
    this.playerName = 'Unknown',
    this.position,
    this.length,
    this.artUrl,
  });

  /// Creates an empty MediaInfo (no active player)
  factory MediaInfo.empty() {
    return const MediaInfo();
  }

  @override
  List<Object?> get props => [
    title,
    artist,
    album,
    status,
    playerName,
    position,
    length,
    artUrl,
  ];

  /// Copy with method for updating specific fields
  MediaInfo copyWith({
    String? title,
    String? artist,
    String? album,
    String? status,
    String? playerName,
    int? position,
    int? length,
    String? artUrl,
  }) {
    return MediaInfo(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      status: status ?? this.status,
      playerName: playerName ?? this.playerName,
      position: position ?? this.position,
      length: length ?? this.length,
      artUrl: artUrl ?? this.artUrl,
    );
  }

  /// Create MediaInfo from JSON
  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown',
      album: json['album'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'Stopped',
      playerName: json['playerName'] as String? ?? 'Unknown',
      position: json['position'] as int?,
      length: json['length'] as int?,
      artUrl: json['artUrl'] as String?,
    );
  }

  /// Convert MediaInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'status': status,
      'playerName': playerName,
      'position': position,
      'length': length,
      'artUrl': artUrl,
    };
  }

  @override
  String toString() {
    return 'MediaInfo(title: $title, artist: $artist, status: $status, player: $playerName)';
  }
}
