import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// End-of-grade Boss Battle: a dragon quizzes the kid on the words they
/// struggle with most (spaced repetition). 10 hits to win, 3 hearts, timer.
class BossScreen extends StatefulWidget {
  final Grade grade;
  const BossScreen({super.key, required this.grade});

  @override
  State<BossScreen> createState() => _BossScreenState();
}

class _BossScreenState extends State<BossScreen> with TickerProviderStateMixin {
  static const _rounds = 10;
  static const _secondsPerQuestion = 12;

  late final List<VocabItem> _questions;
  late final Map<VocabItem, List<String>> _options;
  int _index = 0;
  int _bossHp = _rounds;
  int _hearts = 3;
  int _hits = 0;
  bool _locked = false;
  int? _picked;
  bool _shakeBoss = false;

  late final AnimationController _timer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _secondsPerQuestion),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) _timeout();
    });

  VocabItem get _q => _questions[_index];

  @override
  void initState() {
    super.initState();
    final all = widget.grade.units.expand((u) => u.items).toList();
    // weakest words first (spaced repetition), then random fill
    all.sort((a, b) => Progress.I.wrongCount(b.en).compareTo(Progress.I.wrongCount(a.en)));
    final weak = all.where((e) => Progress.I.wrongCount(e.en) > 0).take(6).toList();
    final rest = List<VocabItem>.from(all)..shuffle(math.Random());
    final picked = <VocabItem>{...weak};
    for (final it in rest) {
      if (picked.length >= _rounds) break;
      picked.add(it);
    }
    _questions = picked.toList()..shuffle(math.Random());
    _options = {
      for (final q in _questions) q: _makeOptions(q, all),
    };
    Sfx.I.speak('Boss battle! Defeat the dragon!');
    _startTimer();
  }

  List<String> _makeOptions(VocabItem q, List<VocabItem> all) {
    final rnd = math.Random();
    final pool = all.where((e) => e.en != q.en).toList()..shuffle(rnd);
    final opts = [q.en, ...pool.take(3).map((e) => e.en)]..shuffle(rnd);
    return opts;
  }

  void _startTimer() => _timer.forward(from: 0);

  void _timeout() {
    if (_locked || !mounted) return;
    _locked = true;
    Sfx.I.wrong();
    Progress.I.recordWrong(_q.en);
    _loseHeart();
  }

  void _answer(int i) {
    if (_locked) return;
    _locked = true;
    _picked = i;
    final correct = _options[_q]![i] == _q.en;
    _timer.stop();
    if (correct) {
      _hits++;
      _bossHp--;
      Progress.I.recordCorrect(_q.en);
      Sfx.I.ding();
      setState(() => _shakeBoss = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shakeBoss = false);
      });
      if (_bossHp <= 0) {
        _finish(win: true);
        return;
      }
    } else {
      Progress.I.recordWrong(_q.en);
      Sfx.I.wrong();
      _loseHeart();
      return;
    }
    _next();
  }

  void _loseHeart() {
    _hearts--;
    if (_hearts <= 0) {
      _finish(win: false);
      return;
    }
    _next();
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      _finish(win: _bossHp <= 0);
      return;
    }
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _index++;
        _locked = false;
        _picked = null;
      });
      _startTimer();
    });
  }

  void _finish({required bool win}) {
    _timer.stop();
    final stars = win ? _hearts.clamp(1, 3) : 0;
    Progress.I.setStars('boss_g${widget.grade.level}', 'boss', stars);
    if (win) {
      Progress.I.addCoins(25);
      Progress.I.addEggs(1); // boss drops a pet egg!
      Progress.I.awardSticker('🏆');
      Sfx.I.win();
    }
    Navigator.of(context).pushReplacement(funRoute(ResultScreen(
      title: win ? 'Boss Kalah! 🎉' : 'Boss Menang...',
      stars: stars,
      correct: _hits,
      total: _rounds,
      retryBuilder: () => BossScreen(grade: widget.grade),
    )));
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        world: 6,
        child: SafeArea(
          child: Column(
            children: [
              KidAppBar(
                title: 'Boss Battle',
                emoji: '🐉',
                colors: const [Color(0xFF4361EE), Color(0xFF9B5DE5)],
                trailing: Row(
                  children: List.generate(
                    3,
                    (i) => Icon(
                      i < _hearts ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: const Color(0xFFFF6B6B),
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // boss + HP bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                transform: _shakeBoss
                    ? (Matrix4.identity()..translate(math.Random().nextDouble() * 8 - 4))
                    : Matrix4.identity(),
                child: const Text('🐉', style: TextStyle(fontSize: 76)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _bossHp / _rounds,
                    minHeight: 14,
                    backgroundColor: Colors.white.withOpacity(0.35),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFEF476F)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // timer bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AnimatedBuilder(
                  animation: _timer,
                  builder: (context, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 1 - _timer.value,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor: AlwaysStoppedAnimation(
                        _timer.value > 0.7 ? AppColors.wrong : AppColors.correct,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // question card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_q.emoji, style: const TextStyle(fontSize: 54)),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Text(
                        'Apa bahasa Inggrisnya?',
                        style: AppText.heading(20),
                      ),
                    ),
                    BouncyButton(
                      onTap: () => Sfx.I.speak(_q.en),
                      child: const Icon(Icons.volume_up_rounded, size: 30, color: Color(0xFF4361EE)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                  itemCount: 4,
                  itemBuilder: (context, i) {
                    final opt = _options[_q]![i];
                    Color? bg;
                    if (_picked != null) {
                      if (opt == _q.en) {
                        bg = AppColors.correct;
                      } else if (i == _picked) {
                        bg = AppColors.wrong;
                      }
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PillButton(
                        label: opt,
                        emoji: ['🅰', '🅱', '🅲', '🅳'][i],
                        color: bg ?? const Color(0xFF4361EE),
                        fontSize: 20,
                        onTap: _locked ? null : () => _answer(i),
                      ),
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
