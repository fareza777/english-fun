import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/progress.dart';

/// Funky the Fox, fully drawn with CustomPainter (no image assets):
/// blinks, bobs, cheers, gets sad, and can wear shop hats.
enum FunkyMood { happy, thinking, sad, excited }

class FunkyMascot extends StatefulWidget {
  final double size;
  final FunkyMood mood;
  final VoidCallback? onTap;
  const FunkyMascot({super.key, this.size = 84, this.mood = FunkyMood.happy, this.onTap});

  @override
  State<FunkyMascot> createState() => FunkyMascotState();
}

class FunkyMascotState extends State<FunkyMascot> with TickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _blink =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
  late final AnimationController _cheer =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  FunkyMood? _tempMood;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    if (!Progress.I.reducedMotion) _bob.repeat(reverse: true);
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(Duration(milliseconds: 1800 + math.Random().nextInt(2600)), () {
      if (!mounted) return;
      _blink.forward(from: 0).then((_) => _blink.reverse());
      _scheduleBlink();
    });
  }

  /// Jump + excited face (used on correct answers / taps).
  void cheer() {
    if (!mounted) return;
    setState(() => _tempMood = FunkyMood.excited);
    if (!Progress.I.reducedMotion) _cheer.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _tempMood = null);
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _bob.dispose();
    _blink.dispose();
    _cheer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = _tempMood ?? widget.mood;
    return GestureDetector(
      onTap: () {
        cheer();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_bob, _blink, _cheer]),
        builder: (context, _) {
          final bobDy = math.sin(_bob.value * math.pi) * -widget.size * 0.06;
          // cheer = parabolic jump
          final jumpDy = -math.sin(_cheer.value * math.pi) * widget.size * 0.35;
          final squash = _cheer.value > 0 && _cheer.value < 1
              ? 1 + math.sin(_cheer.value * math.pi) * 0.08
              : 1.0;
          return Transform.translate(
            offset: Offset(0, bobDy + jumpDy),
            child: Transform.scale(
              scale: squash,
              child: SizedBox(
                width: widget.size,
                height: widget.size * 1.06,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: FunkyPainter(mood: mood, blinkT: _blink.value),
                      ),
                    ),
                    if (Progress.I.equippedHat.isNotEmpty)
                      Positioned(
                        top: -widget.size * 0.22,
                        left: 0,
                        right: 0,
                        child: Transform.rotate(
                          angle: -0.12,
                          child: Text(
                            Progress.I.equippedHat,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: widget.size * 0.42),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Paints the fox in a 100x106 logical box.
class FunkyPainter extends CustomPainter {
  final FunkyMood mood;

  /// 0 = eyes open, 1 = fully blinked.
  final double blinkT;
  FunkyPainter({this.mood = FunkyMood.happy, this.blinkT = 0});

  static const _orange = Color(0xFFF77F00);
  static const _orangeDark = Color(0xFFE85D04);
  static const _cream = Color(0xFFFFF6E9);
  static const _dark = Color(0xFF3A2E2A);
  static const _tongue = Color(0xFFFF8FAB);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 106);

    final orange = Paint()..color = _orange;
    final darkOrange = Paint()..color = _orangeDark;
    final cream = Paint()..color = _cream;
    final dark = Paint()..color = _dark;

    // ---- tail (behind body): big curve with cream tip ----
    final tailWag = mood == FunkyMood.excited ? 6.0 : 0.0;
    final tail = Path()
      ..moveTo(72, 88)
      ..quadraticBezierTo(104, 86, 96 + tailWag, 52)
      ..quadraticBezierTo(92, 44, 84, 48)
      ..quadraticBezierTo(90, 70, 66, 80)
      ..close();
    canvas.drawPath(tail, orange);
    final tailTip = Path()
      ..moveTo(96 + tailWag, 52)
      ..quadraticBezierTo(92, 44, 84, 48)
      ..quadraticBezierTo(86, 56, 90, 58)
      ..close();
    canvas.drawPath(tailTip, cream);

    // ---- body ----
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 86), width: 52, height: 34), orange);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 90), width: 30, height: 20), cream);
    // feet
    canvas.drawOval(Rect.fromCenter(center: const Offset(36, 101), width: 16, height: 9), darkOrange);
    canvas.drawOval(Rect.fromCenter(center: const Offset(64, 101), width: 16, height: 9), darkOrange);

    // ---- ears (droop when sad) ----
    final droop = mood == FunkyMood.sad ? 7.0 : 0.0;
    Path ear(double tipX, double tipY, double baseL, double baseR) => Path()
      ..moveTo(baseL, 40)
      ..lineTo(tipX, tipY + droop)
      ..lineTo(baseR, 40)
      ..close();
    canvas.drawPath(ear(27, 10, 30, 44), orange);
    canvas.drawPath(ear(73, 10, 56, 70), orange);
    canvas.drawPath(ear(30, 20, 33.5, 41), darkOrange);
    canvas.drawPath(ear(70, 20, 59, 66.5), darkOrange);

    // ---- head ----
    canvas.drawCircle(const Offset(50, 46), 26, orange);
    // cheek mask
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 56), width: 34, height: 22), cream);

    // ---- eyes ----
    final eyeOpen = 1 - blinkT;
    void eye(double x, double y) {
      if (mood == FunkyMood.excited) {
        // happy closed arc: ^ ^
        final p = Path()
          ..moveTo(x - 5, y + 1.5)
          ..quadraticBezierTo(x, y - 5.5, x + 5, y + 1.5);
        canvas.drawPath(
            p,
            Paint()
              ..color = _dark
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..strokeCap = StrokeCap.round);
        return;
      }
      final look = mood == FunkyMood.thinking ? 2.2 : 0.0;
      final h = 4.4 * eyeOpen;
      if (h < 0.8) {
        canvas.drawLine(
            Offset(x - 4, y), Offset(x + 4, y),
            Paint()
              ..color = _dark
              ..strokeWidth = 2.2
              ..strokeCap = StrokeCap.round);
      } else {
        canvas.drawOval(Rect.fromCenter(center: Offset(x + look, y), width: 7.4, height: h * 2), dark);
        canvas.drawCircle(Offset(x + look - 1.4, y - h * 0.35), 1.3, cream);
      }
    }

    eye(39, 44);
    eye(61, 44);

    // sad eyebrows
    if (mood == FunkyMood.sad) {
      final brow = Paint()
        ..color = _dark
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(34, 36), const Offset(42, 39), brow);
      canvas.drawLine(const Offset(66, 36), const Offset(58, 39), brow);
    }

    // ---- nose ----
    final nose = Path()
      ..moveTo(45.5, 54)
      ..quadraticBezierTo(50, 51.5, 54.5, 54)
      ..quadraticBezierTo(52.5, 59, 50, 59)
      ..quadraticBezierTo(47.5, 59, 45.5, 54)
      ..close();
    canvas.drawPath(nose, dark);

    // ---- mouth ----
    final mouth = Paint()
      ..color = _dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    switch (mood) {
      case FunkyMood.excited:
        // open joyful mouth + tongue
        final open = Path()
          ..moveTo(43, 61)
          ..quadraticBezierTo(50, 70, 57, 61)
          ..close();
        canvas.drawPath(open, dark);
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(50, 64.5), width: 8, height: 5),
            Paint()..color = _tongue);
      case FunkyMood.sad:
        final frown = Path()
          ..moveTo(44, 64)
          ..quadraticBezierTo(50, 59.5, 56, 64);
        canvas.drawPath(frown, mouth);
      case FunkyMood.thinking:
        canvas.drawLine(const Offset(46, 62.5), const Offset(54, 62.5), mouth);
      case FunkyMood.happy:
        final smile = Path()
          ..moveTo(43, 60.5)
          ..quadraticBezierTo(50, 66.5, 57, 60.5);
        canvas.drawPath(smile, mouth);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(FunkyPainter old) => old.mood != mood || old.blinkT != blinkT;
}
