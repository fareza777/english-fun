import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Painted, animated scenery for [AnimatedBackground].
///
/// Each world is drawn entirely with canvas primitives, so the app ships no
/// background images and every scene scales cleanly to any screen size.
///
/// Worlds: 0 sky, 1 forest, 2 ocean, 3 city, 4 candy, 5 space, 6 magic castle.

class WorldPainter extends CustomPainter {
  final int world;
  final Animation<double> t;
  WorldPainter(this.world, this.t) : super(repaint: t);

  void _cloud(Canvas canvas, Size size, double x, double y, double s, double opacity) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 120 * s, height: 44 * s), Radius.circular(22 * s));
    canvas.drawRRect(rect, paint);
    canvas.drawCircle(Offset(x - 28 * s, y - 14 * s), 22 * s, paint);
    canvas.drawCircle(Offset(x + 12 * s, y - 20 * s), 26 * s, paint);
  }

  void _clouds(Canvas canvas, Size size, double time, {double opacity = 0.5}) {
    for (var i = 0; i < 4; i++) {
      final speed = 0.05 + i * 0.017;
      final x = (((time * speed) + i * 0.31) % 1.3 - 0.15) * size.width;
      final y = size.height * (0.08 + i * 0.09);
      _cloud(canvas, size, x, y, 0.7 + (i % 3) * 0.35, opacity);
    }
  }

  void _stars(Canvas canvas, Size size, double time, {int count = 14, double maxY = 0.5}) {
    final rnd = math.Random(42);
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * maxY;
      final tw = (math.sin(time * 2 * math.pi * (1 + rnd.nextDouble()) + i) + 1) / 2;
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.25 + 0.55 * tw);
      canvas.drawCircle(Offset(x, y), 1.6 + rnd.nextDouble() * 2.2, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final time = t.value;
    switch (world) {
      case 1:
        _forest(canvas, size, time);
      case 2:
        _ocean(canvas, size, time);
      case 3:
        _city(canvas, size, time);
      case 4:
        _candy(canvas, size, time);
      case 5:
        _space(canvas, size, time);
      case 6:
        _magic(canvas, size, time);
      default:
        _clouds(canvas, size, time);
        _stars(canvas, size, time);
    }
  }

  void _forest(Canvas canvas, Size size, double time) {
    _clouds(canvas, size, time, opacity: 0.45);
    final w = size.width, h = size.height;
    // rolling hills
    final hill1 = Paint()..color = const Color(0xFF57B25E);
    final hill2 = Paint()..color = const Color(0xFF3E9B4F);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.15, h * 1.08), width: w * 1.1, height: h * 0.32), hill1);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.85, h * 1.12), width: w * 1.2, height: h * 0.36), hill2);
    // pine trees
    void pine(double x, double y, double s) {
      final trunk = Paint()..color = const Color(0xFF8D5A2B);
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 26 * s), width: 8 * s, height: 18 * s), trunk);
      final leaf = Paint()..color = const Color(0xFF2E7D32);
      for (var i = 0; i < 3; i++) {
        final ty = y - i * 14 * s;
        final p = Path()
          ..moveTo(x - (22 - i * 5) * s, ty)
          ..lineTo(x, ty - 22 * s)
          ..lineTo(x + (22 - i * 5) * s, ty)
          ..close();
        canvas.drawPath(p, leaf);
      }
    }

    pine(w * 0.12, h * 0.86, 1.1);
    pine(w * 0.85, h * 0.9, 0.9);
    pine(w * 0.68, h * 0.84, 0.7);
    // drifting pollen / fireflies
    final rnd = math.Random(7);
    for (var i = 0; i < 10; i++) {
      final bx = (rnd.nextDouble() + time * (0.02 + rnd.nextDouble() * 0.03)) % 1.0;
      final by = 0.35 + rnd.nextDouble() * 0.5 + math.sin(time * 2 * math.pi + i) * 0.02;
      canvas.drawCircle(Offset(bx * w, by * h), 2.2,
          Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.8));
    }
  }

  void _ocean(Canvas canvas, Size size, double time) {
    final w = size.width, h = size.height;
    // rising bubbles
    final rnd = math.Random(11);
    for (var i = 0; i < 12; i++) {
      final speed = 0.05 + rnd.nextDouble() * 0.06;
      final by = 1.05 - ((time * speed + rnd.nextDouble()) % 1.1);
      final bx = rnd.nextDouble() + math.sin(time * 4 * math.pi + i) * 0.015;
      canvas.drawCircle(
          Offset(bx * w, by * h),
          2.5 + rnd.nextDouble() * 4,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
    // little fish
    void fish(double x, double y, double s, Color color, bool flip) {
      final p = Paint()..color = color.withValues(alpha: 0.85);
      final dir = flip ? -1.0 : 1.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(dir * s, s);
      canvas.drawOval(const Rect.fromLTWH(-12, -6, 24, 12), p);
      final tail = Path()
        ..moveTo(12, 0)
        ..lineTo(20, -7)
        ..lineTo(20, 7)
        ..close();
      canvas.drawPath(tail, p);
      canvas.drawCircle(const Offset(-6, -1.5), 1.6, Paint()..color = Colors.white);
      canvas.restore();
    }

    final fx1 = ((time * 0.045) % 1.3 - 0.15) * w;
    final fx2 = (1.15 - (time * 0.035) % 1.3) * w;
    fish(fx1, h * 0.62, 1.0, const Color(0xFFFF9F1C), false);
    fish(fx2, h * 0.74, 0.8, const Color(0xFFFF6B6B), true);
    // waves at the bottom
    for (var layer = 0; layer < 2; layer++) {
      final wave = Path()..moveTo(0, h);
      final baseY = h * (0.94 + layer * 0.03);
      for (double x = 0; x <= w; x += 8) {
        final y = baseY + math.sin((x / w) * 4 * math.pi + time * 2 * math.pi * (layer + 1)) * 6;
        wave.lineTo(x, y);
      }
      wave.lineTo(w, h);
      wave.close();
      canvas.drawPath(wave, Paint()..color = Colors.white.withValues(alpha: 0.35 - layer * 0.12));
    }
  }

  void _city(Canvas canvas, Size size, double time) {
    _clouds(canvas, size, time, opacity: 0.55);
    final w = size.width, h = size.height;
    final rnd = math.Random(5);
    // building silhouettes
    double x = -10;
    while (x < w + 20) {
      final bw = 40 + rnd.nextDouble() * 46;
      final bh = h * (0.10 + rnd.nextDouble() * 0.14);
      final paint = Paint()..color = Color.lerp(const Color(0xFF9CC3FF), const Color(0xFF6A8EDB), rnd.nextDouble())!;
      canvas.drawRect(Rect.fromLTWH(x, h - bh, bw, bh), paint);
      // windows
      final win = Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: 0.9);
      for (var wy = h - bh + 8; wy < h - 10; wy += 14) {
        for (var wx = x + 6; wx < x + bw - 8; wx += 13) {
          if (rnd.nextDouble() > 0.45) canvas.drawRect(Rect.fromLTWH(wx, wy, 6, 8), win);
        }
      }
      x += bw + 6;
    }
    // birds
    final bird = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var b = 0; b < 3; b++) {
      final bx = (((time * (0.06 + b * 0.02)) + b * 0.4) % 1.3 - 0.15) * w;
      final by = h * (0.18 + b * 0.07) + math.sin(time * 6 * math.pi + b) * 3;
      canvas.drawArc(Rect.fromCenter(center: Offset(bx - 5, by), width: 10, height: 8), math.pi, math.pi, false, bird);
      canvas.drawArc(Rect.fromCenter(center: Offset(bx + 5, by), width: 10, height: 8), math.pi, math.pi, false, bird);
    }
  }

  void _candy(Canvas canvas, Size size, double time) {
    _clouds(canvas, size, time, opacity: 0.6);
    final w = size.width, h = size.height;
    // lollipops
    void lollipop(double x, double y, double r, Color c) {
      canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y + r * 2.2), width: 4, height: r * 3),
          Paint()..color = Colors.white.withValues(alpha: 0.9));
      canvas.drawCircle(Offset(x, y), r, Paint()..color = c);
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.28
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      canvas.drawCircle(Offset(x, y), r * 0.35, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    lollipop(w * 0.12, h * 0.8, 16, const Color(0xFFFF5D8F));
    lollipop(w * 0.85, h * 0.72, 20, const Color(0xFF7B61FF));
    lollipop(w * 0.7, h * 0.88, 13, const Color(0xFF2EC4B6));
    // falling sprinkles
    final rnd = math.Random(3);
    const palette = [Color(0xFFFF6B6B), Color(0xFFFFD60A), Color(0xFF43AA8B), Color(0xFF4CC9F0), Color(0xFFC77DFF)];
    for (var i = 0; i < 16; i++) {
      final speed = 0.03 + rnd.nextDouble() * 0.05;
      final sy = ((time * speed + rnd.nextDouble()) % 1.1) * h;
      final sx = rnd.nextDouble() * w;
      canvas.save();
      canvas.translate(sx, sy);
      canvas.rotate(rnd.nextDouble() * math.pi);
      canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -1.5, 8, 3), const Radius.circular(1.5)),
          Paint()..color = palette[i % palette.length].withValues(alpha: 0.85));
      canvas.restore();
    }
  }

  void _space(Canvas canvas, Size size, double time) {
    final w = size.width, h = size.height;
    _stars(canvas, size, time, count: 40, maxY: 1.0);
    // ringed planet
    final planet = Paint()..color = const Color(0xFFC77DFF);
    canvas.drawCircle(Offset(w * 0.82, h * 0.16), 22, planet);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.82, h * 0.16), width: 64, height: 16),
        Paint()
          ..color = const Color(0xFFFFD60A).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // small crater planet
    canvas.drawCircle(Offset(w * 0.15, h * 0.3), 13, Paint()..color = const Color(0xFF4CC9F0));
    canvas.drawCircle(Offset(w * 0.13, h * 0.29), 3, Paint()..color = const Color(0xFF2E8BC0));
    canvas.drawCircle(Offset(w * 0.18, h * 0.32), 2, Paint()..color = const Color(0xFF2E8BC0));
    // cruising rocket
    final rx = (((time * 0.05) + 0.2) % 1.4 - 0.2) * w;
    final ry = h * 0.5 + math.sin(time * 2 * math.pi) * 10;
    canvas.save();
    canvas.translate(rx, ry);
    canvas.rotate(0.5);
    canvas.drawOval(const Rect.fromLTWH(-8, -16, 16, 32), Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(0, -4), 4, Paint()..color = const Color(0xFF4361EE));
    final flame = Path()
      ..moveTo(-5, 16)
      ..lineTo(0, 26 + math.sin(time * 20 * math.pi) * 4)
      ..lineTo(5, 16)
      ..close();
    canvas.drawPath(flame, Paint()..color = const Color(0xFFFF9F1C));
    canvas.restore();
  }

  void _magic(Canvas canvas, Size size, double time) {
    final w = size.width, h = size.height;
    _stars(canvas, size, time, count: 20, maxY: 0.7);
    // castle silhouette
    final castle = Paint()..color = const Color(0xFF3C096C);
    final baseY = h;
    canvas.drawRect(Rect.fromLTWH(w * 0.3, baseY - h * 0.12, w * 0.4, h * 0.12), castle);
    for (final tx in [0.26, 0.46, 0.66]) {
      final tw = w * 0.08;
      final th = h * (tx == 0.46 ? 0.22 : 0.17);
      canvas.drawRect(Rect.fromLTWH(w * tx, baseY - th, tw, th), castle);
      final roof = Path()
        ..moveTo(w * tx - 3, baseY - th)
        ..lineTo(w * tx + tw / 2, baseY - th - h * 0.05)
        ..lineTo(w * tx + tw + 3, baseY - th)
        ..close();
      canvas.drawPath(roof, Paint()..color = const Color(0xFF9D4EDD));
    }
    // glowing windows
    final win = Paint()..color = const Color(0xFFFFD60A);
    canvas.drawRect(Rect.fromLTWH(w * 0.485, baseY - h * 0.09, w * 0.03, h * 0.04), win);
    canvas.drawRect(Rect.fromLTWH(w * 0.285, baseY - h * 0.13, w * 0.03, h * 0.035), win);
    canvas.drawRect(Rect.fromLTWH(w * 0.685, baseY - h * 0.13, w * 0.03, h * 0.035), win);
    // twinkling sparkles (4-point stars)
    final rnd = math.Random(9);
    for (var i = 0; i < 10; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h * 0.55;
      final tw = (math.sin(time * 2 * math.pi * (0.8 + rnd.nextDouble()) + i * 2) + 1) / 2;
      final r = 2 + tw * 4;
      final p = Paint()..color = const Color(0xFFFFE066).withValues(alpha: 0.4 + tw * 0.6);
      final star = Path()
        ..moveTo(x, y - r)
        ..quadraticBezierTo(x, y, x + r, y)
        ..quadraticBezierTo(x, y, x, y + r)
        ..quadraticBezierTo(x, y, x - r, y)
        ..quadraticBezierTo(x, y, x, y - r)
        ..close();
      canvas.drawPath(star, p);
    }
  }

  @override
  bool shouldRepaint(WorldPainter oldDelegate) => false;
}
