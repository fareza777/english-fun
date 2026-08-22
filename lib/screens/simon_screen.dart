import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/adventures.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/funky.dart';
import 'result_screen.dart';

/// "Simon Says" — follow the command ONLY when Simon says so (TPR method).
class SimonScreen extends StatefulWidget {
  const SimonScreen({super.key});

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

class _SimonScreenState extends State<SimonScreen> {
  static const _rounds = 10;
  final _rnd = math.Random();
  int _index = 0;
  int _score = 0;
  late (String, String) _command;
  late List<String> _options;
  late bool _simonSaid;
  bool _locked = false;
  int? _picked;
  Timer? _trickTimer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _command = kSimonCommands[_rnd.nextInt(kSimonCommands.length)];
    _simonSaid = _rnd.nextDouble() < 0.75;
    final others = kSimonCommands.where((c) => c.$2 != _command.$2).toList()..shuffle(_rnd);
    _options = [_command.$2, ...others.take(3).map((c) => c.$2)]..shuffle(_rnd);
    _locked = false;
    _picked = null;
    final said = _simonSaid ? 'Simon says: ${_command.$1}' : _command.$1;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && !_done) Sfx.I.speak(said);
    });
    if (!_simonSaid) {
      // trick round: surviving 2.8s without tapping = correct
      _trickTimer?.cancel();
      _trickTimer = Timer(const Duration(milliseconds: 2800), () {
        if (!mounted || _locked || _done) return;
        _locked = true;
        _score++;
        Sfx.I.ding();
        Sfx.I.speak('Simon did not say! Good job!');
        _next();
      });
    }
  }

  void _tap(int i) {
    if (_locked || _done) return;
    setState(() => _picked = i);
    if (!_simonSaid) {
      // trick round: any tap loses the round
      _trickTimer?.cancel();
      _locked = true;
      Sfx.I.wrong();
      Sfx.I.speak('Simon did not say that!');
      _next();
      return;
    }
    if (_options[i] == _command.$2) {
      _locked = true;
      _score++;
      Sfx.I.ding();
      Sfx.I.praise();
      _next();
    } else {
      Sfx.I.wrong();
    }
  }

  void _next() {
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted || _done) return;
      if (_index + 1 >= _rounds) {
        _finish();
      } else {
        setState(() => _index++);
        _newRound();
      }
    });
  }

  void _finish() {
    _done = true;
    _trickTimer?.cancel();
    final stars = _score >= 9 ? 3 : (_score >= 6 ? 2 : (_score >= 3 ? 1 : 0));
    Progress.I.addCoins(_score * 2);
    Navigator.of(context).pushReplacement(
      funRoute(
        ResultScreen(
          title: 'Simon Says',
          stars: stars,
          correct: _score,
          total: _rounds,
          retryBuilder: () => const SimonScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _trickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        world: 4,
        child: SafeArea(
          child: Column(
            children: [
              KidAppBar(
                title: 'Simon Says',
                emoji: '🧍',
                colors: const [],
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text('${_index + 1}/$_rounds', style: AppText.heading(18)),
                ),
              ),
              const SizedBox(height: 6),
              const FunkyMascot(size: 84),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_simonSaid)
                        Text('SIMON BERKATA:', style: AppText.heading(15, color: AppColors.correct))
                      else
                        Text(
                          '🤫 tanpa "Simon says"...',
                          style: AppText.heading(15, color: AppColors.wrong),
                        ),
                      const SizedBox(height: 4),
                      Text(_command.$1, textAlign: TextAlign.center, style: AppText.heading(26)),
                      BouncyButton(
                        onTap: () =>
                            Sfx.I.speak(_simonSaid ? 'Simon says: ${_command.$1}' : _command.$1),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.volume_up_rounded, color: Color(0xFF4361EE), size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _simonSaid ? 'Lakukan perintahnya!' : 'JANGAN disentuh! Tunggu...',
                style: AppText.body(17, color: Colors.white),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(22),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.25,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < _options.length; i++)
                      BouncyButton(
                        onTap: () => _tap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _picked == i
                                ? (_simonSaid && _options[i] == _command.$2
                                      ? AppColors.correct
                                      : AppColors.wrong)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(_options[i], style: const TextStyle(fontSize: 56)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
