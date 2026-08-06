import 'package:english_fun/services/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'name': 'Tester'});
    await Progress.I.load();
  });

  test('mastery: wrong answers accumulate, correct answers heal', () async {
    Progress.I.recordWrong('Apple');
    Progress.I.recordWrong('apple'); // case-insensitive
    expect(Progress.I.wrongCount('APPLE'), 2);
    Progress.I.recordCorrect('apple');
    expect(Progress.I.wrongCount('apple'), 1);
    final weak = Progress.I.weakWords();
    expect(weak.first.key, 'apple');
    expect(weak.first.value, 1);
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
