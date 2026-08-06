import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:english_fun/data/adventures.dart';
import 'package:english_fun/data/content.dart';
import 'package:english_fun/services/sfx.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dev tool (run with `flutter test test/tools_export_test.dart`):
/// 1. assets/voice/manifest.json  -> every speakable text, for ElevenLabs generation
/// 2. assets/content_export.json  -> full curriculum as data (future remote updates)
void main() {
  test('export voice manifest + content json', () {
    final seen = <String>{};
    final items = <Map<String, String>>[];

    void add(String? text, String voice) {
      final t = (text ?? '').trim();
      if (t.isEmpty || !seen.add(t)) return;
      items.add({
        'id': md5.convert(utf8.encode(t)).toString(),
        'text': t,
        'voice': voice,
      });
    }

    /// Manifest must only reference mp3s that actually got generated,
    /// otherwise the runtime would try (and fail) to play missing assets.
    bool voiceFileExists(String id) =>
        File('assets/voice/$id.mp3').existsSync();

    for (final g in kGrades) {
      for (final u in g.units) {
        add(u.title, 'teach');
        for (final it in u.items) {
          add(it.en, 'teach');
          add(it.sentence, 'teach');
        }
        for (final p in u.pages) {
          add(p.title, 'teach');
          for (final e in p.examples) {
            add(e.en, 'teach');
          }
          for (final c in p.challenges) {
            add(c.full, 'teach');
            for (final o in c.options) {
              add(o, 'teach');
            }
          }
        }
        final s = u.story;
        if (s != null) {
          add(s.title, 'story');
          for (final l in s.lines) {
            add(l.en, 'story');
          }
          for (final q in s.questions) {
            add(q.prompt, 'story');
            add(q.full, 'teach');
            for (final o in q.options) {
              add(o, 'teach');
            }
          }
        }
      }
    }
    for (final p in Sfx.praises) {
      add(p, 'praise');
    }
    add('Great!', 'praise');
    add('Try again!', 'praise');

    // branching stories + Simon Says
    for (final adv in kAdventures) {
      add(adv.title, 'story');
      for (final node in adv.nodes.values) {
        add(node.en, 'story');
        for (final c in node.choices) {
          add(c.text, 'teach');
        }
      }
    }
    for (final cmd in kSimonCommands) {
      add(cmd.$1, 'teach');
      add('Simon says: ${cmd.$1}', 'teach');
    }
    add('Simon did not say! Good job!', 'praise');
    add('Simon did not say that!', 'praise');
    add('You got an egg!', 'praise');
    add('Yummy! Thank you!', 'praise');
    add('Looking good!', 'praise');
    add('Awesome! New hat!', 'praise');
    add('Finish all units first!', 'teach');
    add('Boss battle! Defeat the dragon!', 'teach');

    Directory('assets/voice').createSync(recursive: true);
    // full list -> input for tools/gen_voice.py
    File('assets/voice/manifest_full.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({'items': items}));
    // filtered list -> bundled with the app (only voices that exist on disk)
    final bundled = items.where((e) => voiceFileExists(e['id']!)).toList();
    File('assets/voice/manifest.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({'items': bundled}));
    final chars = items.fold<int>(0, (s, e) => s + (e['text']!.length));

    // ---- full curriculum export (data-driven hook) ----
    final gradesJson = [
      for (final g in kGrades)
        {
          'level': g.level,
          'title': g.title,
          'subtitle': g.subtitle,
          'emoji': g.emoji,
          'colors': [for (final c in g.colors) c.toARGB32()],
          'units': [
            for (final u in g.units)
              {
                'id': u.id,
                'title': u.title,
                'titleId': u.titleId,
                'emoji': u.emoji,
                'kind': u.kind.name,
                'games': u.games,
                'items': [
                  for (final it in u.items)
                    {
                      'en': it.en,
                      'idn': it.idn,
                      'emoji': it.emoji,
                      if (it.big != null) 'big': it.big,
                      if (it.sentence != null) 'sentence': it.sentence,
                    }
                ],
                'pages': [
                  for (final p in u.pages)
                    {
                      'title': p.title,
                      'explain': p.explain,
                      'examples': [
                        for (final e in p.examples)
                          {'en': e.en, 'idn': e.idn, 'emoji': e.emoji}
                      ],
                      'challenges': [
                        for (final c in p.challenges)
                          {
                            'prompt': c.prompt,
                            'options': c.options,
                            'answer': c.answer,
                            'full': c.full,
                          }
                      ],
                    }
                ],
                if (u.story != null)
                  'story': {
                    'title': u.story!.title,
                    'emoji': u.story!.emoji,
                    'lines': [
                      for (final l in u.story!.lines)
                        {'en': l.en, 'idn': l.idn, 'emoji': l.emoji}
                    ],
                    'questions': [
                      for (final q in u.story!.questions)
                        {'prompt': q.prompt, 'options': q.options, 'answer': q.answer, 'full': q.full}
                    ],
                  },
              }
          ],
        }
    ];
    File('assets/content_export.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({'grades': gradesJson}));

    // ignore: avoid_print
    print('VOICE_EXPORT: ${items.length} texts, $chars chars');
    expect(items.length, greaterThan(500));
  });
}
