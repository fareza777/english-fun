import 'package:flutter/material.dart';

import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Flashcard learning: big picture, big word, TTS pronunciation, 3D flip.
class LearnScreen extends StatefulWidget {
  final Unit unit;
  const LearnScreen({super.key, required this.unit});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final PageController _pc = PageController();
  final ConfettiController _confetti = ConfettiController();
  int _page = 0;
  bool _flipped = false;
  bool _finished = false;

  List<VocabItem> get items => widget.unit.items;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () => _speakCurrent());
  }

  @override
  void dispose() {
    _pc.dispose();
    _confetti.dispose();
    Sfx.I.stopSpeak();
    super.dispose();
  }

  void _speakCurrent() {
    final item = items[_page];
    Sfx.I.speak(_flipped ? (item.sentence ?? item.en) : item.en);
  }

  void _goTo(int page) {
    if (page < 0 || page >= items.length) return;
    Sfx.I.flip();
    _pc.animateToPage(page, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    await Progress.I.setStars(widget.unit.id, 'learn', 1);
    _confetti.burst();
    Sfx.I.win();
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FinishDialog(unitTitle: widget.unit.title),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == items.length - 1;
    return Scaffold(
      body: AnimatedBackground(
        child: Stack(
          children: [
            Column(
              children: [
                KidAppBar(title: widget.unit.title, emoji: widget.unit.emoji, colors: const []),
                Expanded(
                  child: PageView.builder(
                    controller: _pc,
                    itemCount: items.length,
                    onPageChanged: (i) {
                      setState(() {
                        _page = i;
                        _flipped = false;
                      });
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted && _page == i && !_flipped) Sfx.I.speak(items[i].en);
                      });
                    },
                    itemBuilder: (context, i) {
                      final it = items[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
                        child: BouncyButton(
                          sound: false,
                          onTap: () {
                            setState(() => _flipped = !_flipped);
                            Sfx.I.flip();
                            Future.delayed(const Duration(milliseconds: 250), _speakCurrent);
                          },
                          child: FlipCard(
                            showBack: _flipped && i == _page,
                            front: _CardFace(item: it, back: false),
                            back: _CardFace(item: it, back: true),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Text('Ketuk kartu untuk membalik 🔄',
                      style: AppText.body(15, color: AppColors.inkSoft.withOpacity(0.8))),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                    child: Row(
                      children: [
                        _ArrowButton(
                          icon: Icons.arrow_back_rounded,
                          enabled: _page > 0,
                          onTap: () => _goTo(_page - 1),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            children: [
                              Text('${_page + 1} / ${items.length}', style: AppText.heading(22)),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (_page + 1) / items.length,
                                  minHeight: 12,
                                  backgroundColor: Colors.white.withOpacity(0.6),
                                  valueColor: const AlwaysStoppedAnimation(AppColors.correct),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        if (isLast)
                          PillButton(
                            label: 'Selesai!',
                            emoji: '🎉',
                            color: AppColors.correct,
                            fontSize: 20,
                            onTap: _finish,
                          )
                        else
                          _ArrowButton(
                            icon: Icons.arrow_forward_rounded,
                            enabled: true,
                            onTap: () => _goTo(_page + 1),
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

class _CardFace extends StatelessWidget {
  final VocabItem item;
  final bool back;
  const _CardFace({required this.item, required this.back});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: back ? const Color(0xFFC77DFF) : const Color(0xFF7ED6FF), width: 5),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: back ? _backContent() : _frontContent(),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: BouncyButton(
              sound: false,
              onTap: () {
                Sfx.I.pop();
                Sfx.I.speak(back ? (item.sentence ?? item.en) : item.en);
              },
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.sun,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Color(0x55B26A00), offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.volume_up_rounded, size: 34, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _frontContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (item.big != null) ...[
          Text(item.big!, style: AppText.heading(54, color: const Color(0xFF4361EE))),
          const SizedBox(height: 4),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(item.emoji, style: const TextStyle(fontSize: 120)),
          ),
        ),
        const SizedBox(height: 10),
        Text(item.en, textAlign: TextAlign.center, style: AppText.heading(44)),
      ],
    );
  }

  Widget _backContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(item.emoji, style: const TextStyle(fontSize: 90)),
          ),
        ),
        const SizedBox(height: 8),
        Text(item.idn, textAlign: TextAlign.center, style: AppText.heading(38, color: const Color(0xFF9B5DE5))),
        if (item.sentence != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              item.sentence!,
              textAlign: TextAlign.center,
              style: AppText.body(20, color: AppColors.ink),
            ),
          ),
        ],
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Icon(icon, size: 34, color: enabled ? AppColors.ink : Colors.grey),
      ),
    );
  }
}

class _FinishDialog extends StatelessWidget {
  final String unitTitle;
  const _FinishDialog({required this.unitTitle});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 80, greeting: 'Great job! You did it!'),
            const SizedBox(height: 8),
            Text('Hebat! 🎉', style: AppText.heading(34)),
            const SizedBox(height: 6),
            Text(
              'Kamu menyelesaikan $unitTitle!\nSekarang coba permainannya, yuk!',
              textAlign: TextAlign.center,
              style: AppText.body(18),
            ),
            const SizedBox(height: 18),
            PillButton(
              label: 'Oke!',
              emoji: '💪',
              color: AppColors.correct,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
