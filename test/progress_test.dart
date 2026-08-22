import 'package:english_fun/services/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'name': 'Tester'});
    await Progress.I.load();
  });

  test('mastery: wrong answers accumulate case-insensitively', () async {
    Progress.I.recordWrong('Apple');
    Progress.I.recordWrong('apple'); // case-insensitive
    expect(Progress.I.wrongCount('APPLE'), 2);

    final weak = Progress.I.weakWords();
    expect(weak.first.key, 'apple');
    expect(weak.first.value, 2);
  });

  test(
    'mastery: correct answers promote the word out of the weak list',
    () async {
      Progress.I.recordWrong('apple');
      expect(Progress.I.weakWords().map((e) => e.key), contains('apple'));
      expect(Progress.I.memoryFor('apple')!.box, 0);

      // Each correct answer promotes one Leitner box; the lifetime wrong
      // counter is history and deliberately never decreases.
      Progress.I.recordCorrect('apple');
      Progress.I.recordCorrect('apple');
      expect(Progress.I.memoryFor('apple')!.box, 2);
      expect(Progress.I.wrongCount('apple'), 1);
      expect(Progress.I.weakWords().map((e) => e.key), contains('apple'));

      // Box 3+ means the word is considered learned and drops off the report.
      Progress.I.recordCorrect('apple');
      expect(Progress.I.memoryFor('apple')!.box, 3);
      expect(
        Progress.I.weakWords().map((e) => e.key),
        isNot(contains('apple')),
      );
    },
  );

  test(
    'mastery: answering schedules the next review into the future',
    () async {
      Progress.I.recordCorrect('banana');
      final memory = Progress.I.memoryFor('banana')!;
      expect(memory.box, 1);
      expect(memory.isNew, isFalse);
      // Box 1 waits a day, so it is not due immediately.
      expect(memory.isDue(DateTime.now()), isFalse);
      expect(memory.isDue(DateTime.now().add(const Duration(days: 2))), isTrue);
    },
  );

  test('mastery: legacy v2 wrong_map migrates into the SRS memory', () async {
    SharedPreferences.setMockInitialValues({
      'name': 'Tester',
      'wrong_map': '{"cat":3,"dog":1}',
    });
    await Progress.I.load();

    expect(Progress.I.wrongCount('cat'), 3);
    expect(Progress.I.wrongCount('dog'), 1);
    expect(Progress.I.memoryFor('cat')!.box, 0);
    expect(Progress.I.weakWords().first.key, 'cat');
  });

  test('placement seeding personalises the first session', () async {
    Progress.I.seedPlacement(['red', 'blue'], ['orange']);

    expect(Progress.I.memoryFor('red')!.box, 3);
    expect(Progress.I.memoryFor('orange')!.box, 0);
    expect(Progress.I.weakWords().map((e) => e.key), contains('orange'));
    expect(Progress.I.weakWords().map((e) => e.key), isNot(contains('red')));
  });

  test('coins: new stars pay out, shop buy/equip works', () async {
    final before = Progress.I.coins;
    await Progress.I.setStars('g1_alphabet', 'quiz', 3);
    expect(Progress.I.coins, before + 30);
    // re-setting lower stars pays nothing
    await Progress.I.setStars('g1_alphabet', 'quiz', 2);
    expect(Progress.I.coins, before + 30);

    expect(Progress.I.buyItem('👑', 300), isFalse); // too expensive
    expect(Progress.I.buyItem('🧢', 50), isFalse); // only 30 coins
    Progress.I.addCoins(100);
    expect(Progress.I.buyItem('🧢', 50), isTrue);
    Progress.I.equipHat('🧢');
    expect(Progress.I.equippedHat, '🧢');
    Progress.I.equipHat('👑'); // not owned -> ignored
    expect(Progress.I.equippedHat, '🧢');
  });

  test('daily goal counts finished games', () {
    expect(Progress.I.dailyGoalReached, isFalse);
    for (var i = 0; i < 3; i++) {
      Progress.I.countGame();
    }
    expect(Progress.I.gamesToday, 3);
    expect(Progress.I.dailyGoalReached, isTrue);
  });

  test(
    'logout clears identity and onboarding state but keeps learning progress',
    () async {
      SharedPreferences.setMockInitialValues({
        'name': 'Ari',
        'onboarded': true,
        'selected_grade': 4,
        'st_g1_alphabet:quiz': 3,
        'coins': 30,
      });
      await Progress.I.load();

      await Progress.I.logout();

      expect(Progress.I.playerName, isEmpty);
      expect(Progress.I.onboarded, isFalse);
      expect(Progress.I.selectedGrade, 0);
      expect(Progress.I.stars('g1_alphabet', 'quiz'), 3);
      expect(Progress.I.coins, 30);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('name'), isNull);
      expect(prefs.getBool('onboarded'), isNull);
      expect(prefs.getInt('selected_grade'), isNull);
    },
  );

  test('pets: egg economy, hatching, feeding and spin daily gates', () {
    final p = Progress.I;
    expect(p.eggs, 0);
    expect(p.hatchEgg('🐱'), isNull); // no eggs yet
    p.addCoins(100);
    expect(p.buyEgg(40), isTrue);
    expect(p.eggs, 1);
    expect(p.hatchEgg('🐱'), '🐱');
    expect(p.pets, contains('🐱'));
    expect(p.activePet, '🐱');
    expect(p.eggs, 0);

    expect(p.canFeedToday, isTrue);
    p.markFedToday();
    expect(p.canFeedToday, isFalse);

    expect(p.canSpinToday, isTrue);
    p.markSpunToday();
    expect(p.canSpinToday, isFalse);
  });

  test('badges unlock once', () {
    final p = Progress.I;
    expect(p.unlockBadge('star1'), isTrue);
    expect(p.unlockBadge('star1'), isFalse);
    expect(p.badges, contains('star1'));
  });
}
