import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

class _MCard {
  final VocabItem item;
  final bool isWord;
  bool flipped = false;
  bool matched = false;
  _MCard(this.item, this.isWord);
}

/// Memory match: pair the picture card with its English word.
class MemoryScreen extends StatefulWidget {
  final Unit unit;
  const MemoryScreen({super.key, required this.unit});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  late final List<_MCard> _cards;
  final ConfettiController _confetti = ConfettiController();
  int? _first;
  bool _lock = false;
  int _moves = 0;
  int _matchedPairs = 0;
  static const _pairs = 6;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    final items = List<VocabItem>.of(widget.unit.items)..shuffle(rnd);
    final picked = items.take(math.min(_pairs, items.length)).toList();
    _cards = [
      for (final it in picked) ...[_MCard(it, false), _MCard(it, true)],
    ]..shuffle(rnd);
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _tap(int i) async {
    if (_lock) return;
    final card = _cards[i];
    if (card.flipped || card.matched) return;
    Sfx.I.flip();
    setState(() => card.flipped = true);
    if (_first == null) {
      _first = i;
      return;
    }
    _moves++;
    final firstCard = _cards[_first!];
    if (firstCard.item == card.item && firstCard.isWord != card.isWord) {
      firstCard.matched = true;
      card.matched = true;
      _matchedPairs++;
      _first = null;
      Sfx.I.ding();
      Sfx.I.speak(card.item.en);
      if (_matchedPairs == _cards.length ~/ 2) {
        _finish();
      }
    } else {
      _lock = true;
      final a = _first!;
      _first = null;
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      setState(() {
        _cards[a].flipped = false;
        _cards[i].flipped = false;
        _lock = false;
      });
      Sfx.I.pop();
    }
  }

  Future<void> _finish() async {
    final stars = _moves <= 9 ? 3 : (_moves <= 14 ? 2 : 1);
    await Progress.I.setStars(widget.unit.id, 'memory', stars);
    _confetti.burst();
    Sfx.I.win();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(funRoute(ResultScreen(
      title: 'Memory Match',
      stars: stars,
      correct: _matchedPairs,
      total: _cards.length ~/ 2,
      retryBuilder: () => MemoryScreen(unit: widget.unit),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Stack(
          children: [
            Column(
              children: [
                KidAppBar(title: 'Memory Match', emoji: '🃏', colors: const []),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pasangan: $_matchedPairs/${_cards.length ~/ 2}', style: AppText.heading(20)),
                      Text('Langkah: $_moves', style: AppText.heading(20)),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, i) => _cardWidget(i),
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

  Widget _cardWidget(int i) {
    final card = _cards[i];
    return BouncyButton(
      sound: false,
      onTap: () => _tap(i),
      child: FlipCard(
        showBack: card.flipped || card.matched,
        front: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4361EE), Color(0xFF4CC9F0)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x334361EE), offset: Offset(0, 5))],
          ),
          alignment: Alignment.center,
          child: const Text('❓', style: TextStyle(fontSize: 36)),
        ),
        back: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: card.matched ? const Color(0xFFD8F5DC) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: card.matched ? AppColors.correct : const Color(0xFF7ED6FF),
              width: 3,
            ),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: card.isWord
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    card.item.en,
                    textAlign: TextAlign.center,
                    style: AppText.heading(20, color: const Color(0xFF4361EE)),
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(card.item.emoji, style: const TextStyle(fontSize: 44)),
                ),
        ),
      ),
    );
  }
}
