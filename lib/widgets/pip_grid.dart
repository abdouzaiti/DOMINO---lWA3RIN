import 'package:flutter/material.dart';

/// The 9 positions of a pip grid (3×3)
const List<List<bool>> _pipLayouts = [
  // 0 — blank
  [false, false, false, false, false, false, false, false, false],
  // 1
  [false, false, false, false, true, false, false, false, false],
  // 2
  [true, false, false, false, false, false, false, false, true],
  // 3
  [true, false, false, false, true, false, false, false, true],
  // 4
  [true, false, true, false, false, false, true, false, true],
  // 5
  [true, false, true, false, true, false, true, false, true],
  // 6
  [true, false, true, true, false, true, true, false, true],
];

class PipGrid extends StatelessWidget {
  final int value;
  final double size;
  final bool hidden;
  final Color? color;

  const PipGrid({
    super.key,
    required this.value,
    required this.size,
    this.hidden = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final layout = _pipLayouts[value.clamp(0, 6)];
    final pipSize = size * 0.22;

    return SizedBox(
      width: size,
      height: size,
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(size * 0.08),
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        children: List.generate(9, (i) {
          return Center(
            child: layout[i]
                ? Container(
                    width: pipSize,
                    height: pipSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color ?? const Color(0xFF1a1a1a),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }),
      ),
    );
  }
}
