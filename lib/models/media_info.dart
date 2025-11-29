/// Represents the current media playback information
class MediaInfo {
  final String title;
  final String artist;
  final String album;
  final String status; // Playing, Paused, Stopped
  final String playerName; // spotify, vlc, etc.
  final int? position; // Position in microseconds
  final int? length; // Length in microseconds

  MediaInfo({
    this.title = 'Unknown',
    this.artist = 'Unknown',
    this.album = 'Unknown',
    this.status = 'Stopped',
    this.playerName = 'Unknown',
    this.position,
    this.length,
  });

  /// Creates an empty MediaInfo (no active player)
  factory MediaInfo.empty() {
    return MediaInfo();
  }

  /// Copy with method for updating specific fields
  MediaInfo copyWith({
    String? title,
    String? artist,
    String? album,
    String? status,
    String? playerName,
    int? position,
    int? length,
  }) {
    return MediaInfo(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      status: status ?? this.status,
      playerName: playerName ?? this.playerName,
      position: position ?? this.position,
      length: length ?? this.length,
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
    };
  }

  @override
  String toString() {
    return 'MediaInfo(title: $title, artist: $artist, status: $status, player: $playerName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MediaInfo &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.status == status &&
        other.playerName == playerName &&
        other.position == position &&
        other.length == length;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        artist.hashCode ^
        album.hashCode ^
        status.hashCode ^
        playerName.hashCode ^
        (position?.hashCode ?? 0) ^
        (length?.hashCode ?? 0);
  }
}
