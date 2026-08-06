import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/stickers.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Daily reward wheel: one free spin per day.
class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> with SingleTickerProviderStateMixin {
  // (emoji, kind, amount)
  static const _segments = <(String, String, int)>[
    ('🪙', 'coins', 10),
    ('🪙', 'coins', 25),
    ('🎁', 'sticker', 0),
    ('🪙', 'coins', 5),
    ('🥚', 'egg', 1),
    ('🪙', 'coins', 15),
    ('🎁', 'sticker', 0),
    ('🪙', 'coins', 50),
  ];
  static const _colors = [
    Color(0xFFFF6B6B), Color(0xFFFFD60A), Color(0xFF43AA8B), Color(0xFF4CC9F0),
    Color(0xFFC77DFF), Color(0xFFFF9F1C), Color(0xFFFF8FAB), Color(0xFF7B61FF),
  ];

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
  late final Animation<double> _anim =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  double _targetRotation = 0;
  String _result = '';
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _applyReward();
    });
  }

  void _spin() {
    if (_spinning || !Progress.I.canSpinToday) return;
    setState(() {
      _spinning = true;
      _result = '';
      _targetRotation = (5 * 360 + math.Random().nextDouble() * 360) * math.pi / 180;
    });
    Sfx.I.pop();
    _c.forward(from: 0);
  }

  void _applyReward() {
    final rotDeg = _targetRotation * 180 / math.pi;
    final atPointer = ((270 - rotDeg) % 360 + 360) % 360;
    final index = (atPointer / 45).floor() % 8;
    final seg = _segments[index];
    String text;
    switch (seg.$2) {
      case 'coins':
        Progress.I.addCoins(seg.$3);
        text = '+${seg.$3} koin! 🪙';
      case 'egg':
        Progress.I.addEggs(seg.$3);
        text = 'Telur baru! 🥚';
      default:
        final unearned = kStickers.where((s) => !Progress.I.stickers.contains(s.$1)).toList();
        if (unearned.isNotEmpty) {
          final pick = unearned[math.Random().nextInt(unearned.length)];
          Progress.I.awardSticker(pick.$1);
          text = 'Stiker ${pick.$1} ${pick.$2}!';
        } else {
          Progress.I.addCoins(20);
          text = '+20 koin! 🪙';
        }
    }
    Progress.I.markSpunToday();
    setState(() {
      _spinning = false;
      _result = text;
    });
    Sfx.I.win();
    Sfx.I.praise();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSpin = Progress.I.canSpinToday && !_spinning;
    return Scaffold(
      body: AnimatedBackground(
        world: 4,
        child: SafeArea(
          child: Column(
            children: [
              const KidAppBar(title: 'Roda Harian', emoji: '🎡', colors: []),
              const SizedBox(height: 10),
              Text('Putar gratis sekali sehari!',
                  style: AppText.body(17, color: Colors.white)),
              const SizedBox(height: 6),
              // pointer
              const Text('🔻', style: TextStyle(fontSize: 34)),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) => Transform.rotate(
                      angle: _anim.value * _targetRotation,
                      child: child,
                    ),
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: _WheelPainter(_segments, _colors),
                    ),
                  ),
                ),
              ),
              if (_result.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_result, style: AppText.display(28)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: PillButton(
                  label: canSpin
                      ? 'PUTAR! 🎡'
                      : (_spinning ? 'Berputar...' : 'Sudah diputar — kembali besok!'),
                  emoji: canSpin ? '🍀' : '⏰',
                  color: canSpin ? AppColors.correct : Colors.grey.shade400,
                  onTap: canSpin ? _spin : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<(String, String, int)> segments;
  final List<Color> colors;
  const _WheelPainter(this.segments, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < segments.length; i++) {
      final start = i * math.pi / 4;
      canvas.drawArc(rect, start, math.pi / 4, true, Paint()..color = colors[i]);
    }
    // rim + hub
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
    canvas.drawCircle(center, 26, Paint()..color = Colors.white);
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFFFFB703));
    // labels
    for (var i = 0; i < segments.length; i++) {
      final angle = (i + 0.5) * math.pi / 4;
      final labelCenter = center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.62;
      final tp = TextPainter(
        text: TextSpan(
          text: segments[i].$2 == 'coins' ? '${segments[i].$1}${segments[i].$3}' : segments[i].$1,
          style: const TextStyle(fontSize: 26),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, labelCenter - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}
