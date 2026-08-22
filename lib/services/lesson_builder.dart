import 'dart:math' as math;

import '../models.dart';
import 'progress.dart';
import 'srs.dart';
import 'text_similarity.dart';

/// Builds the actual content of one game round.
///
/// Every game funnels through here so that spaced repetition and distractor
/// quality behave identically across the whole app.
class LessonBuilder {
  const LessonBuilder._();

  /// Chooses which words to ask, weighted towards words that are due for
  /// review or previously missed.
  static List<VocabItem> pickItems(
    List<VocabItem> pool,
    int count, {
    math.Random? random,
    DateTime? now,
  }) {
    if (pool.isEmpty) return const [];
    return SrsScheduler.pick<VocabItem>(
      pool,
      count,
      memoryOf: (item) => Progress.I.memoryFor(item.en),
      now: now ?? DateTime.now(),
      random: random,
    );
  }

  /// Builds the multiple-choice options for [target]: the correct item plus
  /// confusable wrong answers, shuffled.
  static List<VocabItem> optionsFor(
    VocabItem target,
    List<VocabItem> pool, {
    int distractors = 3,
    math.Random? random,
  }) {
    final rnd = random ?? math.Random();
    final wrong = DistractorPicker.pick<VocabItem>(
      target,
      pool,
      distractors,
      labelOf: (item) => item.en,
      random: rnd,
    );
    return <VocabItem>[target, ...wrong]..shuffle(rnd);
  }

  /// Convenience for games that need a review-first ordering rather than a
  /// weighted sample (for example the boss battle).
  static List<VocabItem> dueFirst(
    List<VocabItem> pool, {
    int limit = 10,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final due = SrsScheduler.due<VocabItem>(
      pool,
      memoryOf: (item) => Progress.I.memoryFor(item.en),
      now: at,
    );
    if (due.length >= limit) return due.take(limit).toList();
    final rest = pool.where((item) => !due.contains(item)).toList();
    return [...due, ...rest].take(limit).toList();
  }
}
