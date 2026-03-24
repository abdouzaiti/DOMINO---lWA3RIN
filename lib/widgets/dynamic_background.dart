import 'dart:math';
import 'package:flutter/material.dart';

class DynamicBackground extends StatefulWidget {
  final Color baseColor;
  const DynamicBackground({super.key, this.baseColor = const Color(0xFF1d5c38)});

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PremiumPainter(
            baseColor: widget.baseColor,
            progress: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _PremiumPainter extends CustomPainter {
  final Color baseColor;
  final double progress;

  _PremiumPainter({required this.baseColor, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // 1. Base Gradient
    final baseGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        baseColor.withOpacity(0.8),
        baseColor.withOpacity(1.0),
        baseColor.darken(0.3),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = baseGradient.createShader(rect));

    // 2. Subtle Animated Smoke/Mist
    final smokePaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    
    for (int i = 0; i < 3; i++) {
        final double t = (progress + (i * 0.33)) % 1.0;
        final double opacity = sin(t * pi); // Fade in and out
        
        final double x = size.width * (0.5 + 0.3 * cos(t * 2 * pi + i));
        final double y = size.height * (0.5 + 0.3 * sin(t * 2 * pi + i));
        
        canvas.drawCircle(
          Offset(x, y),
          150 + 50 * sin(t * pi),
          smokePaint..color = Colors.white.withOpacity(opacity * 0.03),
        );
    }

    // 3. Light Reflections (Glints)
    final reflectionPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..style = PaintingStyle.fill;

    final double rx = size.width * progress;
    final double ry = size.height * (0.2 + 0.1 * sin(progress * 2 * pi));
    
    final path = Path()
      ..moveTo(rx - 100, ry)
      ..quadraticBezierTo(rx, ry - 20, rx + 100, ry)
      ..quadraticBezierTo(rx, ry + 20, rx - 100, ry);
      
    canvas.drawPath(
      path,
      reflectionPaint..color = Colors.white.withOpacity(0.05),
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumPainter oldDelegate) => true;
}

extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
