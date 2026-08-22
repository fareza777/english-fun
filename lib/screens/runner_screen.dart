import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/lesson_builder.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/funky.dart';
import 'result_screen.dart';

/// "Lari Kata" — Funky runs; tap the gate with the correct English word
/// before the gates run past him.
class RunnerScreen extends StatefulWidget {
  final List<VocabItem> words;
  final String title;
  const RunnerScreen({super.key, required this.words, required this.title});

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen> with SingleTickerProviderStateMixin {
  static const _rounds = 10;
  final _rnd = math.Random();
  late final AnimationController _ticker;
  final _funkyKey = GlobalKey<FunkyMascotState>();
  double _lastV = 0;
  double _gateX = 500;
  double _groundOffset = 0;
  double _width = 360;
  late VocabItem _target;
  late List<String> _options;
  final Set<int> _wrongGates = {};
  int _index = 0;
  int _score = 0;
  int _hearts = 3;
  bool _resolved = false;
  bool _sad = false;
  bool _done = false;

  double get _speed => 130 + _index * 14;

  @override
  void initState() {
    super.initState();
    _newQuestion();
    _ticker = AnimationController(vsync: this, duration: const Duration(minutes: 5))
      ..addListener(_tick)
      ..forward();
    Future.delayed(const Duration(milliseconds: 600), _speakTarget);
  }

  void _speakTarget() {
    if (mounted && !_done) Sfx.I.speak(_target.en);
  }

  void _newQuestion() {
    _target =
        LessonBuilder.pickItems(widget.words, 1, random: _rnd).firstOrNull ??
        widget.words[_rnd.nextInt(widget.words.length)];
    _options = LessonBuilder.optionsFor(
      _target,
      widget.words,
      distractors: 2,
      random: _rnd,
    ).map((e) => e.en).toList();
    _wrongGates.clear();
    _gateX = _width + 140;
    _resolved = false;
  }

  void _tick() {
    final v = _ticker.value;
    final dt = (v - _lastV) * _ticker.duration!.inMilliseconds / 1000;
    _lastV = v;
    if (_done || !mounted) return;
    setState(() {
      _groundOffset = (_groundOffset + _speed * dt) % 60;
      _gateX -= _speed * dt;
      if (_gateX < -90 && !_resolved) {
        // gates ran past unanswered
        _resolved = true;
        _hearts--;
        Progress.I.recordWrong(_target.en);
        Sfx.I.wrong();
        _sadMoment();
        if (_hearts <= 0) {
          _finish();
        } else {
          _next();
        }
      }
    });
  }

  void _sadMoment() {
    setState(() => _sad = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _sad = false);
    });
  }

  void _tapGate(int i) {
    if (_resolved || _done || _wrongGates.contains(i)) return;
    if (_options[i] == _target.en) {
      _resolved = true;
      _score++;
      Progress.I.recordCorrect(_target.en);
      Sfx.I.ding();
      _funkyKey.currentState?.cheer();
      if (_index + 1 >= _rounds) {
        _finish();
      } else {
        _next();
      }
    } else {
      _wrongGates.add(i);
      _hearts--;
      Progress.I.recordWrong(_target.en);
      Sfx.I.wrong();
      _sadMoment();
      if (_hearts <= 0) _finish();
    }
  }

  void _next() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _done) return;
      setState(() {
        _index++;
        _newQuestion();
      });
      _speakTarget();
    });
  }

  void _finish() {
    _done = true;
    final stars = _score >= 9 ? 3 : (_score >= 6 ? 2 : (_score >= 3 ? 1 : 0));
    Progress.I.addCoins(_score * 2);
    Navigator.of(context).pushReplacement(
      funRoute(
        ResultScreen(
          title: 'Lari Kata',
          stars: stars,
          correct: _score,
          total: _rounds,
          retryBuilder: () => RunnerScreen(words: widget.words, title: widget.title),
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
        world: 3,
        child: SafeArea(
          child: Column(
            children: [
              KidAppBar(
                title: widget.title,
                emoji: '🏃',
                colors: const [],
                trailing: Row(
                  children: List.generate(
                    3,
                    (i) => Icon(
                      i < _hearts ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: const Color(0xFFFF6B6B),
                      size: 24,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_target.emoji, style: const TextStyle(fontSize: 34)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '${_target.idn}  ($_index/$_rounds)',
                          style: AppText.heading(22),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      BouncyButton(
                        onTap: _speakTarget,
                        child: const Icon(
                          Icons.volume_up_rounded,
                          color: Color(0xFF4361EE),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, play) {
                    _width = play.maxWidth;
                    final laneH = play.maxHeight / 4;
                    return Stack(
                      children: [
                        // moving ground
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 54,
                          child: CustomPaint(painter: _GroundPainter(_groundOffset)),
                        ),
                        // Funky running
                        Positioned(
                          left: 26,
                          bottom: 30,
                          child: FunkyMascot(
                            key: _funkyKey,
                            size: 92,
                            mood: _sad ? FunkyMood.sad : FunkyMood.happy,
                          ),
                        ),
                        // gates
                        for (var i = 0; i < 3; i++)
                          Positioned(
                            left: _gateX,
                            top: laneH * (i + 0.6),
                            child: GestureDetector(
                              onTap: () => _tapGate(i),
                              child: Container(
                                width: 118,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _wrongGates.contains(i)
                                      ? AppColors.wrong
                                      : (_resolved && _options[i] == _target.en
                                            ? AppColors.correct
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFF4361EE), width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _options[i],
                                  style:
                                      _wrongGates.contains(i) ||
                                          (_resolved && _options[i] == _target.en)
                                      ? AppText.display(18)
                                      : AppText.heading(18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Road with stripes sliding left to sell the running illusion.
class _GroundPainter extends CustomPainter {
  final double offset;
  _GroundPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF8D99AE),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 8), Paint()..color = const Color(0xFF43AA8B));
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (double x = -60 + offset; x < size.width + 60; x += 60) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(size.width - x, size.height * 0.55), width: 34, height: 6),
          const Radius.circular(3),
        ),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(_GroundPainter old) => old.offset != offset;
}
