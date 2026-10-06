import 'package:english_fun/models.dart';
import 'package:english_fun/screens/balloon_screen.dart';
import 'package:english_fun/screens/boss_screen.dart';
import 'package:english_fun/screens/result_screen.dart';
import 'package:english_fun/services/progress.dart';
import 'package:english_fun/services/sfx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _words = [
  VocabItem('Apple', 'Apel', '🍎'),
  VocabItem('Banana', 'Pisang', '🍌'),
  VocabItem('Cat', 'Kucing', '🐱'),
  VocabItem('Dog', 'Anjing', '🐶'),
  VocabItem('Egg', 'Telur', '🥚'),
  VocabItem('Fish', 'Ikan', '🐟'),
  VocabItem('Grape', 'Anggur', '🍇'),
  VocabItem('House', 'Rumah', '🏠'),
  VocabItem('Ice', 'Es', '🧊'),
  VocabItem('Juice', 'Jus', '🧃'),
  VocabItem('Kite', 'Layang-layang', '🪁'),
  VocabItem('Lion', 'Singa', '🦁'),
];

const _grade = Grade(
  level: 1,
  title: 'Kelas 1',
  subtitle: 'Ayo Mulai',
  emoji: '🌱',
  colors: [Colors.orange, Colors.red],
  units: [
    Unit.vocab(
      id: 'test_words',
      title: 'Words',
      titleId: 'Kata',
      emoji: '📖',
      items: _words,
    ),
  ],
);

Future<void> _openGame(WidgetTester tester, Widget game) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(420, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Nunito',
        fontFamilyFallback: const ['AppEmoji'],
      ),
      home: game,
    ),
  );
  await tester.pump();
}

Future<void> _closeGame(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
  expect(tester.takeException(), isNull);
}

VocabItem _balloonTarget(WidgetTester tester) {
  final label = tester.widget<Text>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Text && (widget.data?.startsWith('Letuskan: ') ?? false),
    ),
  );
  return _words.firstWhere((word) => label.data == 'Letuskan: ${word.idn}');
}

Future<Finder> _visibleBalloon(
  WidgetTester tester, {
  required bool correct,
}) async {
  for (var step = 0; step < 240; step++) {
    final target = _balloonTarget(tester);
    final candidates = correct
        ? find.text(target.emoji).hitTestable()
        : find
              .byWidgetPredicate(
                (widget) =>
                    widget is Text &&
                    widget.data != target.emoji &&
                    _words.any((word) => word.emoji == widget.data),
              )
              .hitTestable();
    if (candidates.evaluate().isNotEmpty) return candidates.first;
    await tester.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure(
    'No tappable ${correct ? 'correct' : 'wrong'} balloon appeared.',
  );
}

Future<ResultScreen> _finishBalloons(
  WidgetTester tester, {
  required int missedTargets,
}) async {
  await _openGame(
    tester,
    const BalloonScreen(
      words: [
        VocabItem('Apple', 'Apel', '🍎'),
        VocabItem('Banana', 'Pisang', '🍌'),
      ],
      title: 'Balon Pop',
    ),
  );
  for (var target = 0; target < 12; target++) {
    if (target < missedTargets) {
      await tester.tap(await _visibleBalloon(tester, correct: false));
      await tester.pump();
    }
    await tester.tap(await _visibleBalloon(tester, correct: true));
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  return tester.widget<ResultScreen>(find.byType(ResultScreen));
}

Future<void> _answerBoss(WidgetTester tester, {bool correct = true}) async {
  final picture = tester.widget<Text>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Text && _words.any((word) => word.emoji == widget.data),
    ),
  );
  final target = _words.firstWhere((word) => word.emoji == picture.data);
  final options = find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        _words.any((word) => word.en == widget.data) &&
        (correct ? widget.data == target.en : widget.data != target.en),
  );
  await tester.ensureVisible(options.first);
  await tester.tap(options.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = {
      'Baloo': 'assets/fonts/baloo-2-v23-latin-700.ttf',
      'Nunito': 'assets/fonts/nunito-v32-latin-800.ttf',
      'AppEmoji': 'assets/fonts/NotoColorEmojiSubset.ttf',
    };
    for (final font in fonts.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Sfx.I.muted = true;
    await Progress.I.load();
  });

  testWidgets('Balon Pop records each correct target immediately', (
    tester,
  ) async {
    await _openGame(
      tester,
      const BalloonScreen(
        words: [VocabItem('Apple', 'Apel', '🍎')],
        title: 'Balon Pop',
      ),
    );
    try {
      await tester.tap(await _visibleBalloon(tester, correct: true));
      await tester.pump();
      expect(Progress.I.memoryFor('Apple')?.correct, 1);
    } finally {
      await _closeGame(tester);
    }
  });

  testWidgets('Balon Pop ignores a second tap on an already popped balloon', (
    tester,
  ) async {
    await _openGame(
      tester,
      const BalloonScreen(
        words: [VocabItem('Apple', 'Apel', '🍎')],
        title: 'Balon Pop',
      ),
    );
    try {
      final balloon = await _visibleBalloon(tester, correct: true);
      await tester.tap(balloon);
      await tester.tap(balloon);
      await tester.pump();
      expect(find.text('1/12'), findsOneWidget);
    } finally {
      await _closeGame(tester);
    }
  });

  for (final (misses, expectedCorrect, expectedStars) in [
    (0, 12, 3),
    (3, 9, 2),
    (6, 6, 1),
    (12, 0, 0),
  ]) {
    testWidgets(
      'Balon Pop grades $misses missed targets by first-try accuracy',
      (tester) async {
        try {
          final result = await _finishBalloons(tester, missedTargets: misses);
          expect(result.correct, expectedCorrect);
          expect(result.total, 12);
          expect(find.text('Pada percobaan pertama'), findsOneWidget);
          expect(result.stars, expectedStars);
          expect(Progress.I.coins, expectedCorrect * 2);
        } finally {
          await _closeGame(tester);
        }
      },
    );
  }

  for (final (misses, expectedStars, expectedTotal) in [
    (0, 3, 10),
    (1, 2, 11),
    (2, 1, 12),
  ]) {
    testWidgets('Boss Battle can still be won after $misses mistakes', (
      tester,
    ) async {
      await _openGame(tester, const BossScreen(grade: _grade));
      try {
        for (var attempt = 0; attempt < expectedTotal; attempt++) {
          if (find.byType(ResultScreen).evaluate().isNotEmpty) break;
          await _answerBoss(tester, correct: attempt >= misses);
        }
        await tester.pump(const Duration(seconds: 1));
        final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
        expect(result.title, 'Boss Kalah! 🎉');
        expect(result.correct, 10);
        expect(result.total, expectedTotal);
        expect(result.stars, expectedStars);
        expect(Progress.I.eggs, 1);
      } finally {
        await _closeGame(tester);
      }
    });
  }

  testWidgets('Boss Battle counts a timeout and remains winnable', (
    tester,
  ) async {
    await _openGame(tester, const BossScreen(grade: _grade));
    try {
        await tester.pump(const Duration(seconds: 13));
      await tester.pump(const Duration(milliseconds: 700));
        expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
      for (var answer = 0; answer < 10; answer++) {
        if (find.byType(ResultScreen).evaluate().isNotEmpty) break;
        await _answerBoss(tester);
      }
      await tester.pump(const Duration(seconds: 1));
      final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(result.title, 'Boss Kalah! 🎉');
      expect(result.correct, 10);
      expect(result.total, 11);
      expect(result.stars, 2);
    } finally {
      await _closeGame(tester);
    }
  });

  testWidgets('Boss Battle ends after losing all three hearts', (tester) async {
    await _openGame(tester, const BossScreen(grade: _grade));
    try {
      for (var mistake = 0; mistake < 3; mistake++) {
        await _answerBoss(tester, correct: false);
      }
      await tester.pump(const Duration(seconds: 1));
      final result = tester.widget<ResultScreen>(find.byType(ResultScreen));
      expect(result.title, 'Boss Menang...');
      expect(result.correct, 0);
      expect(result.total, 3);
      expect(result.stars, 0);
      expect(Progress.I.eggs, 0);
    } finally {
      await _closeGame(tester);
    }
  });
}
