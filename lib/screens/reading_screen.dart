import 'package:flutter/material.dart';

import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Story time: read line by line with TTS, then answer comprehension quiz.
class ReadingScreen extends StatefulWidget {
  final Unit unit;
  final bool startAtQuiz;
  const ReadingScreen({super.key, required this.unit, this.startAtQuiz = false});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final ConfettiController _confetti = ConfettiController();
  late bool _quizPhase;
  int _line = 0;
  int _qIndex = 0;
  int _correct = 0;
  int? _selected;
  bool _locked = false;

  Story get story => widget.unit.story!;

  @override
  void initState() {
    super.initState();
    _quizPhase = widget.startAtQuiz;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_quizPhase) {
        _speakQuestion();
      } else {
        Sfx.I.speak(story.lines[0].en);
      }
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    Sfx.I.stopSpeak();
    super.dispose();
  }

  void _speakQuestion() => Sfx.I.speak(story.questions[_qIndex].prompt);

  void _goLine(int i) {
    if (i < 0 || i >= story.lines.length) return;
    Sfx.I.flip();
    setState(() => _line = i);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Sfx.I.speak(story.lines[i].en);
    });
  }

  Future<void> _startQuiz() async {
    await Progress.I.setStars(widget.unit.id, 'read', 1);
    Sfx.I.fanfare();
    setState(() => _quizPhase = true);
    Future.delayed(const Duration(milliseconds: 500), _speakQuestion);
  }

  Future<void> _answer(int i) async {
    if (_locked) return;
    final q = story.questions[_qIndex];
    setState(() {
      _selected = i;
      _locked = true;
    });
    if (i == q.answer) {
      _correct++;
      Sfx.I.ding();
      _confetti.burst();
      Sfx.I.speak(q.full);
      await Future.delayed(const Duration(milliseconds: 1200));
    } else {
      Sfx.I.wrong();
      await Future.delayed(const Duration(milliseconds: 1400));
    }
    if (!mounted) return;
    if (_qIndex < story.questions.length - 1) {
      setState(() {
        _qIndex++;
        _selected = null;
        _locked = false;
      });
      Future.delayed(const Duration(milliseconds: 400), _speakQuestion);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final total = story.questions.length;
    final stars = _correct >= total ? 3 : (_correct >= total - 1 ? 2 : 1);
    await Progress.I.setStars(widget.unit.id, 'quiz', stars);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(funRoute(ResultScreen(
      title: 'Kuis Cerita',
      stars: stars,
      correct: _correct,
      total: total,
      retryBuilder: () => ReadingScreen(unit: widget.unit, startAtQuiz: true),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Stack(
          children: [
            _quizPhase ? _buildQuiz() : _buildReading(),
            Positioned.fill(child: ConfettiOverlay(controller: _confetti)),
          ],
        ),
      ),
    );
  }

  Widget _buildReading() {
    final line = story.lines[_line];
    final isLast = _line == story.lines.length - 1;
    return Column(
      children: [
        KidAppBar(title: story.title, emoji: story.emoji, colors: const []),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(story.lines.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _line ? 26 : 11,
                height: 11,
                decoration: BoxDecoration(
                  color: i == _line ? AppColors.ink : Colors.white.withOpacity(0.7),
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
              child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(anim), child: child),
            ),
            child: Container(
              key: ValueKey(_line),
              margin: const EdgeInsets.fromLTRB(26, 10, 26, 10),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFFFD60A), width: 5),
                boxShadow: const [BoxShadow(color: Color(0x2A000000), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(line.emoji, style: const TextStyle(fontSize: 110)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        line.en,
                        textAlign: TextAlign.center,
                        style: AppText.heading(32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(line.idn, textAlign: TextAlign.center, style: AppText.body(19)),
                  const SizedBox(height: 10),
                  BouncyButton(
                    sound: false,
                    onTap: () {
                      Sfx.I.pop();
                      Sfx.I.speak(line.en);
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(color: AppColors.sun, shape: BoxShape.circle),
                      child: const Icon(Icons.volume_up_rounded, size: 32, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: Row(
              children: [
                if (_line > 0)
                  PillButton(
                    label: 'Kembali',
                    emoji: '⬅️',
                    color: Colors.blueGrey,
                    fontSize: 18,
                    onTap: () => _goLine(_line - 1),
                  ),
                const Spacer(),
                if (!isLast)
                  PillButton(
                    label: 'Lanjut',
                    emoji: '➡️',
                    color: const Color(0xFF4361EE),
                    fontSize: 18,
                    onTap: () => _goLine(_line + 1),
                  )
                else
                  PillButton(
                    label: 'Kuis Cerita!',
                    emoji: '🎯',
                    color: AppColors.correct,
                    fontSize: 18,
                    onTap: _startQuiz,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuiz() {
    final q = story.questions[_qIndex];
    return Column(
      children: [
        KidAppBar(title: 'Kuis Cerita', emoji: '🎯', colors: const []),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Text('Soal ${_qIndex + 1}/${story.questions.length}', style: AppText.heading(20)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF7ED6FF), width: 4),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Text(story.emoji, style: const TextStyle(fontSize: 54)),
                    const SizedBox(height: 8),
                    Text(q.prompt, textAlign: TextAlign.center, style: AppText.heading(26)),
                    const SizedBox(height: 6),
                    BouncyButton(
                      sound: false,
                      onTap: () {
                        Sfx.I.pop();
                        _speakQuestion();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.sun, shape: BoxShape.circle),
                        child: const Icon(Icons.volume_up_rounded, size: 26, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(q.options.length, (i) {
                Color color = const Color(0xFF4361EE);
                if (_selected != null) {
                  if (i == q.answer) {
                    color = AppColors.correct;
                  } else if (_selected == i) {
                    color = AppColors.wrong;
                  } else {
                    color = color.withOpacity(0.5);
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BouncyButton(
                    sound: false,
                    onTap: _locked ? null : () => _answer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.4), offset: const Offset(0, 5))],
                      ),
                      child: Text(q.options[i], textAlign: TextAlign.center, style: AppText.display(24)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
