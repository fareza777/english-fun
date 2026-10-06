import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// "Balon Pop" — hear the English word, pop the balloon with the right picture.
class BalloonScreen extends StatefulWidget {
  final List<VocabItem> words;
  final String title;
  const BalloonScreen({super.key, required this.words, required this.title});

  @override
  State<BalloonScreen> createState() => _BalloonScreenState();
}

class _Balloon {
  double x; // 0..1 of width
  double y; // px, decreases
  final double speed; // px per second
  final String emoji;
  final Color color;
  double wobble;
  _Balloon(this.x, this.y, this.speed, this.emoji, this.color) : wobble = 0;
}

class _BalloonScreenState extends State<BalloonScreen>
    with SingleTickerProviderStateMixin {
  static const _targets = 12;
  final _balloons = <_Balloon>[];
  final _rnd = math.Random();
  late final AnimationController _ticker;
  double _lastV = 0;
  double _spawnTimer = 0;
  int _spawnCount = 0;
  double _height = 600;
  late VocabItem _target;
  int _score = 0;
  int _popped = 0;
  bool _done = false;
  bool _missedTarget = false;

  static const _colors = [
    Color(0xFFFF6B6B),
    Color(0xFF4CC9F0),
    Color(0xFF43AA8B),
    Color(0xFFC77DFF),
    Color(0xFFFF9F1C),
    Color(0xFFFF8FAB),
  ];

  @override
  void initState() {
    super.initState();
    _newTarget();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(minutes: 5))
          ..addListener(_tick)
          ..forward();
    Future.delayed(const Duration(milliseconds: 600), _speakTarget);
  }

  void _speakTarget() {
    if (mounted && !_done) Sfx.I.speak(_target.en);
  }

  void _newTarget() {
    _target = widget.words[_rnd.nextInt(widget.words.length)];
    _missedTarget = false;
  }

  void _tick() {
    final v = _ticker.value;
    final dt = (v - _lastV) * _ticker.duration!.inMilliseconds / 1000;
    _lastV = v;
    if (_done || !mounted) return;
    setState(() {
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && _balloons.length < 6) {
        _spawnTimer = 1.05;
        _spawnCount++;
        // every 3rd balloon is the current target so it is always reachable
        final item = (_spawnCount % 3 == 0)
            ? _target
            : widget.words[_rnd.nextInt(widget.words.length)];
        _balloons.add(
          _Balloon(
            0.12 + _rnd.nextDouble() * 0.76,
            _height + 60,
            55 + _rnd.nextDouble() * 45 + _popped * 2.5,
            item.emoji,
            _colors[_rnd.nextInt(_colors.length)],
          ),
        );
      }
      for (final b in _balloons) {
        b.y -= b.speed * dt;
        b.wobble += dt;
      }
      _balloons.removeWhere((b) => b.y < -80);
    });
  }

  void _pop(_Balloon b) {
    if (_done || !_balloons.contains(b)) return;
    if (b.emoji == _target.emoji) {
      if (!_missedTarget) _score++;
      _popped++;
      Progress.I.recordCorrect(_target.en);
      Sfx.I.pop();
      Sfx.I.ding();
      setState(() => _balloons.remove(b));
      if (_popped >= _targets) {
        _finish();
      } else {
        _newTarget();
        _speakTarget();
      }
    } else {
      _missedTarget = true;
      Sfx.I.wrong();
      Progress.I.recordWrong(_target.en);
    }
  }

  void _finish() {
    _done = true;
    final stars = _score >= 12 ? 3 : (_score >= 9 ? 2 : (_score >= 6 ? 1 : 0));
    Progress.I.addCoins(_score * 2);
    Navigator.of(context).pushReplacement(
      funRoute(
        ResultScreen(
          title: 'Balon Pop',
          stars: stars,
          correct: _score,
          total: _targets,
          scoreCaption: 'Pada percobaan pertama',
          retryBuilder: () =>
              BalloonScreen(words: widget.words, title: widget.title),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _height = constraints.maxHeight;
              return Column(
                children: [
                  KidAppBar(
                    title: widget.title,
                    emoji: '🎈',
                    colors: const [],
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '$_popped/$_targets',
                        style: AppText.heading(18),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Letuskan: ${_target.idn}',
                              style: AppText.heading(22),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          BouncyButton(
                            onTap: _speakTarget,
                            child: const Icon(
                              Icons.volume_up_rounded,
                              color: Color(0xFF4361EE),
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        for (final b in _balloons)
                          Positioned(
                            left:
                                b.x * constraints.maxWidth -
                                38 +
                                math.sin(b.wobble * 2.2) * 8,
                            top: b.y,
                            child: GestureDetector(
                              onTap: () => _pop(b),
                              child: _balloonWidget(b),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _balloonWidget(_Balloon b) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: b.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: b.color.withValues(alpha: 0.5),
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(b.emoji, style: const TextStyle(fontSize: 38)),
        ),
        CustomPaint(size: const Size(12, 10), painter: _KnotPainter(b.color)),
        Container(width: 2, height: 26, color: Colors.white70),
      ],
    );
  }
}

class _KnotPainter extends CustomPainter {
  final Color color;
  _KnotPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_KnotPainter old) => old.color != color;
}
