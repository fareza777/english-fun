import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/stickers.dart';
import '../services/monetization.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/common.dart';

/// Celebration screen after finishing a game: animated stars + confetti.
class ResultScreen extends StatefulWidget {
  final String title;
  final int stars;
  final int correct;
  final int total;
  final Widget Function() retryBuilder;
  const ResultScreen({
    super.key,
    required this.title,
    required this.stars,
    required this.correct,
    required this.total,
    required this.retryBuilder,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..forward();
  final ConfettiController _confetti = ConfettiController();
  (String, String)? _newSticker;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    Progress.I.countGame(); // daily goal + parent stats
    MonetizationService.I.preloadInterstitial();
    _awardSticker();
    for (var i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 500 + i * 450), () {
        if (mounted) Sfx.I.star();
      });
    }
    Future.delayed(Duration(milliseconds: 600 + widget.stars * 450), () {
      if (!mounted) return;
      if (widget.stars >= 2) {
        Sfx.I.win();
        _confetti.burst();
      } else {
        Sfx.I.fanfare();
      }
    });
    Future.delayed(Duration(milliseconds: 1700 + widget.stars * 450), () {
      if (mounted) Sfx.I.praise();
    });
  }

  /// Celebration first; interstitial only when leaving, and only if the
  /// child-safe frequency gate is open.
  Future<void> _leave(VoidCallback go) async {
    if (_leaving) return;
    _leaving = true;
    try {
      await MonetizationService.I.showInterstitialIfEligible(
        gamesTotal: Progress.I.gamesTotal,
      );
    } catch (_) {}
    if (!mounted) return;
    go();
  }

  /// 2+ stars earns a random new sticker from the collection pool.
  void _awardSticker() {
    if (widget.stars < 2) return;
    final unearned = kStickers
        .where((s) => !Progress.I.stickers.contains(s.$1))
        .toList();
    if (unearned.isEmpty) return;
    final pick = unearned[math.Random().nextInt(unearned.length)];
    if (Progress.I.awardSticker(pick.$1)) {
      _newSticker = pick;
      Future.delayed(Duration(milliseconds: 900 + widget.stars * 450), () {
        if (mounted) Sfx.I.star();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _confetti.dispose();
    super.dispose();
  }

  String get _message {
    if (widget.stars >= 3) return 'LUAR BIASA! 🏆';
    if (widget.stars == 2) return 'Hebat! 🎉';
    return 'Bagus! Ayo terus berlatih! 💪';
  }

  String get _greeting {
    if (widget.stars >= 3) return 'Amazing! You are a superstar!';
    if (widget.stars == 2) return 'Great job! Keep it up!';
    return 'Good try! Practice makes perfect!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Mascot(size: 90, greeting: _greeting),
                            const SizedBox(height: 10),
                            Text(widget.title, style: AppText.heading(26)),
                            const SizedBox(height: 6),
                            Text(
                              _message,
                              style: AppText.display(34, color: AppColors.ink),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                final earned = i < widget.stars;
                                final start = 0.2 + i * 0.22;
                                final anim = CurvedAnimation(
                                  parent: _c,
                                  curve: Interval(
                                    start,
                                    start + 0.3,
                                    curve: Curves.elasticOut,
                                  ),
                                );
                                return ScaleTransition(
                                  scale: earned
                                      ? anim
                                      : const AlwaysStoppedAnimation(1.0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: i == 1 ? 96 : 76,
                                      color: earned
                                          ? AppColors.star
                                          : Colors.white.withValues(alpha: 0.6),
                                      shadows: earned
                                          ? const [
                                              Shadow(
                                                color: Color(0x88B26A00),
                                                blurRadius: 10,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Benar ${widget.correct} dari ${widget.total}',
                                style: AppText.heading(22),
                              ),
                            ),
                            if (_newSticker != null) ...[
                              const SizedBox(height: 16),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) =>
                                    Transform.scale(scale: value, child: child),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3D6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.star,
                                      width: 3,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '🎁',
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Stiker Baru!  ',
                                        style: AppText.heading(18),
                                      ),
                                      Text(
                                        _newSticker!.$1,
                                        style: const TextStyle(fontSize: 34),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _newSticker!.$2,
                                        style: AppText.body(17),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 26),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PillButton(
                                  label: 'Main Lagi',
                                  emoji: '🔁',
                                  color: const Color(0xFF4361EE),
                                  fontSize: 20,
                                  onTap: () => unawaited(
                                    _leave(
                                      () => Navigator.of(context).pushReplacement(
                                        funRoute(widget.retryBuilder()),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                PillButton(
                                  label: 'Selesai',
                                  emoji: '🏠',
                                  color: AppColors.correct,
                                  fontSize: 20,
                                  onTap: () => unawaited(
                                    _leave(() => Navigator.of(context).pop()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const ResultMrecAd(),
                ],
              ),
            ),
            Positioned.fill(child: ConfettiOverlay(controller: _confetti)),
          ],
        ),
      ),
    );
  }
}
