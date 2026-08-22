import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'services/ads_placement.dart';
import 'services/consent.dart';
import 'services/error_reporter.dart';
import 'services/monetization.dart';
import 'services/progress.dart';
import 'services/sfx.dart';
import 'theme.dart';
import 'widgets/ad_banner.dart';
import 'widgets/responsive.dart';

Future<void> main() async {
  // Everything runs inside a guarded zone so no async error escapes unseen.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await ErrorReporter.I.init();
      ErrorReporter.I.install();

      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
      await _applyOrientationLock();

      await Future.wait([
        Sfx.I.init(),
        Progress.I.load(),
        MonetizationService.I.init(),
      ]);
      // Consent must settle before the first ad request, but it must never
      // block the child from reaching the app.
      unawaited(ConsentService.I.ensureConsent());

      runApp(const EnglishFunApp());
    },
    (error, stack) => ErrorReporter.I.record(
      error,
      stack,
      context: 'runZonedGuarded',
      fatal: true,
    ),
  );
}

/// Phones stay portrait so a child cannot knock the layout sideways
/// mid-game; tablets are big enough to earn landscape support.
Future<void> _applyOrientationLock() async {
  try {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    final shortestSide = math.min(size.width, size.height);
    await SystemChrome.setPreferredOrientations(
      shortestSide >= Breakpoints.tablet
          ? const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
  } catch (error, stack) {
    ErrorReporter.I.record(error, stack, context: 'orientationLock');
  }
}

class EnglishFunApp extends StatelessWidget {
  const EnglishFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Fun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Nunito',
        fontFamilyFallback: const ['AppEmoji'],
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4361EE)),
      ),
      navigatorObservers: [AdsPlacement.I.observer],
      builder: (context, child) => _TextScaleGuard(child: _AdShell(child: child)),
      home: const SplashScreen(),
    );
  }
}

/// Pins a single adaptive banner under the navigator. Games keep a full
/// screen because the banner unmounts whenever [AdsPlacement] is not hub.
class _AdShell extends StatelessWidget {
  final Widget? child;
  const _AdShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdsPlacement.I,
      builder: (context, _) {
        final media = MediaQuery.of(context);
        return Column(
          children: [
            Expanded(
              child: MediaQuery(
                data: AdsPlacement.I.consumeBottomInset
                    ? media.removePadding(removeBottom: true)
                    : media,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            const PersistentAdBanner(),
          ],
        );
      },
    );
  }
}

/// Honours the device font-size setting, but keeps it inside a range the
/// game layouts can actually render.
///
/// The app's base text is already large and bold for young readers, so the
/// floor matters as much as the ceiling: shrinking below 1.0 would hurt
/// legibility rather than help it.
class _TextScaleGuard extends StatelessWidget {
  final Widget? child;
  const _TextScaleGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.textScaler.scale(100) / 100;
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(
          scale.clamp(AppText.minTextScale, AppText.maxTextScale),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
