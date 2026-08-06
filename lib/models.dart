import 'package:flutter/material.dart';

/// Compact builders for content files.
VocabItem v(String en, String idn, String emoji, {String? big, String? sentence}) =>
    VocabItem(en, idn, emoji, big: big, sentence: sentence);

GrammarExample ge(String en, String idn, String emoji) => GrammarExample(en, idn, emoji);

Challenge ch(String prompt, List<String> options, int answer, String full) =>
    Challenge(prompt, options, answer, full);

/// One vocabulary card: English word, Indonesian meaning, picture emoji.
class VocabItem {
  final String en;
  final String idn;
  final String emoji;
  final String? big; // optional big display override (e.g. "Aa" or "7")
  final String? sentence; // optional example sentence
  const VocabItem(this.en, this.idn, this.emoji, {this.big, this.sentence});
}

class GrammarExample {
  final String en;
  final String idn;
  final String emoji;
  const GrammarExample(this.en, this.idn, this.emoji);
}

/// A fill-in-the-blank style mini question.
class Challenge {
  final String prompt; // e.g. "She ___ happy."
  final List<String> options;
  final int answer;
  final String full; // full correct sentence, spoken by TTS
  const Challenge(this.prompt, this.options, this.answer, this.full);
}

class GrammarPage {
  final String title;
  final String explain; // short kid-friendly Indonesian explanation
  final List<GrammarExample> examples;
  final List<Challenge> challenges;
  const GrammarPage({
    required this.title,
    required this.explain,
    this.examples = const [],
    this.challenges = const [],
  });
}

class StoryLine {
  final String en;
  final String idn;
  final String emoji;
  const StoryLine(this.en, this.idn, this.emoji);
}

class Story {
  final String title;
  final String emoji;
  final List<StoryLine> lines;
  final List<Challenge> questions;
  const Story({
    required this.title,
    required this.emoji,
    required this.lines,
    required this.questions,
  });
}

enum UnitKind { vocab, grammar, story }

class Unit {
  final String id;
  final String title;
  final String titleId;
  final String emoji;
  final UnitKind kind;
  final List<VocabItem> items;
  final List<GrammarPage> pages;
  final Story? story;

  const Unit.vocab({
    required this.id,
    required this.title,
    required this.titleId,
    required this.emoji,
    required this.items,
  })  : kind = UnitKind.vocab,
        pages = const [],
        story = null;

  const Unit.grammar({
    required this.id,
    required this.title,
    required this.titleId,
    required this.emoji,
    required this.pages,
  })  : kind = UnitKind.grammar,
        items = const [],
        story = null;

  const Unit.story({
    required this.id,
    required this.title,
    required this.titleId,
    required this.emoji,
    required this.story,
  })  : kind = UnitKind.story,
        items = const [],
        pages = const [];

  /// Spelling needs single words of 3-8 plain letters.
  List<VocabItem> get spellingItems => items.where((e) {
        final letters = e.en.replaceAll(' ', '');
        return letters.length >= 3 &&
            letters.length <= 8 &&
            RegExp(r'^[A-Za-z ]+$').hasMatch(e.en);
      }).toList();

  bool get hasSpelling => kind == UnitKind.vocab && spellingItems.length >= 4;

  /// Game ids available for this unit.
  List<String> get games {
    switch (kind) {
      case UnitKind.vocab:
        return [
          'learn',
          'quiz',
          'listen',
          'speak',
          'memory',
          if (hasSpelling) 'spell',
        ];
      case UnitKind.grammar:
        return const ['learn', 'build'];
      case UnitKind.story:
        return const ['read', 'quiz'];
    }
  }

  int get maxStars {
    switch (kind) {
      case UnitKind.vocab:
        return 1 + 3 + 3 + 3 + 3 + (hasSpelling ? 3 : 0);
      case UnitKind.grammar:
        return 3 + 3;
      case UnitKind.story:
        return 4;
    }
  }
}

class Grade {
  final int level;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;
  final List<Unit> units;
  const Grade({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
    required this.units,
  });

  int get maxStars => units.fold(0, (sum, u) => sum + u.maxStars);
}
