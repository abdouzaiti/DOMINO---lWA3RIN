import 'dart:math';
import '../models/tile.dart';
import '../models/player.dart';
import '../models/game_state.dart';

class AIMove {
  final DominoTile tile;
  final String side;
  const AIMove(this.tile, this.side);
}

/// AI difficulty levels ported from app.js
class AILogic {
  static final _rng = Random();

  /// Returns the best move for the AI, or null if no move possible
  static AIMove? getBestMove(GameState state) {
    final p = state.currentPlayer;
    assert(p.isAI);

    final playable = state.playableTiles(state.currentPlayerIndex);
    if (playable.isEmpty) return null;

    switch (p.difficulty) {
      case AIDifficulty.easy:
        return _easyMove(playable, state);
      case AIDifficulty.medium:
        return _mediumMove(playable, state);
      case AIDifficulty.hard:
        return _hardMove(playable, state);
    }
  }

  // Easy: random valid move
  static AIMove _easyMove(List<DominoTile> playable, GameState state) {
    final tile = playable[_rng.nextInt(playable.length)];
    final sides = tile.getPlayableSides(state.leftEnd, state.rightEnd);
    return AIMove(tile, sides.first);
  }

  // Medium: prefer doubles, then highest pip
  static AIMove _mediumMove(List<DominoTile> playable, GameState state) {
    // Try to play a double first
    final doubles = playable.where((t) => t.isDouble).toList();
    if (doubles.isNotEmpty) {
      doubles.sort((a, b) => b.sideA.compareTo(a.sideA));
      final tile = doubles.first;
      final sides = tile.getPlayableSides(state.leftEnd, state.rightEnd);
      return AIMove(tile, sides.first);
    }
    // Otherwise highest total
    playable.sort((a, b) => b.total.compareTo(a.total));
    final tile = playable.first;
    final sides = tile.getPlayableSides(state.leftEnd, state.rightEnd);
    return AIMove(tile, sides.first);
  }

  // Hard: greedy — maximise pips placed, prefer blocking opponent ends
  static AIMove _hardMove(List<DominoTile> playable, GameState state) {
    AIMove? bestMove;
    int bestScore = -1;

    for (final tile in playable) {
      final sides = tile.getPlayableSides(state.leftEnd, state.rightEnd);
      for (final side in sides) {
        int score = tile.total;

        // Bonus: if this exposes an end that opponents can't match
        final newEnd = side == 'right'
            ? (tile.sideA == state.rightEnd ? tile.sideB : tile.sideA)
            : (tile.sideB == state.leftEnd ? tile.sideA : tile.sideB);

        bool opponentBlocked = true;
        for (final p in state.players) {
          if (p.index == state.currentPlayerIndex) continue;
          if (p.hand.any((t) => t.sideA == newEnd || t.sideB == newEnd)) {
            opponentBlocked = false;
            break;
          }
        }
        if (opponentBlocked) score += 10;

        if (score > bestScore) {
          bestScore = score;
          bestMove = AIMove(tile, side);
        }
      }
    }

    return bestMove ?? _easyMove(playable, state);
  }
}
