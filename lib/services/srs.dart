import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// What the app remembers about one English word.
///
/// Immutable: every update returns a new instance, so state changes are
/// always explicit and easy to reason about.
@immutable
class WordMemory {
  /// Leitner box, 0 = brand new / just failed, [maxBox] = well known.
  final int box;

  /// Lifetime counters, used for the "weak words" parent report.
  final int wrong;
  final int correct;

  /// When this word should next be reviewed. Null = never studied.
  final DateTime? due;
  final DateTime? lastSeen;

  static const maxBox = 5;

  /// Days to wait per box. Index = box the word landed in after answering.
  static const List<int> intervalDays = [0, 1, 2, 4, 7, 14];

  const WordMemory({
    this.box = 0,
    this.wrong = 0,
    this.correct = 0,
    this.due,
    this.lastSeen,
  });

  bool get isNew => lastSeen == null;

  /// True when the word is ready for review.
  bool isDue(DateTime now) => due == null || !due!.isAfter(now);

  /// A word is "weak" while it still has unhealed mistakes.
  bool get isWeak => wrong > correct || box == 0 && wrong > 0;

  /// Promotes on a correct answer, demotes hard on a wrong one.
  ///
  /// Wrong answers drop straight back to box 0: for young learners a missed
  /// word should come back very soon, not three days later.
  WordMemory answer({required bool correct, required DateTime now}) {
    final nextBox = correct ? math.min(box + 1, maxBox) : 0;
    return WordMemory(
      box: nextBox,
      wrong: correct ? wrong : wrong + 1,
      correct: correct ? this.correct + 1 : this.correct,
      due: now.add(Duration(days: intervalDays[nextBox])),
      lastSeen: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'b': box,
        'w': wrong,
        'c': correct,
        if (due != null) 'd': due!.millisecondsSinceEpoch,
        if (lastSeen != null) 'l': lastSeen!.millisecondsSinceEpoch,
      };

  static WordMemory? fromJson(Object? raw) {
    if (raw is! Map) return null;
    int asInt(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
    DateTime? asDate(Object? v) =>
        v == null ? null : DateTime.fromMillisecondsSinceEpoch(asInt(v));
    return WordMemory(
      box: asInt(raw['b']).clamp(0, maxBox),
      wrong: asInt(raw['w']),
      correct: asInt(raw['c']),
      due: asDate(raw['d']),
      lastSeen: asDate(raw['l']),
    );
  }

  /// Builds a memory from the legacy v2 "wrong counter" map so existing
  /// players keep their history when they update the app.
  factory WordMemory.fromLegacyWrongCount(int wrong) =>
      WordMemory(box: 0, wrong: wrong, correct: 0);
}

/// Chooses which words a game should ask, based on spaced repetition.
///
/// Pure and side-effect free so it can be unit tested without any plugins.
class SrsScheduler {
  const SrsScheduler._();

  /// Relative chance a word gets picked.
  ///
  /// Overdue and previously-failed words dominate, brand new words come
  /// next, and well-known words still appear occasionally so the child feels
  /// successful rather than only ever facing their hardest material.
  static double weight(WordMemory? memory, DateTime now) {
    if (memory == null || memory.isNew) return 3.0;
    if (!memory.isDue(now)) return 0.6;
    final overdueBoost = math.min(memory.wrong, 5) * 1.6;
    final boxRelief = memory.box * 0.7; // known words need less drilling
    return math.max(1.0, 6.0 + overdueBoost - boxRelief);
  }

  /// Picks [count] distinct items, favouring words that need review.
  ///
  /// Uses weighted sampling without replacement. Falls back gracefully when
  /// the pool is smaller than [count].
  static List<T> pick<T>(
    List<T> pool,
    int count, {
    required WordMemory? Function(T item) memoryOf,
    required DateTime now,
    math.Random? random,
  }) {
    if (pool.isEmpty || count <= 0) return const [];
    final rnd = random ?? math.Random();
    final remaining = List<T>.of(pool);
    final weights = [
      for (final item in remaining) weight(memoryOf(item), now),
    ];
    final wanted = math.min(count, remaining.length);
    final picked = <T>[];

    for (var n = 0; n < wanted; n++) {
      var total = 0.0;
      for (final w in weights) {
        total += w;
      }
      if (total <= 0) {
        picked.add(remaining.removeAt(rnd.nextInt(remaining.length)));
        weights.removeAt(0);
        continue;
      }
      var threshold = rnd.nextDouble() * total;
      var index = weights.length - 1;
      for (var i = 0; i < weights.length; i++) {
        threshold -= weights[i];
        if (threshold <= 0) {
          index = i;
          break;
        }
      }
      picked.add(remaining.removeAt(index));
      weights.removeAt(index);
    }
    return picked;
  }

  /// Words that are due right now, most urgent first.
  static List<T> due<T>(
    List<T> pool, {
    required WordMemory? Function(T item) memoryOf,
    required DateTime now,
  }) {
    final entries = pool.where((item) {
      final memory = memoryOf(item);
      return memory != null && !memory.isNew && memory.isDue(now);
    }).toList();
    entries.sort((a, b) {
      final wa = memoryOf(a)?.wrong ?? 0;
      final wb = memoryOf(b)?.wrong ?? 0;
      return wb.compareTo(wa);
    });
    return entries;
  }
}
