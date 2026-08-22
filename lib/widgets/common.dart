import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/ads_policy.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import 'funky.dart';
import 'world_painters.dart';

/// Playful scale+fade page transition.
Route<T> funRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: AdsPolicy.routeNameFor(page)),
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

/// Themed animated world background.
/// world: 0 sky, 1 forest, 2 ocean, 3 city, 4 candy, 5 space, 6 magic castle.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final bool clouds;
  final int world;
  const AnimatedBackground({
    super.key,
    required this.child,
    this.colors,
    this.clouds = true,
    this.world = 0,
  });

  /// Default gradient per world theme.
  static List<Color> worldColors(int world) {
    switch (world) {
      case 1:
        return const [Color(0xFF6FCF67), Color(0xFFE9FBDF)]; // forest
      case 2:
        return const [Color(0xFF3FA7D6), Color(0xFFCDEFFB)]; // ocean
      case 3:
        return const [Color(0xFF6EB6FF), Color(0xFFEAF2FF)]; // city
      case 4:
        return const [Color(0xFFFF9AE2), Color(0xFFFFF0F9)]; // candy
      case 5:
        return const [Color(0xFF141E5B), Color(0xFF4A4E8C)]; // space
      case 6:
        return const [Color(0xFF5A189A), Color(0xFFE9D8FF)]; // magic
      default:
        return const [AppColors.skyTop, AppColors.skyBottom];
    }
  }

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void initState() {
    super.initState();
    // Listen so the reduced-motion switch takes effect immediately instead
    // of only after a restart.
    Progress.I.addListener(_syncMotion);
    _syncMotion();
  }

  void _syncMotion() {
    if (!mounted) return;
    final shouldAnimate = widget.clouds && !Progress.I.reducedMotion;
    if (shouldAnimate && !_c.isAnimating) {
      _c.repeat();
    } else if (!shouldAnimate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void didUpdateWidget(AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clouds != widget.clouds) _syncMotion();
  }

  @override
  void dispose() {
    Progress.I.removeListener(_syncMotion);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? AnimatedBackground.worldColors(widget.world);
    final animate = widget.clouds && !Progress.I.reducedMotion;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          if (animate)
            Positioned.fill(
              child: RepaintBoundary(child: CustomPaint(painter: WorldPainter(widget.world, _c))),
            ),
          widget.child,
        ],
      ),
    );
  }
}

/// Button that squishes on press and bounces back.
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool sound;

  /// Spoken label for screen readers. When null the child's own text is used.
  final String? semanticLabel;

  const BouncyButton({
    super.key,
    required this.child,
    this.onTap,
    this.sound = true,
    this.semanticLabel,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> {
  bool _down = false;

  void _setDown(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  void _activate() {
    if (widget.onTap == null) return;
    if (widget.sound) Sfx.I.click();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    // Reduced motion also means no squish animation.
    final squish = Progress.I.reducedMotion ? 1.0 : (_down ? 0.88 : 1.0);
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      onTap: widget.onTap == null ? null : _activate,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setDown(true),
        onTapCancel: () => _setDown(false),
        onTapUp: (_) {
          _setDown(false);
          _activate();
        },
        child: AnimatedScale(
          scale: squish,
          duration: Duration(milliseconds: _down ? 90 : 380),
          curve: _down ? Curves.easeOut : Curves.elasticOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Big rounded colorful button used across menus.
class PillButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback? onTap;
  final double fontSize;
  const PillButton({
    super.key,
    required this.label,
    required this.emoji,
    required this.color,
    this.onTap,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade400 : color,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 3),
          boxShadow: [
            BoxShadow(
              color: (onTap == null ? Colors.grey : color).withValues(alpha: 0.45),
              blurRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: fontSize + 4)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label, textAlign: TextAlign.center, style: AppText.display(fontSize)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of stars (filled / empty).
class StarRow extends StatelessWidget {
  final int stars;
  final int max;
  final double size;
  const StarRow({super.key, required this.stars, this.max = 3, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars dari $max bintang',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(max, (i) {
          final filled = i < stars;
          return Icon(
            Icons.star_rounded,
            size: size,
            color: filled ? AppColors.star : Colors.white.withValues(alpha: 0.5),
            shadows: filled ? const [Shadow(color: Color(0x66B26A00), blurRadius: 4)] : null,
          );
        }),
      ),
    );
  }
}

/// Confetti celebration overlay.
class ConfettiController extends ChangeNotifier {
  void burst() => notifyListeners();
}

class ConfettiOverlay extends StatefulWidget {
  final ConfettiController controller;
  const ConfettiOverlay({super.key, required this.controller});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_burst);
    _ac.addListener(() => setState(() {}));
  }

  void _burst() {
    final rnd = math.Random();
    const palette = [
      Color(0xFFFF6B6B),
      Color(0xFFFFD60A),
      Color(0xFF43AA8B),
      Color(0xFF4CC9F0),
      Color(0xFFC77DFF),
      Color(0xFFFF9F1C),
      Color(0xFFFF8FAB),
    ];
    _particles = List.generate(70, (i) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 2.2;
      final speed = 0.35 + rnd.nextDouble() * 0.75;
      return _Particle(
        x: 0.5 + (rnd.nextDouble() - 0.5) * 0.25,
        y: 0.42,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: palette[rnd.nextInt(palette.length)],
        size: 6 + rnd.nextDouble() * 8,
        spin: rnd.nextDouble() * 6,
        circle: rnd.nextBool(),
      );
    });
    _ac.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_burst);
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_particles, _ac.value)),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, size, spin;
  Color color;
  bool circle;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.spin,
    required this.circle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1 over 2.4s
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || t >= 1) return;
    final seconds = t * 2.4;
    for (final p in particles) {
      final px = (p.x + p.vx * seconds) * size.width;
      final py = (p.y + p.vy * seconds + 0.55 * seconds * seconds) * size.height;
      if (py > size.height + 20) continue;
      final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.spin * seconds * 3);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

/// Funky the fox mascot (painted + animated); tap to hear him talk.
class Mascot extends StatelessWidget {
  final double size;
  final String greeting;
  const Mascot({
    super.key,
    this.size = 84,
    this.greeting = "Hello! I'm Funky! Let's learn English!",
  });

  @override
  Widget build(BuildContext context) {
    return FunkyMascot(
      size: size,
      onTap: () {
        Sfx.I.pop();
        Sfx.I.speak(greeting);
      },
    );
  }
}

/// Speech bubble for mascot / hints.
class SpeechBubble extends StatelessWidget {
  final String text;
  final double fontSize;
  const SpeechBubble({super.key, required this.text, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Text(text, style: AppText.body(fontSize, color: AppColors.ink)),
    );
  }
}

/// 3D flip card: toggles between [front] and [back].
class FlipCard extends StatelessWidget {
  final bool showBack;
  final Widget front;
  final Widget back;
  const FlipCard({super.key, required this.showBack, required this.front, required this.back});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: showBack ? 1 : 0),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        final angle = value * math.pi;
        final isBack = angle > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: isBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: back,
                )
              : front,
        );
      },
    );
  }
}

/// Top bar for game screens: back button + title + optional trailing widget.
class KidAppBar extends StatelessWidget {
  final String title;
  final String emoji;
  final List<Color> colors;
  final Widget? trailing;
  const KidAppBar({
    super.key,
    required this.title,
    required this.emoji,
    required this.colors,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(
          children: [
            BouncyButton(
              semanticLabel: 'Kembali',
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 30, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(title, overflow: TextOverflow.ellipsis, style: AppText.display(26)),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
