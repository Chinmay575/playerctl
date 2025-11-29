import '../models/media_info.dart';

/// Immutable state class representing the complete player state
/// Can be used with any state management solution or none at all
class PlayerState {
  final MediaInfo currentMedia;
  final bool isPlayerctlInstalled;
  final bool hasActivePlayer;
  final List<String> availablePlayers;
  final String selectedPlayer;
  final bool isLoading;
  final String errorMessage;
  final int volume;
  final String shuffleStatus; // 'On', 'Off', or 'Unknown'
  final String loopStatus; // 'None', 'Track', 'Playlist', or 'Unknown'

  const PlayerState({
    required this.currentMedia,
    required this.isPlayerctlInstalled,
    required this.hasActivePlayer,
    required this.availablePlayers,
    required this.selectedPlayer,
    required this.isLoading,
    required this.errorMessage,
    required this.volume,
    required this.shuffleStatus,
    required this.loopStatus,
  });

  /// Initial state
  factory PlayerState.initial() {
    return PlayerState(
      currentMedia: MediaInfo.empty(),
      isPlayerctlInstalled: false,
      hasActivePlayer: false,
      availablePlayers: const [],
      selectedPlayer: '',
      isLoading: true,
      errorMessage: '',
      volume: 50,
      shuffleStatus: 'Unknown',
      loopStatus: 'Unknown',
    );
  }

  /// Create PlayerState from JSON
  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      currentMedia: MediaInfo.fromJson(
        json['currentMedia'] as Map<String, dynamic>? ?? {},
      ),
      isPlayerctlInstalled: json['isPlayerctlInstalled'] as bool? ?? false,
      hasActivePlayer: json['hasActivePlayer'] as bool? ?? false,
      availablePlayers:
          (json['availablePlayers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      selectedPlayer: json['selectedPlayer'] as String? ?? '',
      isLoading: json['isLoading'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String? ?? '',
      volume: json['volume'] as int? ?? 50,
      shuffleStatus: json['shuffleStatus'] as String? ?? 'Unknown',
      loopStatus: json['loopStatus'] as String? ?? 'Unknown',
    );
  }

  /// Convert PlayerState to JSON
  Map<String, dynamic> toJson() {
    return {
      'currentMedia': currentMedia.toJson(),
      'isPlayerctlInstalled': isPlayerctlInstalled,
      'hasActivePlayer': hasActivePlayer,
      'availablePlayers': availablePlayers,
      'selectedPlayer': selectedPlayer,
      'isLoading': isLoading,
      'errorMessage': errorMessage,
      'volume': volume,
      'shuffleStatus': shuffleStatus,
      'loopStatus': loopStatus,
    };
  }

  /// Copy with method for creating updated states
  PlayerState copyWith({
    MediaInfo? currentMedia,
    bool? isPlayerctlInstalled,
    bool? hasActivePlayer,
    List<String>? availablePlayers,
    String? selectedPlayer,
    bool? isLoading,
    String? errorMessage,
    int? volume,
    String? shuffleStatus,
    String? loopStatus,
  }) {
    return PlayerState(
      currentMedia: currentMedia ?? this.currentMedia,
      isPlayerctlInstalled: isPlayerctlInstalled ?? this.isPlayerctlInstalled,
      hasActivePlayer: hasActivePlayer ?? this.hasActivePlayer,
      availablePlayers: availablePlayers ?? this.availablePlayers,
      selectedPlayer: selectedPlayer ?? this.selectedPlayer,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      volume: volume ?? this.volume,
      shuffleStatus: shuffleStatus ?? this.shuffleStatus,
      loopStatus: loopStatus ?? this.loopStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayerState &&
        other.currentMedia == currentMedia &&
        other.isPlayerctlInstalled == isPlayerctlInstalled &&
        other.hasActivePlayer == hasActivePlayer &&
        other.availablePlayers.length == availablePlayers.length &&
        other.selectedPlayer == selectedPlayer &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.volume == volume &&
        other.shuffleStatus == shuffleStatus &&
        other.loopStatus == loopStatus;
  }

  @override
  int get hashCode {
    return currentMedia.hashCode ^
        isPlayerctlInstalled.hashCode ^
        hasActivePlayer.hashCode ^
        availablePlayers.hashCode ^
        selectedPlayer.hashCode ^
        isLoading.hashCode ^
        errorMessage.hashCode ^
        volume.hashCode ^
        shuffleStatus.hashCode ^
        loopStatus.hashCode;
  }

  @override
  String toString() {
    return 'PlayerState(media: $currentMedia, installed: $isPlayerctlInstalled, '
        'hasPlayer: $hasActivePlayer, players: $availablePlayers, '
        'selected: $selectedPlayer, loading: $isLoading, volume: $volume, '
        'shuffle: $shuffleStatus, loop: $loopStatus)';
  }
}
