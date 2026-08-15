import 'package:flutter/material.dart';

import '../data/content.dart';
import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ad_banner.dart';
import 'arcade_screen.dart';
import 'parents_screen.dart';
import 'pets_screen.dart';
import 'shop_screen.dart';
import 'spin_screen.dart';
import 'sticker_book.dart';
import 'units_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ListenableBuilder(
                      listenable: Progress.I,
                      builder: (context, _) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Mascot(size: 72),
                          if (Progress.I.activePet.isNotEmpty)
                            Positioned(
                              right: -12,
                              bottom: -6,
                              child: Text(Progress.I.activePet,
                                  style: const TextStyle(fontSize: 32)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SpeechBubble(
                        text:
                            'Halo${Progress.I.playerName.isNotEmpty ? ', ${Progress.I.playerName}' : ''}! Pilih kelasmu, yuk! 🎒',
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SoundToggle(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('English Fun Adventure', style: AppText.heading(26)),
                    const SizedBox(height: 8),
                    ListenableBuilder(
                      listenable: Progress.I,
                      builder: (context, _) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _InfoChip(emoji: '⭐', label: '${Progress.I.totalStars}'),
                            const SizedBox(width: 8),
                            _InfoChip(
                              emoji: '🪙',
                              label: '${Progress.I.coins}',
                              onTap: () => Navigator.of(context).push(funRoute(const ShopScreen())),
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(emoji: '🔥', label: '${Progress.I.streak} hari'),
                            const SizedBox(width: 8),
                            _InfoChip(
                              emoji: Progress.I.dailyGoalReached ? '✅' : '🎯',
                              label:
                                  '${Progress.I.gamesToday}/${Progress.I.dailyGoal}${Progress.I.dailyGoalReached ? ' 🎉' : ''}',
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              emoji: '🎒',
                              label: 'Stiker ${Progress.I.stickers.length}',
                              onTap: () => Navigator.of(context).push(funRoute(const StickerBookScreen())),
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              emoji: '🥚',
                              label: 'Peliharaan ${Progress.I.pets.length}',
                              onTap: () => Navigator.of(context).push(funRoute(const PetsScreen())),
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              emoji: '🎡',
                              label: Progress.I.canSpinToday ? 'Putar!' : 'Besok',
                              onTap: () => Navigator.of(context).push(funRoute(const SpinScreen())),
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              emoji: '📊',
                              label: 'Orang Tua',
                              onTap: () => Navigator.of(context).push(funRoute(const ParentsScreen())),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Arcade banner
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
                child: BouncyButton(
                  onTap: () => Navigator.of(context).push(funRoute(const ArcadeScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7B61FF), Color(0xFFC77DFF)]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x557B61FF), offset: Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        const Text('🕹️', style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Arena Arcade', style: AppText.display(22)),
                              Text(
                                'Balon Pop • Tangkap Kata • Lari Kata • Simon Says • Cerita',
                                style: AppText.body(12, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: Progress.I,
                  builder: (context, _) => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: kGrades.length,
                    itemBuilder: (context, i) => _GradeCard(grade: kGrades[i]),
                  ),
                ),
              ),
              const AdBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback? onTap;
  const _InfoChip({required this.emoji, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 5),
            Text(label, style: AppText.heading(17)),
          ],
        ),
      ),
    );
  }
}

class _SoundToggle extends StatefulWidget {
  @override
  State<_SoundToggle> createState() => _SoundToggleState();
}

class _SoundToggleState extends State<_SoundToggle> {
  @override
  Widget build(BuildContext context) {
    final on = Sfx.I.ttsEnabled;
    return BouncyButton(
      sound: false,
      onTap: () {
        setState(() {
          Sfx.I.ttsEnabled = !on;
          Sfx.I.sfxEnabled = !on;
        });
        if (!on) Sfx.I.pop();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Icon(on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: on ? AppColors.ink : Colors.grey, size: 26),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final Grade grade;
  const _GradeCard({required this.grade});

  @override
  Widget build(BuildContext context) {
    final earned = Progress.I.gradeStars(grade);
    final done = Progress.I.unitsDone(grade);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BouncyButton(
        onTap: () {
          Sfx.I.speak(grade.title);
          Navigator.of(context).push(funRoute(UnitsScreen(grade: grade)));
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: grade.colors,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
            boxShadow: [
              BoxShadow(color: grade.colors.last.withOpacity(0.5), blurRadius: 0, offset: const Offset(0, 7)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('${grade.level}', style: AppText.heading(40, color: grade.colors.last)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(grade.title, style: AppText.display(28)),
                    Text(grade.subtitle, style: AppText.body(16, color: Colors.white.withOpacity(0.95))),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: grade.units.isEmpty ? 0 : done / grade.units.length,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.35),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.sun, size: 20),
                        const SizedBox(width: 3),
                        Text('$earned/${grade.maxStars}',
                            style: AppText.body(14, color: Colors.white)),
                        const SizedBox(width: 12),
                        Text('$done/${grade.units.length} unit',
                            style: AppText.body(14, color: Colors.white.withOpacity(0.9))),
                      ],
                    ),
                  ],
                ),
              ),
              Text(grade.emoji, style: const TextStyle(fontSize: 44)),
            ],
          ),
        ),
      ),
    );
  }
}
