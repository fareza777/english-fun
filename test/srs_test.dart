import 'dart:math' as math;

import 'package:english_fun/services/srs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 19, 10);

  group('WordMemory', () {
    test('a new word is due immediately', () {
      const memory = WordMemory();
      expect(memory.isNew, isTrue);
      expect(memory.isDue(now), isTrue);
    });

    test('correct answers climb the Leitner boxes and stop at the ceiling', () {
      var memory = const WordMemory();
      for (var i = 0; i < WordMemory.maxBox + 3; i++) {
        memory = memory.answer(correct: true, now: now);
      }
      expect(memory.box, WordMemory.maxBox);
      expect(memory.correct, WordMemory.maxBox + 3);
      expect(memory.wrong, 0);
    });

    test('a wrong answer drops straight back to box zero', () {
      var memory = const WordMemory();
      memory = memory.answer(correct: true, now: now);
      memory = memory.answer(correct: true, now: now);
      expect(memory.box, 2);

      memory = memory.answer(correct: false, now: now);
      expect(memory.box, 0);
      expect(memory.wrong, 1);
      // Box 0 has a zero-day interval, so it comes back in the same session.
      expect(memory.isDue(now), isTrue);
    });

    test('review intervals grow as the box grows', () {
      final box1 = const WordMemory().answer(correct: true, now: now);
      expect(box1.isDue(now.add(const Duration(hours: 12))), isFalse);
      expect(box1.isDue(now.add(const Duration(days: 1))), isTrue);

      final box2 = box1.answer(correct: true, now: now);
      expect(box2.due!.difference(now).inDays, WordMemory.intervalDays[2]);
    });

    test('survives a JSON round trip', () {
      final memory = const WordMemory()
          .answer(correct: true, now: now)
          .answer(correct: false, now: now);
      final restored = WordMemory.fromJson(memory.toJson())!;

      expect(restored.box, memory.box);
      expect(restored.wrong, memory.wrong);
      expect(restored.correct, memory.correct);
      expect(restored.due, memory.due);
      expect(restored.lastSeen, memory.lastSeen);
    });

    test('rejects malformed payloads instead of throwing', () {
      expect(WordMemory.fromJson(null), isNull);
      expect(WordMemory.fromJson('nonsense'), isNull);
      expect(WordMemory.fromJson(<String, dynamic>{})!.box, 0);
    });
  });

  group('SrsScheduler.weight', () {
    test('due and previously-missed words outrank everything else', () {
      final missed = const WordMemory().answer(correct: false, now: now);
      final fresh = SrsScheduler.weight(null, now);
      final due = SrsScheduler.weight(missed, now);

      final learned = const WordMemory()
          .answer(correct: true, now: now)
          .answer(correct: true, now: now);
      final notDue = SrsScheduler.weight(learned, now);

      expect(due, greaterThan(fresh));
      expect(fresh, greaterThan(notDue));
    });

    test('weight never goes to zero, so nothing is unreachable', () {
      var memory = const WordMemory();
      for (var i = 0; i < WordMemory.maxBox; i++) {
        memory = memory.answer(correct: true, now: now);
      }
      // Far in the future the word is due again but very well known.
      final later = now.add(const Duration(days: 400));
      expect(SrsScheduler.weight(memory, later), greaterThan(0));
    });
  });

  group('SrsScheduler.pick', () {
    test('returns distinct items and respects the pool size', () {
      final pool = List.generate(5, (i) => 'w$i');
      final picked = SrsScheduler.pick<String>(
        pool,
        10,
        memoryOf: (_) => null,
        now: now,
        random: math.Random(1),
      );
      expect(picked, hasLength(5));
      expect(picked.toSet(), hasLength(5));
    });

    test('handles an empty pool and a zero count', () {
      expect(
        SrsScheduler.pick<String>([], 3, memoryOf: (_) => null, now: now),
        isEmpty,
      );
      expect(
        SrsScheduler.pick<String>(['a'], 0, memoryOf: (_) => null, now: now),
        isEmpty,
      );
    });

    test('favours the word the child keeps getting wrong', () {
      final pool = ['easy1', 'easy2', 'easy3', 'hard'];
      final known = const WordMemory()
          .answer(correct: true, now: now)
          .answer(correct: true, now: now)
          .answer(correct: true, now: now);
      var hard = const WordMemory();
      for (var i = 0; i < 4; i++) {
        hard = hard.answer(correct: false, now: now);
      }

      WordMemory? memoryOf(String w) => w == 'hard' ? hard : known;

      var hardPicked = 0;
      const trials = 300;
      for (var i = 0; i < trials; i++) {
        final picked = SrsScheduler.pick<String>(
          pool,
          1,
          memoryOf: memoryOf,
          now: now,
          random: math.Random(i),
        );
        if (picked.single == 'hard') hardPicked++;
      }
      // Pure chance would be 25%; weighting should push it far above that.
      expect(hardPicked / trials, greaterThan(0.6));
    });
  });

  group('SrsScheduler.due', () {
    test('lists studied due words, most-missed first, skipping new ones', () {
      var weak = const WordMemory();
      for (var i = 0; i < 3; i++) {
        weak = weak.answer(correct: false, now: now);
      }
      final mild = const WordMemory().answer(correct: false, now: now);
      final memories = {'weak': weak, 'mild': mild};

      final result = SrsScheduler.due<String>(
        ['weak', 'mild', 'brandnew'],
        memoryOf: (w) => memories[w],
        now: now,
      );
      expect(result, ['weak', 'mild']);
    });
  });
}
