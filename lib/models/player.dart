import 'tile.dart';

enum PlayerType { human, ai, network }

enum AIDifficulty { easy, medium, hard, expert }

class Player {
  final int index;
  final String name;
  final String? username;
  final String? avatarUrl;
  final PlayerType type;
  final AIDifficulty difficulty;
  final int team; // 0=Team A, 1=Team B (only used in 2v2)
  List<DominoTile> hand;
  int score;
  
  // Stats
  final int wins;
  final int losses;
  final int maxScore;

  Player({
    required this.index,
    required this.name,
    this.username,
    this.avatarUrl,
    required this.type,
    this.difficulty = AIDifficulty.medium,
    this.team = 0,
    List<DominoTile>? hand,
    this.score = 0,
    this.wins = 0,
    this.losses = 0,
    this.maxScore = 0,
  }) : hand = hand ?? [];

  bool get isAI => type == PlayerType.ai;
  bool get isNetwork => type == PlayerType.network;
  bool get isHuman => type == PlayerType.human;

  int get pipTotal => hand.fold(0, (sum, t) => sum + t.total);

  Player copyWith({
    int? index,
    String? name,
    String? username,
    String? avatarUrl,
    PlayerType? type,
    AIDifficulty? difficulty,
    int? team,
    List<DominoTile>? hand,
    int? score,
    int? wins,
    int? losses,
    int? maxScore,
  }) =>
      Player(
        index: index ?? this.index,
        name: name ?? this.name,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        type: type ?? this.type,
        difficulty: difficulty ?? this.difficulty,
        team: team ?? this.team,
        hand: hand ?? List.from(this.hand),
        score: score ?? this.score,
        wins: wins ?? this.wins,
        losses: losses ?? this.losses,
        maxScore: maxScore ?? this.maxScore,
      );

  static const List<String> emojis = ['🟡', '🟢', '🔴', '🟣'];
  static const List<String> colors = ['#d4a843', '#2ecc71', '#e74c3c', '#9b59b6'];

  String get emoji => emojis[index % emojis.length];
  String get colorHex => colors[index % colors.length];
}
