import 'package:english_fun/data/content.dart';
import 'package:english_fun/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('curriculum has 6 grades with valid content', () {
    expect(kGrades.length, 6);
    final ids = <String>{};
    for (final g in kGrades) {
      expect(g.units, isNotEmpty);
      for (final u in g.units) {
        expect(ids.add(u.id), isTrue, reason: 'duplicate unit id ${u.id}');
        switch (u.kind) {
          case UnitKind.vocab:
            expect(u.items.length, greaterThanOrEqualTo(4), reason: u.id);
            for (final it in u.items) {
              expect(it.en, isNotEmpty, reason: u.id);
              expect(it.idn, isNotEmpty, reason: u.id);
              expect(it.emoji, isNotEmpty, reason: u.id);
            }
          case UnitKind.grammar:
            expect(u.pages, isNotEmpty, reason: u.id);
            var challengeCount = 0;
            for (final p in u.pages) {
              expect(p.examples.isNotEmpty || p.challenges.isNotEmpty, isTrue,
                  reason: '${u.id}/${p.title} is empty');
              for (final c in p.challenges) {
                challengeCount++;
                expect(c.answer, inInclusiveRange(0, c.options.length - 1),
                    reason: '${u.id}/${p.title}');
                expect(c.full, isNotEmpty, reason: '${u.id}/${p.title}');
              }
            }
            // grammar units must be exercise-rich
            expect(challengeCount, greaterThanOrEqualTo(5), reason: '${u.id} needs more challenges');
          case UnitKind.story:
            expect(u.story, isNotNull, reason: u.id);
            expect(u.story!.lines.length, greaterThanOrEqualTo(3), reason: u.id);
            for (final q in u.story!.questions) {
              expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: u.id);
            }
        }
      }
    }
  });

  test('grade 1 has at least 200 flashcards', () {
    final g1 = kGrades.first;
    final cards = g1.units.fold(0, (sum, u) => sum + u.items.length);
    expect(cards, greaterThanOrEqualTo(200), reason: 'grade 1 only has $cards cards');
  });

  test('every vocab unit supports all five games', () {
    for (final g in kGrades) {
      for (final u in g.units.where((x) => x.kind == UnitKind.vocab)) {
        expect(u.hasSpelling, isTrue, reason: '${u.id} needs >=4 spelling items');
        expect(u.games, containsAll(['learn', 'quiz', 'listen', 'memory', 'spell']));
      }
    }
  });

  test('every grade carries enough vocabulary to stay interesting', () {
    // Grade 6 used to ship only 18 cards, which a child finishes in one
    // sitting. Every grade now has to hold a real amount of material.
    for (final g in kGrades) {
      final cards = g.units
          .where((u) => u.kind == UnitKind.vocab)
          .fold(0, (sum, u) => sum + u.items.length);
      expect(cards, greaterThanOrEqualTo(60),
          reason: 'grade ${g.level} only has $cards vocabulary cards');
    }
  });

  test('no vocab unit repeats an English word', () {
    // Duplicates inside a unit would let the distractor picker offer the
    // correct answer twice.
    for (final g in kGrades) {
      for (final u in g.units.where((x) => x.kind == UnitKind.vocab)) {
        final seen = <String>{};
        for (final item in u.items) {
          final key = item.en.trim().toLowerCase();
          expect(seen.add(key), isTrue,
              reason: '${u.id} repeats "${item.en}"');
        }
      }
    }
  });

  test('every vocab unit can build a four-option question', () {
    for (final g in kGrades) {
      for (final u in g.units.where((x) => x.kind == UnitKind.vocab)) {
        expect(u.items.length, greaterThanOrEqualTo(4),
            reason: '${u.id} cannot fill four answer slots');
      }
    }
  });

  test('challenge options never repeat and always name a real answer', () {
    for (final g in kGrades) {
      for (final u in g.units) {
        final challenges = <Challenge>[
          ...u.pages.expand((p) => p.challenges),
          ...?u.story?.questions,
        ];
        for (final c in challenges) {
          expect(c.options.length, greaterThanOrEqualTo(2), reason: u.id);
          expect(c.options.toSet().length, c.options.length,
              reason: '${u.id} repeats an option in "${c.prompt}"');
          expect(c.options[c.answer], isNotEmpty, reason: u.id);
        }
      }
    }
  });

  test('star economy is consistent', () {
    for (final g in kGrades) {
      expect(g.maxStars, greaterThan(0));
      for (final u in g.units) {
        expect(u.maxStars, greaterThan(0), reason: u.id);
        expect(u.games, isNotEmpty, reason: u.id);
      }
    }
  });
}
