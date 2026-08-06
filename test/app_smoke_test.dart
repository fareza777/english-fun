import 'package:english_fun/main.dart';
import 'package:english_fun/services/progress.dart';
import 'package:english_fun/services/sfx.dart';
import 'package:english_fun/widgets/funky.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Pre-set a player name so the app skips onboarding and lands on Home.
    SharedPreferences.setMockInitialValues({'name': 'Tester'});
    Sfx.I.muted = true;
    await Progress.I.load();
  });

  testWidgets('splash -> home -> grade map -> flashcard learn flow', (tester) async {
    await tester.pumpWidget(const EnglishFunApp());

    // Splash shows the painted mascot, badge and subtitle (title is per-letter animated).
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FunkyMascot), findsWidgets);
    expect(find.text('ADVENTURE'), findsOneWidget);
    expect(find.text('Kelas 1 - 6 SD'), findsOneWidget);

    // Auto-navigate to home after the splash delay.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('English Fun Adventure'), findsOneWidget);
    expect(find.text('Kelas 1'), findsOneWidget);

    // Scroll the grade list to reveal Kelas 6.
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Kelas 6'), findsOneWidget);

    // Scroll back to the top.
    await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
    await tester.pump(const Duration(milliseconds: 400));

    // Open grade 1 -> unit map shows Alphabet Fun.
    await tester.tap(find.text('Kelas 1'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Alphabet Fun'), findsOneWidget);
    expect(find.text('Numbers'), findsOneWidget);

    // Open the unit detail sheet and start Belajar.
    await tester.tap(find.text('Alphabet Fun'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Belajar'), findsOneWidget);
    expect(find.text('Tebak Kata'), findsOneWidget);
    expect(find.text('Tebak Suara'), findsOneWidget);
    expect(find.text('Ucapkan!'), findsOneWidget);
    expect(find.text('Memory Match'), findsOneWidget);
    expect(find.text('Susun Huruf'), findsOneWidget);

    await tester.tap(find.text('Belajar'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Flashcard front: big letter + English word.
    expect(find.text('Aa'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);

    // Flip the card -> Indonesian translation appears.
    await tester.tap(find.text('Apple'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Apel'), findsOneWidget);
  });

  testWidgets('home -> sticker book opens with badges tab', (tester) async {
    await tester.pumpWidget(const EnglishFunApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('English Fun Adventure'), findsOneWidget);

    // Give the player a star so a badge condition is met on open
    // (regression: badge unlock during build used to crash this route).
    await Progress.I.setStars('g1_alphabet', 'learn', 1);

    await tester.tap(find.text('Stiker 0'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Koleksiku'), findsOneWidget);
    expect(find.text('Stiker 🎒'), findsOneWidget);
    expect(find.text('Lencana 🏅'), findsOneWidget);

    // Switch to the badges tab; the "Bintang Pertama" badge is now unlocked.
    await tester.tap(find.text('Lencana 🏅'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Bintang Pertama'), findsOneWidget);
  });
}
