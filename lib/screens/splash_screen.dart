import 'package:flutter/material.dart';

import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () => Sfx.I.fanfare());
    Future.delayed(const Duration(milliseconds: 2400), _go);
  }

  void _go() {
    if (!mounted) return;
    // Onboarding can be finished without entering a name, so the explicit
    // flag is what decides, not the presence of a name.
    final done = Progress.I.onboarded || Progress.I.playerName.isNotEmpty;
    Navigator.of(
      context,
    ).pushReplacement(funRoute(done ? const HomeScreen() : const OnboardingScreen()));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _c,
                  curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
                ),
                child: const Mascot(size: 130),
              ),
              const SizedBox(height: 18),
              // The per-letter row is laid out at its natural width, which is
              // wider than a narrow phone. Scale it down instead of clipping.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _StaggeredText(
                    text: 'English Fun',
                    controller: _c,
                    start: 0.25,
                    style: AppText.display(52, color: AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: CurvedAnimation(parent: _c, curve: const Interval(0.7, 1.0)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sun,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Color(0x44B26A00), offset: Offset(0, 4))],
                  ),
                  child: Text('ADVENTURE', style: AppText.heading(20, color: AppColors.ink)),
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: CurvedAnimation(parent: _c, curve: const Interval(0.8, 1.0)),
                child: Text('Kelas 1 - 6 SD', style: AppText.body(20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggeredText extends StatelessWidget {
  final String text;
  final AnimationController controller;
  final double start;
  final TextStyle style;
  const _StaggeredText({
    required this.text,
    required this.controller,
    required this.start,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final letters = text.split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(letters.length, (i) {
        final s = start + (i / letters.length) * 0.4;
        final anim = CurvedAnimation(
          parent: controller,
          curve: Interval(s, s + 0.25, curve: Curves.elasticOut),
        );
        return ScaleTransition(
          scale: anim,
          child: Text(letters[i], style: style),
        );
      }),
    );
  }
}
