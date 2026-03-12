import '../models/tile.dart';
import '../models/player.dart';
import '../models/game_state.dart';

/// Ported directly from app.js place() and applyPlace()
class GameLogic {
  /// Place a tile on the board. Returns new state or null if invalid.
  static GameState? placeTile(GameState state, DominoTile tile, String side) {
    final newBoard = List<PlacedTile>.from(state.board);
    int? newLeft = state.leftEnd;
    int? newRight = state.rightEnd;

    if (state.boardEmpty) {
      // First tile
      newBoard.add(PlacedTile(id: tile.id, sideA: tile.sideA, sideB: tile.sideB));
      newLeft = tile.sideA;
      newRight = tile.sideB;
    } else if (side == 'left') {
      if (tile.sideB == state.leftEnd) {
        newBoard.insert(0, PlacedTile(id: tile.id, sideA: tile.sideB, sideB: tile.sideA));
        newLeft = tile.sideA;
      } else if (tile.sideA == state.leftEnd) {
        newBoard.insert(0, PlacedTile(id: tile.id, sideA: tile.sideA, sideB: tile.sideB));
        newLeft = tile.sideB;
      } else {
        return null; // invalid
      }
    } else {
      // right
      if (tile.sideA == state.rightEnd) {
        newBoard.add(PlacedTile(id: tile.id, sideA: tile.sideA, sideB: tile.sideB));
        newRight = tile.sideB;
      } else if (tile.sideB == state.rightEnd) {
        newBoard.add(PlacedTile(id: tile.id, sideA: tile.sideB, sideB: tile.sideA));
        newRight = tile.sideA;
      } else {
        return null; // invalid
      }
    }

    // Remove tile from player's hand
    final newPlayers = state.players.map((p) {
      if (p.index == state.currentPlayerIndex) {
        return p.copyWith(
          hand: p.hand.where((t) => t.id != tile.id).toList(),
        );
      }
      return p.copyWith();
    }).toList();

    return state.copyWith(
      board: newBoard,
      players: newPlayers,
      leftEnd: newLeft,
      rightEnd: newRight,
    );
  }

  /// Draw one tile from boneyard for current player
  static GameState? drawTile(GameState state) {
    if (state.boneyard.isEmpty) return null;
    final drawn = state.boneyard.first;
    final newBoneyard = state.boneyard.sublist(1);

    final newPlayers = state.players.map((p) {
      if (p.index == state.currentPlayerIndex) {
        return p.copyWith(hand: [...p.hand, drawn]);
      }
      return p.copyWith();
    }).toList();

    return state.copyWith(players: newPlayers, boneyard: newBoneyard);
  }

  /// Advance to next player
  static GameState nextTurn(GameState state) {
    final next = (state.currentPlayerIndex + 1) % state.players.length;
    return state.copyWith(currentPlayerIndex: next);
  }

  /// Check pip exhaustion (all tiles of value X are placed, so ends can't match)
  static int? checkPipExhaustion(GameState state) {
    for (int val = 0; val <= 6; val++) {
      if (val != state.leftEnd && val != state.rightEnd) continue;
      // Count tiles with this value in hands + boneyard
      int inPlay = 0;
      for (final p in state.players) {
        for (final t in p.hand) {
          if (t.sideA == val || t.sideB == val) inPlay++;
        }
      }
      for (final t in state.boneyard) {
        if (t.sideA == val || t.sideB == val) inPlay++;
      }
      if (inPlay == 0) return val; // exhausted
    }
    return null;
  }

  /// Find best starting tile (highest double, or highest total)
  static DominoTile? bestStartTile(List<DominoTile> hand) {
    DominoTile? best;
    for (final t in hand) {
      if (!t.isDouble) continue;
      if (best == null || t.sideA > best.sideA) best = t;
    }
    if (best != null) return best;
    // No double — highest total
    for (final t in hand) {
      if (best == null || t.total > best.total) best = t;
    }
    return best;
  }

  /// Calculate round winner score in draw mode
  static int calcEarned(GameState state, int winnerIdx) {
    if (state.teamMode) {
      final losingTeam = 1 - state.players[winnerIdx].team;
      return state.players
          .where((p) => p.team == losingTeam)
          .fold(0, (sum, p) => sum + p.pipTotal);
    } else {
      return state.players
          .where((p) => p.index != winnerIdx)
          .fold(0, (sum, p) => sum + p.pipTotal);
    }
  }

  /// Block mode winner = player with lowest pip total
  static int blockModeWinner(GameState state) {
    int minPips = 999;
    int winIdx = 0;
    for (final p in state.players) {
      if (p.pipTotal < minPips) {
        minPips = p.pipTotal;
        winIdx = p.index;
      }
    }
    return winIdx;
  }

  /// Apply earned score and return updated state
  static GameState applyRoundScore(GameState state, int winnerIdx, int earned) {
    final newPlayers = state.players.map((p) {
      if (state.teamMode) {
        if (p.team == state.players[winnerIdx].team) {
          return p.copyWith(score: p.score + earned);
        }
      } else {
        if (p.index == winnerIdx) {
          return p.copyWith(score: p.score + earned);
        }
      }
      return p.copyWith();
    }).toList();

    final newTeamScores = List<int>.from(state.teamScores);
    if (state.teamMode) {
      newTeamScores[state.players[winnerIdx].team] += earned;
    }

    return state.copyWith(
      players: newPlayers,
      teamScores: newTeamScores,
    );
  }

  /// Start a new round — deal tiles, set first player
  static GameState startNewRound(GameState state, int firstPlayerIdx) {
    var deck = shuffleDeck(makeDeck());
    final tilesPerPlayer = state.players.length == 4 ? 5 : 7;

    final newPlayers = <Player>[];
    for (final p in state.players) {
      final hand = deck.take(tilesPerPlayer).toList();
      deck = deck.skip(tilesPerPlayer).toList();
      newPlayers.add(p.copyWith(hand: hand));
    }

    return state.copyWith(
      players: newPlayers,
      board: [],
      boneyard: deck,
      currentPlayerIndex: firstPlayerIdx,
      leftEnd: null,
      rightEnd: null,
      phase: GamePhase.playing,
    );
  }
}
