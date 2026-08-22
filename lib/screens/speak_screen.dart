import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models.dart';
import '../services/lesson_builder.dart';
import '../services/text_similarity.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/funky.dart';
import 'result_screen.dart';

/// "Ucapkan!" — kids say the English word out loud and the app checks
/// their pronunciation with on-device speech recognition.
class SpeakScreen extends StatefulWidget {
  final Unit unit;
  final List<Color> colors;
  const SpeakScreen({super.key, required this.unit, required this.colors});

  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> {
  static const _rounds = 6;
  final SpeechToText _speech = SpeechToText();
  late final List<VocabItem> _words;
  int _index = 0;
  int _score = 0;
  int _tries = 0;
  bool? _available; // null = still initializing
  bool _listening = false;
  String _heard = '';
  bool _done = false;

  VocabItem get _word => _words[_index];

  @override
  void initState() {
    super.initState();
    _words = LessonBuilder.pickItems(widget.unit.items, _rounds);
    _initSpeech();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Sfx.I.speak('Say it! ${_word.en}');
    });
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize();
      if (mounted) setState(() => _available = ok);
    } catch (_) {
      if (mounted) setState(() => _available = false);
    }
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
    });
    Sfx.I.pop();
    try {
      await _speech.listen(
        onResult: (r) {
          if (!mounted) return;
          setState(() => _heard = r.recognizedWords);
          if (r.finalResult) _evaluate(r.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          localeId: 'en_US',
          listenFor: const Duration(seconds: 6),
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _listening = false);
    }
    // safety: auto-evaluate whatever we heard after 7s
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted && _listening) _evaluate(_heard);
    });
  }

  Future<void> _evaluate(String heard) async {
    if (!_listening) return;
    try {
      await _speech.stop();
    } catch (_) {}
    setState(() => _listening = false);
    if (TextSimilarity.soundsLike(heard, _word.en)) {
      _score++;
      Progress.I.recordCorrect(_word.en);
      Sfx.I.ding();
      Sfx.I.praise();
      _next();
    } else {
      _tries++;
      Progress.I.recordWrong(_word.en);
      if (_tries >= 2) {
        Sfx.I.wrong();
        Sfx.I.speak('It is ${_word.en}');
        _next();
      } else {
        Sfx.I.flip();
        Sfx.I.speak('Try again! ${_word.en}');
      }
    }
  }

  void _next() {
    _tries = 0;
    _heard = '';
    if (_index + 1 >= _words.length) {
      _finish();
    } else {
      setState(() => _index++);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && !_done) Sfx.I.speak('Say it! ${_word.en}');
      });
    }
  }

  void _finish() {
    _done = true;
    final total = _words.length;
    final stars = (_score / total * 3).round().clamp(0, 3);
    Progress.I.setStars(widget.unit.id, 'speak', stars);
    Navigator.of(context).pushReplacement(
      funRoute(
        ResultScreen(
          title: widget.unit.title,
          stars: stars,
          correct: _score,
          total: total,
          retryBuilder: () => SpeakScreen(unit: widget.unit, colors: widget.colors),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        colors: widget.colors,
        child: SafeArea(child: _available == false ? _unavailable() : _game()),
      ),
    );
  }

  Widget _unavailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎤😢', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Maaf, fitur pengenal suara tidak tersedia di perangkat ini. Coba game lainnya, ya!',
              textAlign: TextAlign.center,
              style: AppText.body(18, color: Colors.white),
            ),
            const SizedBox(height: 20),
            PillButton(
              label: 'Kembali',
              emoji: '🔙',
              color: AppColors.correct,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _game() {
    return Column(
      children: [
        KidAppBar(
          title: 'Ucapkan!',
          emoji: '🎤',
          colors: widget.colors,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Text('${_index + 1}/${_words.length}', style: AppText.heading(18)),
          ),
        ),
        const SizedBox(height: 8),
        const FunkyMascot(size: 78),
        const SizedBox(height: 6),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_word.emoji, style: const TextStyle(fontSize: 84)),
                  const SizedBox(height: 8),
                  Text(_word.en, style: AppText.heading(40)),
                  Text(_word.idn, style: AppText.body(20, color: AppColors.inkSoft)),
                  const SizedBox(height: 10),
                  BouncyButton(
                    onTap: () => Sfx.I.speak(_word.en),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_up_rounded, color: Color(0xFF4361EE)),
                          const SizedBox(width: 6),
                          Text(
                            'Dengar',
                            style: AppText.heading(16, color: const Color(0xFF4361EE)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_heard.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Kamu bilang: "$_heard"',
              textAlign: TextAlign.center,
              style: AppText.body(16, color: Colors.white),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 26),
          child: BouncyButton(
            sound: false,
            onTap: _available == true ? _toggleListen : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _listening ? AppColors.wrong : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: (_listening ? AppColors.wrong : Colors.black).withValues(alpha: 0.3),
                    blurRadius: _listening ? 24 : 10,
                    spreadRadius: _listening ? 4 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 48,
                color: _listening ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
        Text(
          _listening ? 'Mendengarkan... ucapkan kata di atas!' : 'Tekan mikrofon, lalu ucapkan!',
          style: AppText.body(16, color: Colors.white),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
