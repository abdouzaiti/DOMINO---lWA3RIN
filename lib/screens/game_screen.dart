import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';
import '../models/game_state.dart';
import '../models/tile.dart';
import '../i18n/translations.dart';
import '../widgets/board_widget.dart';
import '../widgets/domino_tile.dart';
import '../widgets/dynamic_background.dart';
import 'menu_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (ctx, gp, _) {
        final state = gp.state;
        if (state == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0c1018),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        Widget body;
        if (state.phase == GamePhase.roundOver || state.phase == GamePhase.matchOver) {
          body = _RoundOverOverlay(gp: gp, state: state);
        } else {
          body = _GameBody(gp: gp, state: state);
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0c1018),
          body: SafeArea(child: body),
        );
      },
    );
  }
}

// ── Main game body ───────────────────────────────────────────────────────────

class _GameBody extends StatefulWidget {
  final GameProvider gp;
  final GameState state;
  const _GameBody({required this.gp, required this.state});
  @override
  State<_GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<_GameBody> {
  DominoTile? _selectedTile;

  String _t(String key) => tr(widget.gp.lang, key);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final curPlayer = state.currentPlayer;
    final isMyTurn = !curPlayer.isAI;
    final playable = state.playableTiles(state.currentPlayerIndex);
    final playableIds = {for (final t in playable) t.id};

    return Column(
      children: [
        // ── Top bar ──
        _TopBar(gp: widget.gp, state: state, timerRemaining: widget.gp.timerRemaining),

        // ── Opponent area ──
        if (state.players.length > 2 || state.players.any((p) => p.isAI))
          _OpponentsBar(state: state),

        // ── Status bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          color: Colors.black26,
          child: Row(
            children: [
              Text('🎴 ${state.boneyard.length}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const Spacer(),
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(int.parse(
                      curPlayer.colorHex.replaceFirst('#', 'FF'), radix: 16) | 0xFF000000),
                ),
              ),
              Text(
                isMyTurn ? _t('yourTurn') : curPlayer.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11,
                    letterSpacing: 1),
              ),
              const Spacer(),
              Text(
                state.teamMode
                    ? '${state.teamScores[0]}–${state.teamScores[1]}'
                    : state.players.map((p) => p.score).join('–'),
                style: const TextStyle(
                    color: Color(0xFFd4a843), fontWeight: FontWeight.w900,
                    fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),

        // ── Board ──
        Expanded(
          child: Stack(
            children: [
              DynamicBackground(baseColor: _boardColor(state.boardColor)),
              BoardWidget(board: state.board, lang: widget.gp.lang, tileSkin: widget.gp.tileSkin),
            ],
          ),
        ),

        // ── Player hand ──
        if (isMyTurn) ...[
          const SizedBox(height: 4),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: curPlayer.hand.length,
              separatorBuilder: (_, __) => const SizedBox(width: 5),
              itemBuilder: (ctx, i) {
                final tile = curPlayer.hand[i];
                final canPlay = playableIds.contains(tile.id);
                return GestureDetector(
                  onTap: canPlay ? () => _onTileTap(tile, state, context) : null,
                  child: DominoTileWidget(
                    sideA: tile.sideA,
                    sideB: tile.sideB,
                    orientation: TileOrientation.vertical,
                    halfSize: 36,
                    playable: canPlay,
                    tileSkin: widget.gp.tileSkin,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // ── Action buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.rule == GameRule.draw &&
                  state.boneyard.isNotEmpty &&
                  playable.isEmpty)
                _actionBtn(_t('draw'), '🎴', () => widget.gp.playerDraw()),
              const SizedBox(width: 12),
              _actionBtn(_t('pass'), '↩', () => widget.gp.playerPass()),
            ],
          ),
          const SizedBox(height: 8),
        ] else ...[
          // Waiting for AI / other player
          Container(
            height: 60,
            alignment: Alignment.center,
            child: Text(
              '${curPlayer.name}…',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  void _onTileTap(DominoTile tile, GameState state, BuildContext context) {
    if (state.boardEmpty) {
      widget.gp.playerPlace(tile, 'right');
      return;
    }
    final sides = tile.getPlayableSides(state.leftEnd, state.rightEnd);
    if (sides.length == 1) {
      widget.gp.playerPlace(tile, sides.first);
    } else {
      // Both sides work — let player choose
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0a1018),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _sideBtn('◀ Left', () {
                Navigator.pop(context);
                widget.gp.playerPlace(tile, 'left');
              }),
              _sideBtn('Right ▶', () {
                Navigator.pop(context);
                widget.gp.playerPlace(tile, 'right');
              }),
            ],
          ),
        ),
      );
    }
  }

  Widget _actionBtn(String label, String icon, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1a2a40),
        foregroundColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text('$icon $label', style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _sideBtn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFd4a843),
        foregroundColor: const Color(0xFF0c1018),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }

  Color _boardColor(String key) {
    switch (key) {
      case 'navy': return const Color(0xFF1a2a52);
      case 'maroon': return const Color(0xFF521820);
      case 'slate': return const Color(0xFF283040);
      case 'purple': return const Color(0xFF2d1b4e);
      default: return const Color(0xFF1d5c38); // green
    }
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GameProvider gp;
  final GameState state;
  final int timerRemaining;
  const _TopBar({required this.gp, required this.state, required this.timerRemaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: const Color(0xFF0a1018),
      child: Row(
        children: [
          const Text('LWA3RIN',
              style: TextStyle(
                  fontFamily: 'Impact',
                  color: Color(0xFFd4a843),
                  fontSize: 18,
                  letterSpacing: 3)),
          const Spacer(),
          if (state.timerEnabled)
            _TimerBadge(remaining: timerRemaining, total: state.timerDuration),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.pause, color: Colors.white54),
            onPressed: () => _showPause(context),
          ),
        ],
      ),
    );
  }

  void _showPause(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0a1018),
        title: const Text('PAUSED',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Resume', style: TextStyle(color: Color(0xFFd4a843))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const MenuScreen()));
            },
            child: const Text('Main Menu', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int remaining;
  final int total;
  const _TimerBadge({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = remaining / total;
    final warn = remaining <= 5;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 32, height: 32,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: const Color(0xFF1e2e44),
            color: warn ? Colors.red : const Color(0xFFd4a843),
          ),
        ),
        Text('$remaining',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: warn ? Colors.red : const Color(0xFFd4a843))),
      ],
    );
  }
}

// ── Opponents bar ────────────────────────────────────────────────────────────

class _OpponentsBar extends StatelessWidget {
  final GameState state;
  const _OpponentsBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final opponents = state.players.where((p) => p.index != 0).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF0a1018),
      child: Row(
        children: opponents.map((p) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                    Text('${p.hand.length} tiles',
                        style: const TextStyle(color: Colors.white38, fontSize: 9)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Round / Match over overlay ───────────────────────────────────────────────

class _RoundOverOverlay extends StatelessWidget {
  final GameProvider gp;
  final GameState state;
  const _RoundOverOverlay({required this.gp, required this.state});

  @override
  Widget build(BuildContext context) {
    final isMatch = state.phase == GamePhase.matchOver;
    final winIdx = state.pendingWinIndex ?? 0;
    final winner = state.players[winIdx];
    final lang = gp.lang;

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isMatch ? tr(lang, 'matchWinner') : tr(lang, 'roundOver'),
            style: const TextStyle(
                color: Color(0xFFd4a843),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          Text(
            '${winner.emoji} ${winner.name}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          // Scores
          ...state.players.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${p.emoji} ${p.name}  ${p.score} pts',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              )),
          const SizedBox(height: 32),
          if (!isMatch)
            ElevatedButton(
              onPressed: () => gp.startNextRound(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFd4a843),
                foregroundColor: const Color(0xFF0c1018),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text(tr(lang, 'newRound'),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const MenuScreen())),
            child: Text(tr(lang, 'backMenu'),
                style: const TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
