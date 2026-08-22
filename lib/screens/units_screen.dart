import 'package:flutter/material.dart';

import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'boss_screen.dart';
import 'build_screen.dart';
import 'grammar_screen.dart';
import 'learn_screen.dart';
import 'memory_screen.dart';
import 'quiz_screen.dart';
import 'reading_screen.dart';
import 'speak_screen.dart';
import 'spelling_screen.dart';

class UnitsScreen extends StatelessWidget {
  final Grade grade;
  const UnitsScreen({super.key, required this.grade});

  static const _pattern = [0.0, -0.5, 0.0, 0.5];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        world: grade.level, // each grade is its own themed world
        child: Column(
          children: [
            KidAppBar(
              title: '${grade.title} • ${grade.subtitle}',
              emoji: grade.emoji,
              colors: grade.colors,
            ),
            Expanded(
              child: ContentWidth(
                child: ListenableBuilder(
                  listenable: Progress.I,
                  builder: (context, _) => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    itemCount: grade.units.length + 1, // +1 = boss node
                    itemBuilder: (context, i) {
                      final alignX = _pattern[i % _pattern.length];
                      final connector = i == 0
                          ? const SizedBox(height: 6)
                          : SizedBox(
                              height: 40,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _ConnectorPainter(
                                  from: _pattern[(i - 1) % _pattern.length],
                                  to: alignX,
                                  color: grade.colors.first,
                                ),
                              ),
                            );
                      if (i == grade.units.length) {
                        final bossDone =
                            Progress.I.unitsDone(grade) == grade.units.length;
                        return Column(
                          children: [
                            connector,
                            Align(
                              alignment: Alignment(alignX, 0),
                              child: _BossNode(
                                grade: grade,
                                unlocked: bossDone,
                                onTap: () {
                                  if (bossDone) {
                                    Sfx.I.pop();
                                    Navigator.of(
                                      context,
                                    ).push(funRoute(BossScreen(grade: grade)));
                                  } else {
                                    Sfx.I.wrong();
                                    Sfx.I.speak('Finish all units first!');
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      final unit = grade.units[i];
                      final unlocked = Progress.I.unitUnlocked(grade, i);
                      return Column(
                        children: [
                          connector,
                          Align(
                            alignment: Alignment(alignX, 0),
                            child: _UnitNode(
                              unit: unit,
                              unlocked: unlocked,
                              colors: grade.colors,
                              onTap: () =>
                                  _showUnitDetail(context, unit, grade.colors),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitDetail(BuildContext context, Unit unit, List<Color> colors) {
    Sfx.I.pop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(unit.emoji, style: const TextStyle(fontSize: 54)),
              Text(unit.title, style: AppText.heading(30)),
              Text(unit.titleId, style: AppText.body(18)),
              const SizedBox(height: 16),
              ...unit.games.map((game) {
                final meta = _gameMeta(unit, game);
                final earned = Progress.I.stars(unit.id, game);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BouncyButton(
                    onTap: () => _openGame(sheetContext, unit, game, colors),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: colors.last.withValues(alpha: 0.4),
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(meta.$1, style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(meta.$2, style: AppText.display(22)),
                          ),
                          StarRow(stars: earned, max: meta.$3, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  (String, String, int) _gameMeta(Unit u, String game) {
    switch (game) {
      case 'learn':
        return u.kind == UnitKind.grammar
            ? ('📖', 'Belajar & Latihan', 3)
            : ('📖', 'Belajar', 1);
      case 'quiz':
        return u.kind == UnitKind.story
            ? ('🎯', 'Kuis Cerita', 3)
            : ('🎯', 'Tebak Kata', 3);
      case 'listen':
        return ('🎧', 'Tebak Suara', 3);
      case 'build':
        return ('🧩', 'Susun Kalimat', 3);
      case 'speak':
        return ('🎤', 'Ucapkan!', 3);
      case 'memory':
        return ('🃏', 'Memory Match', 3);
      case 'spell':
        return ('🔤', 'Susun Huruf', 3);
      case 'read':
        return ('📖', 'Baca Cerita', 1);
      default:
        return ('🎮', game, 3);
    }
  }

  void _openGame(
    BuildContext sheetContext,
    Unit unit,
    String game,
    List<Color> colors,
  ) {
    Navigator.of(sheetContext).pop();
    late final Widget screen;
    switch (game) {
      case 'learn':
        screen = unit.kind == UnitKind.grammar
            ? GrammarScreen(unit: unit)
            : LearnScreen(unit: unit);
        break;
      case 'quiz':
        screen = unit.kind == UnitKind.story
            ? ReadingScreen(unit: unit, startAtQuiz: true)
            : QuizScreen(unit: unit, mode: QuizMode.picture);
        break;
      case 'listen':
        screen = QuizScreen(unit: unit, mode: QuizMode.listening);
        break;
      case 'speak':
        screen = SpeakScreen(unit: unit, colors: colors);
        break;
      case 'build':
        screen = BuildScreen(unit: unit);
        break;
      case 'memory':
        screen = MemoryScreen(unit: unit);
        break;
      case 'spell':
        screen = SpellingScreen(unit: unit);
        break;
      case 'read':
        screen = ReadingScreen(unit: unit);
        break;
      default:
        screen = LearnScreen(unit: unit);
    }
    Navigator.of(sheetContext).push(funRoute(screen));
  }
}

/// Dotted winding path connecting two map nodes (decorative, scrolls with list).
class _ConnectorPainter extends CustomPainter {
  final double from; // alignment.x of previous node
  final double to; // alignment.x of this node
  final Color color;
  _ConnectorPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double x(double alignX) => size.width / 2 + alignX * (size.width - 170) / 2;
    final p1 = Offset(x(from), -4);
    final p2 = Offset(x(to), size.height + 4);
    final paint = Paint()..color = color.withValues(alpha: 0.65);
    // dotted cubic curve
    const steps = 7;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final mt = 1 - t;
      // control points pull horizontally for an S-curve feel
      final c1 = Offset(p1.dx, size.height * 0.45);
      final c2 = Offset(p2.dx, size.height * 0.55);
      final px =
          mt * mt * mt * p1.dx +
          3 * mt * mt * t * c1.dx +
          3 * mt * t * t * c2.dx +
          t * t * t * p2.dx;
      final py =
          mt * mt * mt * p1.dy +
          3 * mt * mt * t * c1.dy +
          3 * mt * t * t * c2.dy +
          t * t * t * p2.dy;
      canvas.drawCircle(Offset(px, py), 4.5, paint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.from != from || old.to != to || old.color != color;
}

class _UnitNode extends StatelessWidget {
  final Unit unit;
  final bool unlocked;
  final List<Color> colors;
  final VoidCallback onTap;
  const _UnitNode({
    required this.unit,
    required this.unlocked,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final earned = Progress.I.unitStars(unit);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: BouncyButton(
        onTap: unlocked ? onTap : () => Sfx.I.wrong(),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: unlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      )
                    : null,
                color: unlocked ? null : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: (unlocked ? colors.last : Colors.grey).withValues(
                      alpha: 0.45,
                    ),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                unlocked ? unit.emoji : '🔒',
                style: TextStyle(
                  fontSize: 44,
                  color: unlocked ? null : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(unit.title, style: AppText.heading(18)),
                  Text(unit.titleId, style: AppText.body(13)),
                  if (earned > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.star,
                          size: 18,
                        ),
                        Text(
                          '$earned/${unit.maxStars}',
                          style: AppText.body(13),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dragon boss node at the end of every grade map.
class _BossNode extends StatelessWidget {
  final Grade grade;
  final bool unlocked;
  final VoidCallback onTap;
  const _BossNode({
    required this.grade,
    required this.unlocked,
    required this.onTap,
  });

  static const _colors = [Color(0xFF4361EE), Color(0xFF9B5DE5)];

  @override
  Widget build(BuildContext context) {
    final stars = Progress.I.stars('boss_g${grade.level}', 'boss');
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: BouncyButton(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                gradient: unlocked
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _colors,
                      )
                    : null,
                color: unlocked ? null : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD60A), width: 5),
                boxShadow: [
                  BoxShadow(
                    color: (unlocked ? _colors.last : Colors.grey).withValues(
                      alpha: 0.5,
                    ),
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                unlocked ? '🐉' : '🔒',
                style: TextStyle(
                  fontSize: 52,
                  color: unlocked ? null : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3C096C),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text('BOSS BATTLE', style: AppText.display(18)),
                  Text(
                    unlocked ? 'Kalahkan Naga!' : 'Selesaikan semua unit dulu!',
                    style: AppText.body(12, color: Colors.white70),
                  ),
                  if (stars > 0) StarRow(stars: stars, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
