import 'tile.dart';
import 'player.dart';

enum GameRule { draw, block }
enum GamePhase { menu, playing, roundOver, matchOver, handoff }

class GameState {
  final List<Player> players;
  final List<PlacedTile> board;
  final List<DominoTile> boneyard;
  final int currentPlayerIndex;
  final int? leftEnd;   // open left end value (null = empty board)
  final int? rightEnd;  // open right end value
  final GameRule rule;
  final GamePhase phase;
  final bool teamMode;
  final List<int> teamScores; // [teamA, teamB]
  final int? lastRoundWinnerIndex;
  final int? pendingWinIndex;
  final String boardColor;
  final bool timerEnabled;
  final int timerDuration; // seconds
  final bool isTurbo;
  final int matchWinScore;

  const GameState({
    required this.players,
    required this.board,
    required this.boneyard,
    required this.currentPlayerIndex,
    this.leftEnd,
    this.rightEnd,
    required this.rule,
    required this.phase,
    this.teamMode = false,
    required this.teamScores,
    this.lastRoundWinnerIndex,
    this.pendingWinIndex,
    this.boardColor = 'green',
    this.timerEnabled = false,
    this.timerDuration = 30,
    this.isTurbo = false,
    this.matchWinScore = 100,
  });

  Player get currentPlayer => players[currentPlayerIndex];

  bool get boardEmpty => board.isEmpty;

  List<DominoTile> playableTiles(int playerIdx) {
    final p = players[playerIdx];
    if (boardEmpty) return List.from(p.hand);
    return p.hand
        .where((t) => t.canPlay(leftEnd, rightEnd))
        .toList();
  }

  bool get isBlocked {
    for (final p in players) {
      if (p.hand.any((t) => t.canPlay(leftEnd, rightEnd))) return false;
    }
    return true;
  }

  GameState copyWith({
    List<Player>? players,
    List<PlacedTile>? board,
    List<DominoTile>? boneyard,
    int? currentPlayerIndex,
    Object? leftEnd = _sentinel,
    Object? rightEnd = _sentinel,
    GameRule? rule,
    GamePhase? phase,
    bool? teamMode,
    List<int>? teamScores,
    Object? lastRoundWinnerIndex = _sentinel,
    Object? pendingWinIndex = _sentinel,
    String? boardColor,
    bool? timerEnabled,
    int? timerDuration,
    bool? isTurbo,
    int? matchWinScore,
  }) =>
      GameState(
        players: players ?? this.players.map((p) => p.copyWith()).toList(),
        board: board ?? List.from(this.board),
        boneyard: boneyard ?? List.from(this.boneyard),
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
        leftEnd: identical(leftEnd, _sentinel) ? this.leftEnd : leftEnd as int?,
        rightEnd: identical(rightEnd, _sentinel) ? this.rightEnd : rightEnd as int?,
        rule: rule ?? this.rule,
        phase: phase ?? this.phase,
        teamMode: teamMode ?? this.teamMode,
        teamScores: teamScores ?? List.from(this.teamScores),
        lastRoundWinnerIndex: identical(lastRoundWinnerIndex, _sentinel)
            ? this.lastRoundWinnerIndex
            : lastRoundWinnerIndex as int?,
        pendingWinIndex: identical(pendingWinIndex, _sentinel)
            ? this.pendingWinIndex
            : pendingWinIndex as int?,
        boardColor: boardColor ?? this.boardColor,
        timerEnabled: timerEnabled ?? this.timerEnabled,
        timerDuration: timerDuration ?? this.timerDuration,
        isTurbo: isTurbo ?? this.isTurbo,
        matchWinScore: matchWinScore ?? this.matchWinScore,
      );
}

const _sentinel = Object();
