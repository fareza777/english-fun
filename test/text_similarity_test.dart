import 'dart:math' as math;

import 'package:english_fun/services/text_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('levenshtein', () {
    test('computes known distances', () {
      expect(TextSimilarity.levenshtein('cat', 'cat'), 0);
      expect(TextSimilarity.levenshtein('cat', 'cap'), 1);
      expect(TextSimilarity.levenshtein('cat', 'cup'), 2);
      expect(TextSimilarity.levenshtein('kitten', 'sitting'), 3);
    });

    test('is symmetric and handles empty strings', () {
      expect(TextSimilarity.levenshtein('abc', ''), 3);
      expect(TextSimilarity.levenshtein('', 'abc'), 3);
      expect(
        TextSimilarity.levenshtein('elephant', 'relevant'),
        TextSimilarity.levenshtein('relevant', 'elephant'),
      );
    });
  });

  group('soundsLike', () {
    test('accepts exact and near matches the way a patient teacher would', () {
      expect(TextSimilarity.soundsLike('Apple', 'apple'), isTrue);
      expect(TextSimilarity.soundsLike('  apple!  ', 'apple'), isTrue);
      expect(TextSimilarity.soundsLike('the apple', 'apple'), isTrue);
      expect(TextSimilarity.soundsLike('aple', 'apple'), isTrue); // one typo
    });

    test('rejects genuinely different words', () {
      expect(TextSimilarity.soundsLike('banana', 'apple'), isFalse);
      expect(TextSimilarity.soundsLike('', 'apple'), isFalse);
    });

    test('does not accept a one-typo match on very short words', () {
      // "cat" vs "cap" is a real distinction worth correcting.
      expect(TextSimilarity.soundsLike('cap', 'cat'), isFalse);
    });
  });

  group('confusability', () {
    test('scores lookalikes above unrelated words', () {
      final close = TextSimilarity.confusability('cat', 'cap');
      final far = TextSimilarity.confusability('cat', 'refrigerator');
      expect(close, greaterThan(far));
    });

    test('is zero for the word itself', () {
      expect(TextSimilarity.confusability('cat', 'cat'), 0);
      expect(TextSimilarity.confusability('cat', ''), 0);
    });
  });

  group('DistractorPicker', () {
    final pool = [
      'cat', 'cap', 'cup', 'car', 'can',
      'refrigerator', 'helicopter', 'mountain', 'umbrella',
    ];

    test('never includes the target', () {
      for (var seed = 0; seed < 30; seed++) {
        final picked = DistractorPicker.pick<String>(
          'cat',
          pool,
          3,
          labelOf: (s) => s,
          random: math.Random(seed),
        );
        expect(picked, isNot(contains('cat')));
        expect(picked, hasLength(3));
        expect(picked.toSet(), hasLength(3), reason: 'options must be distinct');
      }
    });

    test('prefers confusable words over unrelated long ones', () {
      const lookalikes = {'cap', 'cup', 'car', 'can'};
      var lookalikeCount = 0;
      var total = 0;
      for (var seed = 0; seed < 60; seed++) {
        final picked = DistractorPicker.pick<String>(
          'cat',
          pool,
          3,
          labelOf: (s) => s,
          random: math.Random(seed),
        );
        lookalikeCount += picked.where(lookalikes.contains).length;
        total += picked.length;
      }
      expect(lookalikeCount / total, greaterThan(0.75));
    });

    test('degrades gracefully when the pool is tiny', () {
      final picked = DistractorPicker.pick<String>(
        'cat',
        ['cat', 'dog'],
        3,
        labelOf: (s) => s,
        random: math.Random(0),
      );
      expect(picked, ['dog']);
    });

    test('filters duplicates of the target that differ only by case', () {
      final picked = DistractorPicker.pick<String>(
        'cat',
        ['cat', 'CAT', ' Cat ', 'dog'],
        3,
        labelOf: (s) => s,
        random: math.Random(0),
      );
      expect(picked, ['dog']);
    });

    test('returns nothing when asked for nothing', () {
      expect(
        DistractorPicker.pick<String>('cat', pool, 0, labelOf: (s) => s),
        isEmpty,
      );
    });
  });
}
