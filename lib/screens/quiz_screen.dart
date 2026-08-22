import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/lesson_builder.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

enum QuizMode { picture, listening }

class _Question {
  final VocabItem correct;
  final List<VocabItem> options;
  _Question(this.correct, this.options);
}

/// Picture quiz (pick the right word) & listening quiz (pick the right picture).
class QuizScreen extends StatefulWidget {
  final Unit unit;
  final QuizMode mode;
  const QuizScreen({super.key, required this.unit, required this.mode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late final List<_Question> _questions;
  final ConfettiController _confetti = ConfettiController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  int _index = 0;
  int _correctCount = 0;
  int? _selected;
  bool _locked = false;

  bool get _isPicture => widget.mode == QuizMode.picture;
  _Question get _q => _questions[_index];

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
    if (!_isPicture) {
      Future.delayed(const Duration(milliseconds: 600), _speakQuestion);
    }
  }

  List<_Question> _buildQuestions() {
    final rnd = math.Random();
    // Spaced repetition decides *which* words are asked...
    final picked = LessonBuilder.pickItems(widget.unit.items, 8, random: rnd);
    return picked.map((item) {
      // ...and confusability decides which wrong answers sit next to them.
      final options = LessonBuilder.optionsFor(item, widget.unit.items, random: rnd);
      return _Question(item, options);
    }).toList();
  }

  @override
  void dispose() {
    _shake.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _speakQuestion() => Sfx.I.speak(_q.correct.en);

  Future<void> _answer(int i) async {
    if (_locked) return;
    setState(() {
      _selected = i;
      _locked = true;
    });
    final correct = _q.options[i] == _q.correct;
    if (correct) {
      _correctCount++;
      Progress.I.recordCorrect(_q.correct.en);
      Sfx.I.ding();
      _confetti.burst();
      Sfx.I.speak(_q.correct.en);
      await Future.delayed(const Duration(milliseconds: 1100));
    } else {
      Progress.I.recordWrong(_q.correct.en);
      Sfx.I.wrong();
      _shake.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    if (!mounted) return;
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _locked = false;
      });
      if (!_isPicture) {
        Future.delayed(const Duration(milliseconds: 450), _speakQuestion);
      }
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final total = _questions.length;
    final pct = _correctCount / total;
    final stars = pct >= 0.9 ? 3 : (pct >= 0.6 ? 2 : 1);
    await Progress.I.setStars(widget.unit.id, _isPicture ? 'quiz' : 'listen', stars);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      funRoute(
        ResultScreen(
          title: _isPicture ? 'Tebak Kata' : 'Tebak Suara',
          stars: stars,
          correct: _correctCount,
          total: total,
          retryBuilder: () => QuizScreen(unit: widget.unit, mode: widget.mode),
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
                KidAppBar(
                  title: _isPicture ? 'Tebak Kata' : 'Tebak Suara',
                  emoji: _isPicture ? '🎯' : '🎧',
                  colors: const [],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Text('Soal ${_index + 1}/${_questions.length}', style: AppText.heading(20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_index + 1) / _questions.length,
                            minHeight: 12,
                            backgroundColor: Colors.white.withValues(alpha: 0.6),
                            valueColor: const AlwaysStoppedAnimation(AppColors.sun),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) {
                      final dx = math.sin(_shake.value * math.pi * 5) * 10 * (1 - _shake.value);
                      return Transform.translate(offset: Offset(dx, 0), child: child);
                    },
                    child: _isPicture ? _pictureLayout() : _listeningLayout(),
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

  Widget _pictureLayout() {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF7ED6FF), width: 5),
                boxShadow: const [
                  BoxShadow(color: Color(0x2A000000), blurRadius: 14, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_q.correct.emoji, style: const TextStyle(fontSize: 110)),
                      ),
                    ),
                  ),
                  Text('Apa bahasa Inggrisnya?', style: AppText.body(18)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            itemCount: _q.options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _wordOption(i),
          ),
        ),
      ],
    );
  }

  Widget _listeningLayout() {
    return Column(
      children: [
        BouncyButton(
          sound: false,
          onTap: () {
            Sfx.I.pop();
            _speakQuestion();
          },
          child: Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.sun,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x55B26A00), offset: Offset(0, 6))],
            ),
            child: const Icon(Icons.volume_up_rounded, size: 64, color: AppColors.ink),
          ),
        ),
        Text('Dengarkan, lalu pilih gambarnya!', style: AppText.body(18)),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: List.generate(_q.options.length, (i) => _emojiOption(i)),
          ),
        ),
      ],
    );
  }

  Color _optionColor(int i, Color base) {
    if (_selected == null) return base;
    final isCorrect = _q.options[i] == _q.correct;
    if (isCorrect) return AppColors.correct;
    if (_selected == i) return AppColors.wrong;
    return base.withValues(alpha: 0.55);
  }

  Widget _wordOption(int i) {
    final color = _optionColor(i, const Color(0xFF4361EE));
    return BouncyButton(
      sound: false,
      onTap: _locked ? null : () => _answer(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _q.options[i].en,
                textAlign: TextAlign.center,
                style: AppText.display(24),
              ),
            ),
            if (_selected != null && _q.options[i] == _q.correct)
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 30),
            if (_selected == i && _q.options[i] != _q.correct)
              const Icon(Icons.cancel_rounded, color: Colors.white, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _emojiOption(int i) {
    final color = _optionColor(i, Colors.white);
    final borderColor = _selected == null
        ? const Color(0xFF7ED6FF)
        : (_q.options[i] == _q.correct
              ? AppColors.correct
              : (_selected == i ? AppColors.wrong : Colors.grey.shade300));
    return BouncyButton(
      sound: false,
      onTap: _locked ? null : () => _answer(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 5),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(_q.options[i].emoji, style: const TextStyle(fontSize: 64)),
            ),
          ),
        ),
      ),
    );
  }
}
