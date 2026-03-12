import 'package:flutter/material.dart';
import 'pip_grid.dart';

enum TileOrientation { horizontal, vertical }

class DominoTileWidget extends StatelessWidget {
  final int sideA;
  final int sideB;
  final TileOrientation orientation;
  final double halfSize; // size of one pip face (S)
  final bool hidden;
  final bool playable;
  final bool isNew; // animate when placed
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DominoTileWidget({
    super.key,
    required this.sideA,
    required this.sideB,
    required this.orientation,
    required this.halfSize,
    this.hidden = false,
    this.playable = false,
    this.isNew = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isH = orientation == TileOrientation.horizontal;
    final gap = 2.0;
    final w = isH ? halfSize * 2 + gap : halfSize;
    final h = isH ? halfSize : halfSize * 2 + gap;

    final borderColor = playable
        ? const Color(0xFF2ecc71)
        : hidden
            ? const Color(0xFF2a5888)
            : const Color(0xFFb8a870);

    Widget tileContent;

    if (hidden) {
      tileContent = Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1c3d6a), Color(0xFF0c1e38)],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
        ),
      );
    } else {
      final divider = isH
          ? Container(
              width: gap,
              margin: EdgeInsets.symmetric(vertical: halfSize * 0.1),
              color: const Color(0xFF9a8860).withOpacity(0.7),
            )
          : Container(
              height: gap,
              margin: EdgeInsets.symmetric(horizontal: halfSize * 0.1),
              color: const Color(0xFF9a8860).withOpacity(0.7),
            );

      final faceA = PipGrid(value: sideA, size: halfSize);
      final faceB = PipGrid(value: sideB, size: halfSize);

      tileContent = Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFfefcf4), Color(0xFFf0e8d4)],
          ),
          boxShadow: [
            BoxShadow(
              color: playable
                  ? const Color(0xFF2ecc71).withOpacity(0.3)
                  : Colors.black38,
              blurRadius: playable ? 8 : 4,
              offset: const Offset(0, 2),
            ),
            if (playable)
              BoxShadow(
                color: const Color(0xFF2ecc71).withOpacity(0.85),
                blurRadius: 0,
                spreadRadius: 1,
              ),
          ],
        ),
        child: isH
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [faceA, divider, faceB],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [faceA, divider, faceB],
              ),
      );
    }

    if (onTap != null || onLongPress != null) {
      tileContent = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: tileContent,
      );
    }

    if (isNew) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
        child: tileContent,
      );
    }

    return tileContent;
  }
}
