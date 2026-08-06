import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

/// First-launch screen: Funky asks the kid's name.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      Sfx.I.speak("Hello! I'm Funky! What's your name?");
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _name.text.trim();
    if (name.isNotEmpty) {
      await Progress.I.setName(name);
      Sfx.I.speak('Hello, $name! Welcome to English Fun!');
    }
    Sfx.I.fanfare();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(funRoute(const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Mascot(size: 120),
                  const SizedBox(height: 14),
                  Text('Halo! Aku Funky! 🦊', style: AppText.heading(30)),
                  const SizedBox(height: 6),
                  Text('Siapa namamu?', style: AppText.body(22)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF7ED6FF), width: 4),
                      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: TextField(
                      controller: _name,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 14,
                      style: AppText.heading(28),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]"))],
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'Tulis namamu di sini',
                        hintStyle: AppText.body(20, color: Colors.grey.shade400),
                      ),
                      onSubmitted: (_) => _start(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PillButton(
                    label: 'Mulai Petualangan!',
                    emoji: '🚀',
                    color: AppColors.correct,
                    fontSize: 22,
                    onTap: _start,
                  ),
                  const SizedBox(height: 12),
                  BouncyButton(
                    onTap: _start,
                    child: Text('Lewati dulu', style: AppText.body(16, color: AppColors.inkSoft.withOpacity(0.7))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
