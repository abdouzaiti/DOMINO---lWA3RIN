import 'package:flutter/material.dart';
import 'pip_grid.dart';

enum TileOrientation { horizontal, vertical }

class DominoTileWidget extends StatelessWidget {
  final int sideA;
  final int sideB;
  final TileOrientation orientation;
  final double halfSize;
  final bool hidden;
  final bool playable;
  final bool isNew;
  final String tileSkin;
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
    this.tileSkin = 'classic',
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

    BoxDecoration decoration;
    Color pipColor = Colors.black87;
    Widget? background;

    switch (tileSkin) {
      case 'algerian':
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        );
        pipColor = Colors.black;
        background = Stack(
          children: [
            Row(
              children: [
                Expanded(child: Container(color: const Color(0xFF006633))), // Green
                Expanded(child: Container(color: Colors.white)), // White
              ],
            ),
            Center(
              child: Text('☪️', style: TextStyle(color: const Color(0xFFD21034), fontSize: halfSize * 0.8)),
            ),
          ],
        );
        break;
      case 'gold':
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
          gradient: const LinearGradient(
            colors: [Color(0xFFBF953F), Color(0xFFFCF6BA), Color(0xFFB38728)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
        pipColor = const Color(0xFF432c0d);
        break;
      case 'wood':
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3E2723), width: 2),
          gradient: const LinearGradient(
            colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
        pipColor = Colors.white70;
        break;
      case 'neon':
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00E5FF), width: 2),
          color: Colors.black,
          boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.5), blurRadius: 8)],
        );
        pipColor = const Color(0xFF00E5FF);
        break;
      case 'ivory':
      default:
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFfefcf4), Color(0xFFf0e8d4)],
          ),
          boxShadow: [
            BoxShadow(
              color: playable ? const Color(0xFF2ecc71).withOpacity(0.3) : Colors.black38,
              blurRadius: playable ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
    }

    if (hidden) {
      tileContent = Container(
        width: w,
        height: h,
        decoration: decoration.copyWith(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1c3d6a), Color(0xFF0c1e38)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
          ),
        ),
      );
    } else {
      final divider = isH
          ? Container(width: gap, margin: EdgeInsets.symmetric(vertical: halfSize * 0.1), color: pipColor.withOpacity(0.3))
          : Container(height: gap, margin: EdgeInsets.symmetric(horizontal: halfSize * 0.1), color: pipColor.withOpacity(0.3));

      final faceA = PipGrid(value: sideA, size: halfSize, color: pipColor);
      final faceB = PipGrid(value: sideB, size: halfSize, color: pipColor);

      tileContent = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: w,
          height: h,
          decoration: decoration,
          child: Stack(
            children: [
              if (background != null) background,
              Positioned.fill(
                child: isH
                    ? Row(mainAxisSize: MainAxisSize.min, children: [faceA, divider, faceB])
                    : Column(mainAxisSize: MainAxisSize.min, children: [faceA, divider, faceB]),
              ),
            ],
          ),
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
