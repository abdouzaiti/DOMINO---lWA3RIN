import 'tile.dart';

enum PlayerType { human, ai, network }

enum AIDifficulty { easy, medium, hard }

class Player {
  final int index;
  final String name;
  final PlayerType type;
  final AIDifficulty difficulty;
  final int team; // 0=Team A, 1=Team B (only used in 2v2)
  List<DominoTile> hand;
  int score;

  Player({
    required this.index,
    required this.name,
    required this.type,
    this.difficulty = AIDifficulty.medium,
    this.team = 0,
    List<DominoTile>? hand,
    this.score = 0,
  }) : hand = hand ?? [];

  bool get isAI => type == PlayerType.ai;
  bool get isNetwork => type == PlayerType.network;
  bool get isHuman => type == PlayerType.human;

  int get pipTotal => hand.fold(0, (sum, t) => sum + t.total);

  Player copyWith({
    String? name,
    PlayerType? type,
    AIDifficulty? difficulty,
    int? team,
    List<DominoTile>? hand,
    int? score,
  }) =>
      Player(
        index: index,
        name: name ?? this.name,
        type: type ?? this.type,
        difficulty: difficulty ?? this.difficulty,
        team: team ?? this.team,
        hand: hand ?? List.from(this.hand),
        score: score ?? this.score,
      );

  static const List<String> emojis = ['🟡', '🟢', '🔴', '🟣'];
  static const List<String> colors = ['#d4a843', '#2ecc71', '#e74c3c', '#9b59b6'];

  String get emoji => emojis[index % emojis.length];
  String get colorHex => colors[index % colors.length];
}
