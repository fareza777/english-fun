import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// "Susun Kalimat" — arrange shuffled words into the correct English sentence.
/// Uses the grammar unit's own example sentences and challenge solutions.
class BuildScreen extends StatefulWidget {
  final Unit unit;
  const BuildScreen({super.key, required this.unit});

  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildSentence {
  final String hint; // Indonesian meaning or the fill-in prompt
  final String sentence;
  const _BuildSentence(this.hint, this.sentence);
  List<String> get words => sentence.split(' ');
}

class _BuildScreenState extends State<BuildScreen> {
  late final List<_BuildSentence> _sentences;
  int _index = 0;
  late List<String> _pool;
  final List<String> _built = [];
  int _firstTry = 0;
  bool _messed = false;
  bool _locked = false;
  bool _done = false;

  _BuildSentence get _s => _sentences[_index];

  @override
  void initState() {
    super.initState();
    final all = <_BuildSentence>[];
    for (final p in widget.unit.pages) {
      for (final e in p.examples) {
        all.add(_BuildSentence(e.idn, e.en));
      }
      for (final c in p.challenges) {
        all.add(_BuildSentence(c.prompt, c.full));
      }
    }
    final seen = <String>{};
    all.retainWhere((s) {
      final wc = s.words.length;
      return wc >= 3 && wc <= 8 && seen.add(s.sentence);
    });
    all.shuffle(math.Random());
    _sentences = all.take(math.min(6, all.length)).toList();
    _loadSentence();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Sfx.I.speak(_s.sentence);
    });
  }

  void _loadSentence() {
    final words = List<String>.from(_s.words);
    // guarantee the pool is actually shuffled
    var tries = 0;
    do {
      words.shuffle(math.Random());
      tries++;
    } while (_listEquals(words, _s.words) && tries < 10);
    _pool = words;
    _built.clear();
    _messed = false;
    _locked = false;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _tapPool(int i) {
    if (_locked) return;
    Sfx.I.click();
    setState(() => _built.add(_pool.removeAt(i)));
    if (_pool.isEmpty) _check();
  }

  void _tapBuilt(int i) {
    if (_locked) return;
    Sfx.I.flip();
    setState(() => _pool.add(_built.removeAt(i)));
  }

  void _check() {
    final attempt = _built.join(' ');
    if (attempt == _s.sentence) {
      _locked = true;
      if (!_messed) _firstTry++;
      Sfx.I.ding();
      Sfx.I.speak(_s.sentence);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (_index + 1 >= _sentences.length) {
          _finish();
        } else {
          setState(() {
            _index++;
            _loadSentence();
          });
          Sfx.I.speak(_s.sentence);
        }
      });
    } else {
      _messed = true;
      Sfx.I.wrong();
      // bounce the built words back so the kid can rearrange
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_locked) setState(() {});
      });
    }
  }

  void _finish() {
    _done = true;
    final total = _sentences.length;
    final stars = (_firstTry / total * 3).round().clamp(0, 3);
    Progress.I.setStars(widget.unit.id, 'build', stars);
    Navigator.of(context).pushReplacement(funRoute(ResultScreen(
      title: widget.unit.title,
      stars: stars,
      correct: _firstTry,
      total: total,
      retryBuilder: () => BuildScreen(unit: widget.unit),
    )));
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const Scaffold(body: SizedBox.shrink());
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              KidAppBar(
                title: 'Susun Kalimat',
                emoji: '🧩',
                colors: const [],
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration:
                      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Text('${_index + 1}/${_sentences.length}', style: AppText.heading(18)),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('Susun jadi kalimat:', style: AppText.body(15)),
                      const SizedBox(height: 4),
                      Text(_s.hint, textAlign: TextAlign.center, style: AppText.heading(22)),
                      BouncyButton(
                        onTap: () => Sfx.I.speak(_s.sentence),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.volume_up_rounded, color: Color(0xFF4361EE), size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // answer slots
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 84),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _built.length; i++)
                        BouncyButton(
                          onTap: () => _tapBuilt(i),
                          child: _wordChip(_built[i], const Color(0xFF43AA8B)),
                        ),
                      if (_built.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text('...', style: AppText.body(22, color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // word pool
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < _pool.length; i++)
                        BouncyButton(
                          onTap: () => _tapPool(i),
                          child: _wordChip(_pool[i], const Color(0xFF4361EE)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wordChip(String word, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), offset: const Offset(0, 4))],
      ),
      child: Text(word, style: AppText.display(20)),
    );
  }
}
