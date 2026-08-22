import 'package:flutter/material.dart';

import '../data/adventures.dart';
import '../data/content.dart';
import '../models.dart';
import '../services/progress.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'adventure_screen.dart';
import 'balloon_screen.dart';
import 'catch_screen.dart';
import 'runner_screen.dart';
import 'simon_screen.dart';

/// Words for arcade games: prefers units the kid already played (>=1 star),
/// falls back to the whole grade so the games are never empty.
List<VocabItem> arcadeWordPool(int gradeLevel) {
  final grade = kGrades[(gradeLevel - 1).clamp(0, kGrades.length - 1)];
  final learned = grade.units
      .where((u) => u.kind == UnitKind.vocab && Progress.I.unitStars(u) > 0)
      .expand((u) => u.items)
      .toList();
  if (learned.length >= 8) return learned;
  return grade.units
      .where((u) => u.kind == UnitKind.vocab)
      .expand((u) => u.items)
      .toList();
}

/// "Arena Arcade" — hub for the action & bonus games.
class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  int _grade = 1;

  void _openWordGame(Widget Function(List<VocabItem> words) builder) {
    final pool = arcadeWordPool(_grade);
    if (pool.length < 4) return;
    Navigator.of(context).push(funRoute(builder(pool)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        world: 5,
        child: SafeArea(
          child: Column(
            children: [
              const KidAppBar(title: 'Arena Arcade', emoji: '🕹️', colors: []),
              const SizedBox(height: 4),
              // grade picker for word games
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text(
                      'Kelas:',
                      style: AppText.body(17, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    for (var g = 1; g <= 6; g++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$g'),
                          selected: _grade == g,
                          onSelected: (_) => setState(() => _grade = g),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ContentWidth(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _gameCard(
                        emoji: '🎈',
                        title: 'Balon Pop',
                        desc: 'Dengar kata, letuskan balon yang benar!',
                        colors: const [Color(0xFFFF6B6B), Color(0xFFFF9F1C)],
                        onTap: () => _openWordGame(
                          (w) => BalloonScreen(words: w, title: 'Balon Pop'),
                        ),
                      ),
                      _gameCard(
                        emoji: '🧺',
                        title: 'Tangkap Kata',
                        desc: 'Gerakkan keranjang, tangkap kata yang tepat!',
                        colors: const [Color(0xFF43AA8B), Color(0xFF80ED99)],
                        onTap: () => _openWordGame(
                          (w) => CatchScreen(words: w, title: 'Tangkap Kata'),
                        ),
                      ),
                      _gameCard(
                        emoji: '🏃',
                        title: 'Lari Kata',
                        desc:
                            'Funky berlari! Ketuk gerbang jawaban yang benar!',
                        colors: const [Color(0xFF4CC9F0), Color(0xFF4361EE)],
                        onTap: () => _openWordGame(
                          (w) => RunnerScreen(words: w, title: 'Lari Kata'),
                        ),
                      ),
                      _gameCard(
                        emoji: '🧍',
                        title: 'Simon Says',
                        desc: 'Ikuti perintah... hanya kalau Simon bilang!',
                        colors: const [Color(0xFFFF8FAB), Color(0xFFC77DFF)],
                        onTap: () => Navigator.of(
                          context,
                        ).push(funRoute(const SimonScreen())),
                      ),
                      const SizedBox(height: 6),
                      Text('🗺️ Cerita Bercabang', style: AppText.display(22)),
                      const SizedBox(height: 8),
                      for (final adv in kAdventures)
                        _gameCard(
                          emoji: adv.emoji,
                          title: adv.title,
                          desc: adv.titleId,
                          colors: const [Color(0xFF7B61FF), Color(0xFF9B5DE5)],
                          onTap: () => Navigator.of(
                            context,
                          ).push(funRoute(AdventureScreen(adventure: adv))),
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

  Widget _gameCard({
    required String emoji,
    required String title,
    required String desc,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncyButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.45),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 46)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.display(23)),
                    Text(desc, style: AppText.body(14, color: Colors.white)),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
