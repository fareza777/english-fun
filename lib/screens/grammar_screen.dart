import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Interactive grammar lesson: pattern cards + examples with TTS + challenges.
/// Stars reward first-try correct answers.
class GrammarScreen extends StatefulWidget {
  final Unit unit;
  const GrammarScreen({super.key, required this.unit});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> with SingleTickerProviderStateMixin {
  final ConfettiController _confetti = ConfettiController();
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  int _page = 0;
  final Map<String, int?> _selected = {};
  final Set<String> _solved = {};
  final Set<String> _failed = {};

  List<GrammarPage> get pages => widget.unit.pages;
  GrammarPage get _p => pages[_page];
  int get _total => pages.fold(0, (s, p) => s + p.challenges.length);

  String _key(int page, int ci) => '$page:$ci';

  @override
  void dispose() {
    _shake.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _answer(int ci, int optionIndex) async {
    final k = _key(_page, ci);
    if (_solved.contains(k)) return;
    final challenge = _p.challenges[ci];
    setState(() => _selected[k] = optionIndex);
    if (optionIndex == challenge.answer) {
      _solved.add(k);
      Sfx.I.ding();
      _confetti.burst();
      Sfx.I.speak(challenge.full);
    } else {
      _failed.add(k);
      Sfx.I.wrong();
      _shake.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _selected[k] = null);
    }
  }

  void _goTo(int page) {
    if (page < 0 || page >= pages.length) return;
    Sfx.I.flip();
    setState(() => _page = page);
  }

  Future<void> _finish() async {
    final total = _total;
    final perfect = _solved.where((k) => !_failed.contains(k)).length;
    final stars = total == 0
        ? 3
        : (perfect >= total ? 3 : (perfect >= (total * 0.6).ceil() ? 2 : 1));
    await Progress.I.setStars(widget.unit.id, 'learn', stars);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(funRoute(ResultScreen(
      title: widget.unit.title,
      stars: stars,
      correct: perfect,
      total: total,
      retryBuilder: () => GrammarScreen(unit: widget.unit),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == pages.length - 1;
    return Scaffold(
      body: AnimatedBackground(
        child: Stack(
          children: [
            Column(
              children: [
                KidAppBar(title: widget.unit.title, emoji: widget.unit.emoji, colors: const []),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 28 : 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: i == _page ? AppColors.ink : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: ListView(
                      key: ValueKey(_page),
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF9B5DE5), Color(0xFF5A189A)]),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [BoxShadow(color: Color(0x555A189A), offset: Offset(0, 5))],
                          ),
                          child: Text(_p.title, textAlign: TextAlign.center, style: AppText.display(26)),
                        ),
                        const SizedBox(height: 12),
                        SpeechBubble(text: _p.explain, fontSize: 17),
                        const SizedBox(height: 14),
                        ..._p.examples.map((e) => _ExampleCard(example: e)),
                        if (_p.challenges.isNotEmpty) const SizedBox(height: 8),
                        ...List.generate(_p.challenges.length, (ci) {
                          final k = _key(_page, ci);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AnimatedBuilder(
                              animation: _shake,
                              builder: (context, child) {
                                final dx = math.sin(_shake.value * math.pi * 5) * 9 * (1 - _shake.value);
                                return Transform.translate(offset: Offset(dx, 0), child: child);
                              },
                              child: _ChallengeCard(
                                number: ci + 1,
                                challenge: _p.challenges[ci],
                                selected: _selected[k],
                                solved: _solved.contains(k),
                                onPick: (opt) => _answer(ci, opt),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
                      children: [
                        if (_page > 0)
                          PillButton(
                            label: 'Kembali',
                            emoji: '⬅️',
                            color: Colors.blueGrey,
                            fontSize: 18,
                            onTap: () => _goTo(_page - 1),
                          ),
                        const Spacer(),
                        if (!isLast)
                          PillButton(
                            label: 'Lanjut',
                            emoji: '➡️',
                            color: const Color(0xFF4361EE),
                            fontSize: 18,
                            onTap: () => _goTo(_page + 1),
                          )
                        else
                          PillButton(
                            label: 'Selesai!',
                            emoji: '🎉',
                            color: AppColors.correct,
                            fontSize: 18,
                            onTap: _finish,
                          ),
                      ],
                    ),
                  ),
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

class _ExampleCard extends StatelessWidget {
  final GrammarExample example;
  const _ExampleCard({required this.example});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3D7FF), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Text(example.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(example.en, style: AppText.heading(20)),
                Text(example.idn, style: AppText.body(15)),
              ],
            ),
          ),
          BouncyButton(
            sound: false,
            onTap: () {
              Sfx.I.pop();
              Sfx.I.speak(example.en);
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: AppColors.sun, shape: BoxShape.circle),
              child: const Icon(Icons.volume_up_rounded, size: 26, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final int number;
  final Challenge challenge;
  final int? selected;
  final bool solved;
  final ValueChanged<int> onPick;
  const _ChallengeCard({
    required this.number,
    required this.challenge,
    required this.selected,
    required this.solved,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sun, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x33B26A00), offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text('⚡ Soal $number', style: AppText.heading(20, color: const Color(0xFFB26A00))),
          const SizedBox(height: 8),
          Text(
            challenge.prompt,
            textAlign: TextAlign.center,
            style: AppText.heading(24),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: List.generate(challenge.options.length, (i) {
              Color color = const Color(0xFF4361EE);
              if (selected != null || solved) {
                if (i == challenge.answer && (solved || selected == i)) {
                  color = AppColors.correct;
                } else if (selected == i) {
                  color = AppColors.wrong;
                }
              }
              return BouncyButton(
                sound: false,
                onTap: () => onPick(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), offset: const Offset(0, 4))],
                  ),
                  child: Text(challenge.options[i], style: AppText.display(22)),
                ),
              );
            }),
          ),
          if (solved) ...[
            const SizedBox(height: 10),
            Text('✅ ${challenge.full}', textAlign: TextAlign.center, style: AppText.body(17, color: AppColors.correct)),
          ],
        ],
      ),
    );
  }
}
