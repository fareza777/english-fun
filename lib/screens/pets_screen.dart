import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/pets.dart';
import '../models.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

/// "Peliharaan" — buy eggs, hatch surprise pets, feed them daily by
/// answering 3 quick word questions.
class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  Pet? _justHatched;

  void _buyEgg() {
    if (Progress.I.buyEgg(40)) {
      Sfx.I.pop();
      Sfx.I.speak('You got an egg!');
    } else {
      Sfx.I.wrong();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.wrong,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(
            'Koin kurang! Main game untuk kumpulkan koin. 🪙',
            style: AppText.body(16, color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _hatch() async {
    Sfx.I.flip();
    final pet = rollPet(Progress.I.pets);
    // egg shake suspense
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Progress.I.hatchEgg(pet.id);
    setState(() => _justHatched = pet);
    Sfx.I.win();
    Sfx.I.speak('It is ${pet.name}!');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justHatched = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        world: 1,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Progress.I,
            builder: (context, _) {
              final p = Progress.I;
              return Column(
                children: [
                  KidAppBar(
                    title: 'Peliharaanku',
                    emoji: '🥚',
                    colors: const [],
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text('${p.coins}', style: AppText.heading(17)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // egg zone
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BouncyButton(
                        onTap: p.eggs > 0 ? _hatch : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(_justHatched?.id ?? '🥚', style: const TextStyle(fontSize: 44)),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _justHatched != null
                                        ? 'Menetas: ${_justHatched!.name}!'
                                        : (p.eggs > 0
                                              ? 'Telur: ${p.eggs} — ketuk untuk menetas!'
                                              : 'Belum punya telur'),
                                    style: AppText.heading(17),
                                  ),
                                  if (p.eggs == 0)
                                    Text('Beli dengan 40 koin 👉', style: AppText.body(13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      BouncyButton(
                        onTap: _buyEgg,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4361EE),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Color(0x554361EE), offset: Offset(0, 4)),
                            ],
                          ),
                          child: Text(
                            '+ 🥚\n🪙40',
                            textAlign: TextAlign.center,
                            style: AppText.display(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // feed button
                  if (p.pets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: PillButton(
                        label: p.canFeedToday
                            ? 'Beri Makan (kuis 3 kata) 🍎'
                            : 'Sudah kenyang hari ini 😋',
                        emoji: '🍽️',
                        color: p.canFeedToday ? AppColors.correct : Colors.grey.shade400,
                        fontSize: 18,
                        onTap: p.canFeedToday ? () => _startFeeding(context) : null,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: context.isTablet ? 5 : 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: kPets.length,
                      itemBuilder: (context, i) {
                        final pet = kPets[i];
                        final owned = p.pets.contains(pet.id);
                        final active = p.activePet == pet.id;
                        return BouncyButton(
                          onTap: owned ? () => p.setActivePet(pet.id) : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFFFFF3D6) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active ? AppColors.star : Colors.transparent,
                                width: 4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  owned ? pet.id : '❓',
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: owned ? null : Colors.grey.shade400,
                                  ),
                                ),
                                Text(
                                  owned ? pet.name.split(' ').first : '???',
                                  style: AppText.heading(14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (active)
                                  Text(
                                    'Teman main ✓',
                                    style: AppText.body(11, color: AppColors.correct),
                                  ),
                                if (owned && !active)
                                  Text('ketuk: pilih', style: AppText.body(11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Feeding = 3 quick questions (weak words first), then coins + full tummy.
  void _startFeeding(BuildContext context) {
    final weak = Progress.I.weakWords(limit: 3).map((e) => e.key).toList();
    final allItems = kGrades.expand((g) => g.units).expand((u) => u.items).toList();
    final picked = <VocabItem>[];
    for (final w in weak) {
      final match = allItems.where((it) => it.en.toLowerCase() == w);
      if (match.isNotEmpty) picked.add(match.first);
    }
    allItems.shuffle();
    for (final it in allItems) {
      if (picked.length >= 3) break;
      if (!picked.contains(it)) picked.add(it);
    }
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FeedingSheet(
        items: picked,
        onDone: (success) {
          Navigator.of(sheetContext).pop();
          if (success) {
            Progress.I.markFedToday();
            Progress.I.addCoins(10);
            Sfx.I.win();
            Sfx.I.speak('Yummy! Thank you!');
          }
        },
      ),
    );
  }
}

class _FeedingSheet extends StatefulWidget {
  final List<VocabItem> items;
  final void Function(bool success) onDone;
  const _FeedingSheet({required this.items, required this.onDone});

  @override
  State<_FeedingSheet> createState() => _FeedingSheetState();
}

class _FeedingSheetState extends State<_FeedingSheet> {
  int _index = 0;
  int _correct = 0;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _buildOptions();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) Sfx.I.speak(widget.items[0].en);
    });
  }

  void _buildOptions() {
    final current = widget.items[_index];
    final others = widget.items.where((e) => e.en != current.en).map((e) => e.en).toList();
    _options = [current.en, ...others]..shuffle();
  }

  void _answer(String word) {
    final current = widget.items[_index];
    if (word == current.en) {
      _correct++;
      Sfx.I.ding();
    } else {
      Sfx.I.wrong();
    }
    if (_index + 1 >= widget.items.length) {
      widget.onDone(_correct >= 2);
    } else {
      setState(() {
        _index++;
        _buildOptions();
      });
      Sfx.I.speak(widget.items[_index].en);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Beri makan peliharaanmu! 🍎', style: AppText.heading(22)),
          Text(
            'Soal ${_index + 1}/${widget.items.length}: apa bahasa Inggrisnya?',
            style: AppText.body(15),
          ),
          const SizedBox(height: 10),
          Text(item.emoji, style: const TextStyle(fontSize: 64)),
          Text(item.idn, style: AppText.heading(24)),
          const SizedBox(height: 12),
          for (final opt in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PillButton(
                label: opt,
                emoji: '🍎',
                color: const Color(0xFF43AA8B),
                fontSize: 19,
                onTap: () => _answer(opt),
              ),
            ),
        ],
      ),
    );
  }
}
