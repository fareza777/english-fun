import 'dart:math' as math;

/// Shared string helpers for matching speech, scoring spelling, and building
/// quiz distractors. Pure functions only, so everything here is unit testable.
class TextSimilarity {
  const TextSimilarity._();

  /// Lowercase, letters and single spaces only.
  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[^a-z ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Classic edit distance, O(min(a,b)) memory.
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    if (a.length > b.length) return levenshtein(b, a);

    var row = List<int>.generate(a.length + 1, (i) => i);
    for (var j = 1; j <= b.length; j++) {
      var prev = row[0];
      row[0] = j;
      for (var i = 1; i <= a.length; i++) {
        final cur = row[i];
        row[i] = math.min(
          math.min(row[i] + 1, row[i - 1] + 1),
          prev + (a[i - 1] == b[j - 1] ? 0 : 1),
        );
        prev = cur;
      }
    }
    return row[a.length];
  }

  /// Generous kid-friendly speech match: exact, contained, or one typo away.
  static bool soundsLike(String heard, String target) {
    final h = normalize(heard);
    final t = normalize(target);
    if (h.isEmpty || t.isEmpty) return false;
    if (h == t) return true;
    if (h.split(' ').contains(t)) return true;
    if (t.contains(' ') && h.contains(t)) return true;
    if (t.length >= 4 && levenshtein(h, t) <= 1) return true;
    return false;
  }

  /// How confusable [candidate] is with [target] — higher means a better
  /// (i.e. more educational) wrong answer.
  ///
  /// A good distractor forces the child to actually read the word instead of
  /// spotting the only plausible option. Words that look or sound close
  /// score highest: "cap" and "cup" are far better foils for "cat" than
  /// "refrigerator" is.
  static int confusability(String target, String candidate) {
    final t = normalize(target);
    final c = normalize(candidate);
    if (t.isEmpty || c.isEmpty || t == c) return 0;

    var score = 0;
    final distance = levenshtein(t, c);
    if (distance == 1) {
      score += 6;
    } else if (distance == 2) {
      score += 4;
    } else if (distance == 3) {
      score += 2;
    }

    if (t[0] == c[0]) score += 2;
    if (t[t.length - 1] == c[c.length - 1]) score += 1;

    final lengthGap = (t.length - c.length).abs();
    if (lengthGap == 0) {
      score += 2;
    } else if (lengthGap == 1) {
      score += 1;
    }

    if (t.length >= 2 && c.length >= 2 && t.substring(0, 2) == c.substring(0, 2)) {
      score += 2;
    }
    return score;
  }
}

/// Builds the wrong answers shown next to a correct one.
class DistractorPicker {
  const DistractorPicker._();

  /// Chooses [count] wrong options for [target] out of [pool].
  ///
  /// Ranks the pool by [TextSimilarity.confusability], keeps a shortlist of
  /// the closest matches, then samples from that shortlist so the same word
  /// does not produce an identical question every single time.
  static List<T> pick<T>(
    T target,
    List<T> pool,
    int count, {
    required String Function(T item) labelOf,
    math.Random? random,
  }) {
    if (count <= 0) return const [];
    final rnd = random ?? math.Random();
    final targetLabel = labelOf(target);

    final candidates = pool
        .where((item) =>
            !identical(item, target) &&
            TextSimilarity.normalize(labelOf(item)) !=
                TextSimilarity.normalize(targetLabel))
        .toList();
    if (candidates.length <= count) {
      return (candidates..shuffle(rnd)).take(count).toList();
    }

    final scored = candidates
        .map((item) => (
              item: item,
              score: TextSimilarity.confusability(targetLabel, labelOf(item)),
            ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Shortlist is slightly wider than needed so sessions stay varied, but
    // narrow enough that the options remain genuinely confusable. Two spare
    // slots give plenty of combinations without diluting the ranking.
    final shortlistSize = math.min(candidates.length, count + 2);
    final shortlist = scored.take(shortlistSize).map((e) => e.item).toList()
      ..shuffle(rnd);
    return shortlist.take(count).toList();
  }
}
