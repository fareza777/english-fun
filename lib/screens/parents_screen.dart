import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/stickers.dart';
import '../services/progress.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Parents' dashboard: progress per grade + reset option.
class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Reset Progres?', style: AppText.heading(24)),
        content: Text(
          'Semua bintang, stiker, koin, kostum, dan statistik akan dihapus. Nama pemain tetap tersimpan. Yakin?',
          style: AppText.body(17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: AppText.body(17, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ya, Reset', style: AppText.body(17, color: AppColors.wrong)),
          ),
        ],
      ),
    );
    if (sure == true) {
      await Progress.I.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Column(
          children: [
            const KidAppBar(title: 'Untuk Orang Tua', emoji: '📊', colors: []),
            Expanded(
              child: ListenableBuilder(
                listenable: Progress.I,
                builder: (context, _) {
                  final maxTotal = kGrades.fold(0, (s, g) => s + g.maxStars);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                    children: [
                      Row(
                        children: [
                          _statCard('⭐', '${Progress.I.totalStars}', 'dari $maxTotal bintang'),
                          const SizedBox(width: 12),
                          _statCard('🔥', '${Progress.I.streak}', 'hari beruntun'),
                          const SizedBox(width: 12),
                          _statCard('🎒', '${Progress.I.stickers.length}', 'dari ${kStickers.length} stiker'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard('🎮', '${Progress.I.gamesToday}', 'game hari ini'),
                          const SizedBox(width: 12),
                          _statCard('🏅', '${Progress.I.gamesTotal}', 'total game'),
                          const SizedBox(width: 12),
                          _statCard('🪙', '${Progress.I.coins}', 'koin'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _settingsCard(context),
                      const SizedBox(height: 12),
                      _weakWordsCard(),
                      const SizedBox(height: 18),
                      ...kGrades.map((g) {
                        final earned = Progress.I.gradeStars(g);
                        final done = Progress.I.unitsDone(g);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(g.emoji, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('${g.title} • ${g.subtitle}', style: AppText.heading(19))),
                                  Text('⭐ $earned/${g.maxStars}', style: AppText.body(15)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: g.maxStars == 0 ? 0 : earned / g.maxStars,
                                  minHeight: 12,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(g.colors[0]),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('$done dari ${g.units.length} unit dimainkan', style: AppText.body(14)),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      Center(
                        child: PillButton(
                          label: 'Reset Progres',
                          emoji: '🗑️',
                          color: AppColors.wrong,
                          fontSize: 18,
                          onTap: () => _confirmReset(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Words the child struggles with most (from wrong answers across games).
  Widget _weakWordsCard() {
    final weak = Progress.I.weakWords(limit: 8);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📝 Kata yang Perlu Dilatih', style: AppText.heading(19)),
          const SizedBox(height: 6),
          if (weak.isEmpty)
            Text('Belum ada — hebat! Kata yang sering salah akan muncul di sini.',
                style: AppText.body(14))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in weak)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8EE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.wrong.withOpacity(0.4)),
                    ),
                    child: Text('${e.key} (${e.value}× salah)', style: AppText.body(14)),
                  ),
              ],
            ),
          if (weak.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tips: kata-kata ini otomatis muncul lagi di Boss Battle 🐉',
              style: AppText.body(13, color: AppColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }

  /// Daily goal + accessibility settings.
  Widget _settingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚙️ Pengaturan', style: AppText.heading(19)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('🎯 Target harian (game/hari)', style: AppText.body(15))),
              for (final g in [3, 5, 10])
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text('$g'),
                    selected: Progress.I.dailyGoal == g,
                    onSelected: (_) => Progress.I.setDailyGoal(g),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text('🐢 Kurangi animasi (untuk anak sensitif)', style: AppText.body(15)),
              ),
              Switch(
                value: Progress.I.reducedMotion,
                onChanged: (v) => Progress.I.setReducedMotion(v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String big, String caption) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            Text(big, style: AppText.heading(26)),
            Text(caption, textAlign: TextAlign.center, style: AppText.body(12)),
          ],
        ),
      ),
    );
  }
}
