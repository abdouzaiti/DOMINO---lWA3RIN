import 'package:flutter/material.dart';
import '../models/tile.dart';
import 'domino_tile.dart';

/// Ported from computeSnakeLayout in app.js
class _TilePosition {
  final double px, py, tW, tH;
  final TileOrientation orient;
  final bool isCorner;
  final String dir; // 'left' | 'right'
  const _TilePosition({
    required this.px,
    required this.py,
    required this.tW,
    required this.tH,
    required this.orient,
    required this.isCorner,
    required this.dir,
  });
}

List<_TilePosition> computeSnakeLayout(
  List<PlacedTile> board,
  double areaW, {
  double S = 30,
}) {
  if (board.isEmpty) return [];
  const gap = 2.0;
  const pad = 14.0;
  final tH = S * 2 + gap; // long dim
  final tW = S;            // short dim

  final perRow = (((areaW - pad * 2) / (tH + gap)).floor()).clamp(3, 999);

  final positions = <_TilePosition>[];
  double anchor = pad;
  double cy = pad;
  String dir = 'right';
  int col = 0;

  for (int i = 0; i < board.length; i++) {
    final bt = board[i];
    final isDouble = bt.isDouble;
    final isCorner = (col == perRow - 1) && (i < board.length - 1);
    final orient = (isCorner || isDouble)
        ? TileOrientation.vertical
        : TileOrientation.horizontal;
    final tw = orient == TileOrientation.horizontal ? tH : tW;
    final th = orient == TileOrientation.horizontal ? tW : tH;
    final left = dir == 'right' ? anchor : anchor - tw;

    positions.add(_TilePosition(
      px: left, py: cy, tW: tw, tH: th,
      orient: orient, isCorner: isCorner, dir: dir,
    ));

    if (isCorner) {
      final cRight = left + tw;
      cy += tH + gap;
      col = 0;
      dir = dir == 'right' ? 'left' : 'right';
      anchor = cRight;
    } else {
      col++;
      if (dir == 'right') {
        anchor = left + tw + gap;
      } else {
        anchor = left - gap;
      }
    }
  }
  return positions;
}

class BoardWidget extends StatelessWidget {
  final List<PlacedTile> board;
  final bool Function(PlacedTile)? isPlayable;
  final void Function(PlacedTile, String)? onDropZoneTap;
  final String lang;

  const BoardWidget({
    super.key,
    required this.board,
    this.isPlayable,
    this.onDropZoneTap,
    this.lang = 'en',
  });

  @override
  Widget build(BuildContext context) {
    if (board.isEmpty) {
      return Center(
        child: Text(
          'TAP A TILE TO START',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 13,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final areaW = constraints.maxWidth;

        // Auto-scale tile size to fit
        double S = 30;
        List<_TilePosition> positions;
        while (S >= 12) {
          positions = computeSnakeLayout(board, areaW, S: S);
          final maxX = positions.fold(0.0, (m, p) => (p.px + p.tW) > m ? p.px + p.tW : m);
          final maxY = positions.fold(0.0, (m, p) => (p.py + p.tH) > m ? p.py + p.tH : m);
          if (maxX <= areaW && maxY <= constraints.maxHeight) break;
          S -= 2;
        }
        positions = computeSnakeLayout(board, areaW, S: S);

        final maxX = positions.fold(0.0, (m, p) => (p.px + p.tW) > m ? p.px + p.tW : m);
        final maxY = positions.fold(0.0, (m, p) => (p.py + p.tH) > m ? p.py + p.tH : m);
        final chainW = maxX + 14;
        final chainH = maxY + 14;

        final offsetX = ((areaW - chainW) / 2).clamp(0.0, double.infinity);
        final offsetY = ((constraints.maxHeight - chainH) / 2).clamp(0.0, double.infinity);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SizedBox(
              width: chainW.clamp(areaW, double.infinity),
              height: chainH.clamp(constraints.maxHeight, double.infinity),
              child: Stack(
                children: [
                  for (int i = 0; i < positions.length; i++)
                    Positioned(
                      left: positions[i].px + offsetX,
                      top: positions[i].py + offsetY,
                      child: DominoTileWidget(
                        // Flip pip order for left-going tiles
                        sideA: (positions[i].dir == 'left' && !positions[i].isCorner)
                            ? board[i].sideB
                            : board[i].sideA,
                        sideB: (positions[i].dir == 'left' && !positions[i].isCorner)
                            ? board[i].sideA
                            : board[i].sideB,
                        orientation: positions[i].orient,
                        halfSize: S,
                        isNew: i == board.length - 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
