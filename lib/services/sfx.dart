import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

/// Central sound service: studio voice-over (with device-TTS fallback)
/// + playful sound effects.
class Sfx {
  Sfx._();
  static final Sfx I = Sfx._();

  final FlutterTts _tts = FlutterTts();
  final List<AudioPlayer> _pool = [];

  /// Dedicated player for studio voice-overs. Created lazily in [init]
  /// because constructing AudioPlayer touches platform channels (tests).
  AudioPlayer? _voicePlayer;

  /// md5 ids of texts that have a studio voice-over mp3 bundled.
  final Set<String> _voiceIds = {};
  int _idx = 0;
  bool _ready = false;
  bool ttsEnabled = true;
  bool sfxEnabled = true;

  /// When true, all audio is skipped (used in tests / headless environments).
  bool muted = false;

  /// Debug info: which TTS voice got selected (shown nowhere, useful in logs).
  String selectedVoice = 'default';

  /// How many studio voice-over files are available.
  int get voiceOverCount => _voiceIds.length;

  static String voiceId(String text) => md5.convert(utf8.encode(text.trim())).toString();

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.setSpeechRate(0.42); // slow & clear, like a patient teacher
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.setQueueMode(1); // flush: newest utterance replaces old
      await _tts.awaitSpeakCompletion(false);
      // Baseline first: guarantee English even if voice picking fails.
      await _setEnglishLanguage();
      await _pickBestVoice();
    } catch (_) {}
    try {
      _voicePlayer = AudioPlayer();
      await _voicePlayer!.setReleaseMode(ReleaseMode.stop);
    } catch (_) {
      _voicePlayer = null;
    }
    await _loadVoiceManifest();
    for (var i = 0; i < 4; i++) {
      final p = AudioPlayer();
      try {
        await p.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
      _pool.add(p);
    }
  }

  /// Loads the list of available studio voice-overs generated at build time.
  Future<void> _loadVoiceManifest() async {
    try {
      final raw = await rootBundle.loadString('assets/voice/manifest.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['items'] is List) {
        for (final it in decoded['items'] as List) {
          if (it is Map && it['id'] is String) _voiceIds.add(it['id'] as String);
        }
      }
    } catch (_) {}
  }

  Future<void> _setEnglishLanguage() async {
    for (final lang in ['en-US', 'en-GB', 'en']) {
      try {
        final available = await _tts.isLanguageAvailable(lang);
        if (available == true || available == 1) {
          await _tts.setLanguage(lang);
          return;
        }
      } catch (_) {}
    }
    try {
      await _tts.setLanguage('en-US');
    } catch (_) {}
  }

  /// Pick the highest-quality English voice installed on the device
  /// (prefers en-US network/neural voices from Google Speech Services).
  Future<void> _pickBestVoice() async {
    try {
      final dynamic raw = await _tts.getVoices;
      if (raw is! List) return;
      final voices = raw
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry('$k', '$v')))
          .where((v) =>
              (v['locale'] ?? '').replaceAll('_', '-').toLowerCase().startsWith('en'))
          .toList();
      if (voices.isEmpty) return;
      final us = voices
          .where((v) =>
              (v['locale'] ?? '').replaceAll('_', '-').toLowerCase().startsWith('en-us'))
          .toList();
      final pool = us.isNotEmpty ? us : voices;
      pool.sort((a, b) => _voiceScore(b).compareTo(_voiceScore(a)));
      final best = pool.first;
      await _tts.setVoice({'name': best['name']!, 'locale': best['locale']!});
      selectedVoice = '${best['name']} (${best['locale']})';
    } catch (_) {}
  }

  int _voiceScore(Map<String, String> v) {
    final name = (v['name'] ?? '').toLowerCase();
    var s = 0;
    if (name.contains('neural')) s += 4;
    if (name.contains('network')) s += 3; // server-grade Google voice
    if (name.contains('high') || name.contains('hd')) s += 2;
    if (name.contains('local')) s += 1; // on-device fallback still fine
    return s;
  }

  static const List<String> praises = [
    'Great job!',
    'Awesome!',
    'You are amazing!',
    'Super!',
    'Fantastic!',
    'Well done!',
    'You are a superstar!',
    'Excellent!',
  ];

  /// Speak a random English praise phrase.
  void praise() => speak(praises[math.Random().nextInt(praises.length)]);

  /// Speak English text: studio voice-over when available, device TTS otherwise.
  Future<void> speak(String text) async {
    if (muted || !ttsEnabled) return;
    final player = _voicePlayer;
    final id = voiceId(text);
    if (player != null && _voiceIds.contains(id)) {
      try {
        await _tts.stop();
        await player.stop();
        await player.play(AssetSource('voice/$id.mp3'), volume: 1.0);
        return;
      } catch (_) {}
      // fall through to TTS if the file is missing for any reason
    }
    try {
      await player?.stop();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stopSpeak() async {
    try {
      await _tts.stop();
      await _voicePlayer?.stop();
    } catch (_) {}
  }

  void _play(String file, [double volume = 0.85]) {
    if (muted || !sfxEnabled || _pool.isEmpty) return;
    final p = _pool[_idx++ % _pool.length];
    try {
      p.stop();
      p.play(AssetSource('sfx/$file'), volume: volume);
    } catch (_) {}
  }

  void click() => _play('click.wav', 0.6);
  void pop() => _play('pop.wav', 0.7);
  void flip() => _play('flip.wav', 0.45);
  void ding() => _play('ding.wav', 0.9);
  void wrong() => _play('wrong.wav', 0.6);
  void star() => _play('star.wav', 0.9);
  void fanfare() => _play('fanfare.wav', 0.85);
  void win() => _play('win.wav', 0.9);
}
