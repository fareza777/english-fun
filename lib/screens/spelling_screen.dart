import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/lesson_builder.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Spelling bee: arrange scrambled letters to spell the English word.
class SpellingScreen extends StatefulWidget {
  final Unit unit;
  const SpellingScreen({super.key, required this.unit});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> with SingleTickerProviderStateMixin {
  late final List<VocabItem> _rounds;
  final ConfettiController _confetti = ConfettiController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  int _index = 0;
  int _mistakes = 0;
  late String _word;
  late List<String?> _slots;
  late List<String> _pool;
  bool _locked = false;

  VocabItem get _item => _rounds[_index];

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _rounds = LessonBuilder.pickItems(widget.unit.spellingItems, 6, random: rnd);
    _setupRound();
    Future.delayed(const Duration(milliseconds: 500), () => Sfx.I.speak(_item.en));
  }

  void _setupRound() {
    _word = _item.en.toUpperCase().replaceAll(' ', '');
    _slots = List.filled(_word.length, null);
    _pool = _word.split('')..shuffle(math.Random());
    _locked = false;
  }

  @override
  void dispose() {
    _shake.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _tapPool(int i) {
    if (_locked) return;
    final empty = _slots.indexOf(null);
    if (empty < 0) return;
    Sfx.I.pop();
    setState(() {
      _slots[empty] = _pool.removeAt(i);
    });
    if (!_slots.contains(null)) _check();
  }

  void _tapSlot(int i) {
    if (_locked || _slots[i] == null) return;
    Sfx.I.click();
    setState(() {
      _pool.add(_slots[i]!);
      _slots[i] = null;
    });
  }

  Future<void> _check() async {
    final attempt = _slots.join();
    if (attempt == _word) {
      _locked = true;
      Progress.I.recordCorrect(_item.en);
      Sfx.I.ding();
      _confetti.burst();
      Sfx.I.speak(_item.en);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      if (_index < _rounds.length - 1) {
        setState(() {
          _index++;
          _setupRound();
        });
        Future.delayed(const Duration(milliseconds: 350), () => Sfx.I.speak(_item.en));
      } else {
        _finish();
      }
    } else {
      _mistakes++;
      Progress.I.recordWrong(_item.en);
      Sfx.I.wrong();
      _shake.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _pool = _word.split('')..shuffle(math.Random());
        _slots = List.filled(_word.length, null);
      });
    }
  }

  Future<void> _finish() async {
    final stars = _mistakes == 0 ? 3 : (_mistakes <= 2 ? 2 : 1);
    await Progress.I.setStars(widget.unit.id, 'spell', stars);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      funRoute(
        ResultScreen(
          title: 'Susun Huruf',
          stars: stars,
          correct: _rounds.length - _mistakes > 0 ? _rounds.length - _mistakes : 0,
          total: _rounds.length,
          retryBuilder: () => SpellingScreen(unit: widget.unit),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Stack(
          children: [
            Column(
              children: [
                KidAppBar(title: 'Susun Huruf', emoji: '🔤', colors: const []),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text('Kata ${_index + 1}/${_rounds.length}', style: AppText.heading(20)),
                      const Spacer(),
                      BouncyButton(
                        sound: false,
                        onTap: () {
                          Sfx.I.pop();
                          Sfx.I.speak(_item.en);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.sun,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volume_up_rounded,
                            size: 28,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFF7ED6FF), width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(_item.emoji, style: const TextStyle(fontSize: 76)),
                            ),
                            Text(_item.idn, style: AppText.body(20)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      // answer slots
                      AnimatedBuilder(
                        animation: _shake,
                        builder: (context, child) {
                          final dx = math.sin(_shake.value * math.pi * 5) * 9 * (1 - _shake.value);
                          return Transform.translate(offset: Offset(dx, 0), child: child);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_word.length, (i) {
                                final filled = _slots[i] != null;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: BouncyButton(
                                    sound: false,
                                    onTap: () => _tapSlot(i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 46,
                                      height: 56,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: filled
                                            ? const Color(0xFF4361EE)
                                            : Colors.white.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: filled
                                              ? const Color(0xFF4361EE)
                                              : const Color(0xFF7ED6FF),
                                          width: 3,
                                        ),
                                      ),
                                      child: Text(
                                        _slots[i] ?? '',
                                        style: AppText.display(
                                          28,
                                          color: filled ? Colors.white : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // letter pool
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(_pool.length, (i) {
                            return BouncyButton(
                              sound: false,
                              onTap: () => _tapPool(i),
                              child: Container(
                                width: 52,
                                height: 60,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.sun,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x66B26A00), offset: Offset(0, 4)),
                                  ],
                                ),
                                child: Text(_pool[i], style: AppText.heading(30)),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text('Ketuk huruf untuk menyusun kata!', style: AppText.body(16)),
                ),
              ],
            ),
            Positioned.fill(child: ConfettiOverlay(controller: _confetti)),
          ],
        ),
      ),
    );
  }
}
