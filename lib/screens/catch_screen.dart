import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// "Tangkap Kata" — move Funky's basket and catch the correct English word.
class CatchScreen extends StatefulWidget {
  final List<VocabItem> words;
  final String title;
  const CatchScreen({super.key, required this.words, required this.title});

  @override
  State<CatchScreen> createState() => _CatchScreenState();
}

class _Falling {
  final String word;
  final bool isTarget;
  double x; // px
  double y; // px
  final double speed;
  _Falling(this.word, this.isTarget, this.x, this.y, this.speed);
}

class _CatchScreenState extends State<CatchScreen> with SingleTickerProviderStateMixin {
  static const _goal = 10;
  final _items = <_Falling>[];
  final _rnd = math.Random();
  late final AnimationController _ticker;
  double _lastV = 0;
  double _spawnTimer = 0;
  int _spawnCount = 0;
  double _basketX = 160;
  double _width = 360;
  double _playH = 400; // height of the play Stack (set by inner LayoutBuilder)
  late VocabItem _target;
  int _score = 0;
  int _hearts = 3;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _newTarget();
    _ticker = AnimationController(vsync: this, duration: const Duration(minutes: 5))
      ..addListener(_tick)
      ..forward();
    Future.delayed(const Duration(milliseconds: 600), _speakTarget);
  }

  void _speakTarget() {
    // speak only the word so the studio voice-over is used
    if (mounted && !_done) Sfx.I.speak(_target.en);
  }

  void _newTarget() {
    _target = widget.words[_rnd.nextInt(widget.words.length)];
  }

  void _tick() {
    final v = _ticker.value;
    final dt = (v - _lastV) * _ticker.duration!.inMilliseconds / 1000;
    _lastV = v;
    if (_done || !mounted) return;
    setState(() {
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && _items.length < 5) {
        _spawnTimer = 1.25;
        _spawnCount++;
        final isTarget = _spawnCount % 3 == 0;
        final item = isTarget ? _target : widget.words[_rnd.nextInt(widget.words.length)];
        _items.add(
          _Falling(
            item.en,
            isTarget,
            30 + _rnd.nextDouble() * (_width - 90),
            -40,
            90 + _rnd.nextDouble() * 50 + _score * 6,
          ),
        );
      }
      final basketY = _playH - 110;
      final caught = <_Falling>[];
      for (final it in _items) {
        it.y += it.speed * dt;
        if (it.y > basketY - 24 && it.y < basketY + 40 && (it.x - _basketX).abs() < 62) {
          caught.add(it);
        }
      }
      for (final it in caught) {
        _items.remove(it);
        _resolveCatch(it);
      }
      _items.removeWhere((it) => it.y > _playH + 40);
    });
  }

  void _resolveCatch(_Falling it) {
    if (_done) return;
    if (it.word == _target.en) {
      _score++;
      Progress.I.recordCorrect(_target.en);
      Sfx.I.ding();
      if (_score >= _goal) {
        _finish();
      } else {
        _newTarget();
        _speakTarget();
      }
    } else {
      _hearts--;
      Progress.I.recordWrong(_target.en);
      Sfx.I.wrong();
      if (_hearts <= 0) _finish();
    }
  }

  void _finish() {
    _done = true;
    final stars = _score >= 10 ? 3 : (_score >= 7 ? 2 : (_score >= 4 ? 1 : 0));
    Progress.I.addCoins(_score * 2);
    Navigator.of(context).pushReplacement(
      funRoute(
        ResultScreen(
          title: 'Tangkap Kata',
          stars: stars,
          correct: _score,
          total: _goal,
          retryBuilder: () => CatchScreen(words: widget.words, title: widget.title),
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
        world: 1,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _width = constraints.maxWidth;
              _basketX = _basketX.clamp(50, _width - 50);
              return GestureDetector(
                onPanUpdate: (d) => setState(() => _basketX = d.localPosition.dx),
                onTapDown: (d) => setState(() => _basketX = d.localPosition.dx),
                child: Column(
                  children: [
                    KidAppBar(
                      title: widget.title,
                      emoji: '🧺',
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
                            Text(_target.emoji, style: const TextStyle(fontSize: 30)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Tangkap: ${_target.idn}  ($_score/$_goal)',
                                style: AppText.heading(20),
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
                          _playH = play.maxHeight;
                          return Stack(
                            children: [
                              for (final it in _items)
                                Positioned(
                                  left: it.x - 55,
                                  top: it.y,
                                  child: Container(
                                    width: 110,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF4361EE), width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x22000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      it.word,
                                      style: AppText.heading(17),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              // basket
                              Positioned(
                                left: _basketX - 46,
                                top: _playH - 110,
                                child: const Text('🧺', style: TextStyle(fontSize: 72)),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
