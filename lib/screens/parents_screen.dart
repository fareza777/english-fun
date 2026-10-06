import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/stickers.dart';
import '../services/consent.dart';
import '../services/error_reporter.dart';
import '../services/monetization.dart';
import '../services/progress.dart';
import '../theme.dart';
import '../widgets/adult_gate.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'diagnostics_screen.dart';
import 'about_screen.dart';
import 'onboarding_screen.dart';
import 'privacy_screen.dart';

/// Parents' dashboard: progress per grade + reset option.
class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    // Destructive and irreversible: an adult must approve it.
    final approved = await AdultGate.show(
      context,
      reason:
          'Menghapus seluruh progres belajar anak. Tindakan ini tidak bisa dibatalkan.',
    );
    if (!approved || !context.mounted) return;

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
            child: Text(
              'Ya, Reset',
              style: AppText.body(17, color: AppColors.wrong),
            ),
          ),
        ],
      ),
    );
    if (sure == true) {
      await Progress.I.reset();
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final approved = await AdultGate.show(
      context,
      reason: 'Mengganti nama profil dan mengulangi panduan onboarding.',
    );
    if (!approved || !context.mounted) return;

    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Ganti Profil?', style: AppText.heading(24)),
        content: Text(
          'Nama dan panduan onboarding akan diulang. Progres belajar tetap tersimpan.',
          style: AppText.body(17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: AppText.body(17, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Ya, Ganti Profil',
              style: AppText.body(17, color: AppColors.correct),
            ),
          ),
        ],
      ),
    );
    if (sure != true) return;

    await Progress.I.logout();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(funRoute(const OnboardingScreen()), (_) => false);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final approved = await AdultGate.show(
      context,
      reason: 'Menghapus profil dan seluruh data belajar di perangkat ini.',
    );
    if (!approved || !context.mounted) return;

    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus Akun & Data?', style: AppText.heading(24)),
        content: Text(
          'Nama, progres, bintang, koleksi, statistik, dan pengaturan lokal akan dihapus. Pembelian Hapus Iklan tetap tersedia melalui akun Google Play. Tindakan ini tidak bisa dibatalkan.',
          style: AppText.body(17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: AppText.body(17, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Ya, Hapus Semua',
              style: AppText.body(17, color: AppColors.wrong),
            ),
          ),
        ],
      ),
    );
    if (sure != true) return;

    await Progress.I.deleteAccount();
    await ErrorReporter.I.clear();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(funRoute(const OnboardingScreen()), (_) => false);
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
                  return ContentWidth(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                      children: [
                        Row(
                          children: [
                            _statCard(
                              '⭐',
                              '${Progress.I.totalStars}',
                              'dari $maxTotal bintang',
                            ),
                            const SizedBox(width: 12),
                            _statCard(
                              '🔥',
                              '${Progress.I.streak}',
                              'hari beruntun',
                            ),
                            const SizedBox(width: 12),
                            _statCard(
                              '🎒',
                              '${Progress.I.stickers.length}',
                              'dari ${kStickers.length} stiker',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statCard(
                              '🎮',
                              '${Progress.I.gamesToday}',
                              'game hari ini',
                            ),
                            const SizedBox(width: 12),
                            _statCard(
                              '🏅',
                              '${Progress.I.gamesTotal}',
                              'total game',
                            ),
                            const SizedBox(width: 12),
                            _statCard('🪙', '${Progress.I.coins}', 'koin'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _settingsCard(context),
                        const SizedBox(height: 12),
                        _adFreeCard(context),
                        const SizedBox(height: 12),
                        _weakWordsCard(),
                        const SizedBox(height: 12),
                        _privacyCard(context),
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
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      g.emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${g.title} • ${g.subtitle}',
                                        style: AppText.heading(19),
                                      ),
                                    ),
                                    Text(
                                      '⭐ $earned/${g.maxStars}',
                                      style: AppText.body(15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: g.maxStars == 0
                                        ? 0
                                        : earned / g.maxStars,
                                    minHeight: 12,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                      g.colors[0],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$done dari ${g.units.length} unit dimainkan',
                                  style: AppText.body(14),
                                ),
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Privacy policy, ad consent choices, and the on-device error log.
  Widget _privacyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔒 Privasi & Bantuan', style: AppText.heading(19)),
          const SizedBox(height: 4),
          _linkRow(
            context,
            icon: Icons.privacy_tip_outlined,
            label: 'Kebijakan Privasi',
            onTap: () =>
                Navigator.of(context).push(funRoute(const PrivacyScreen())),
          ),
          if (ConsentService.I.privacyOptionsRequired)
            _linkRow(
              context,
              icon: Icons.tune_rounded,
              label: 'Pilihan Iklan & Persetujuan',
              onTap: ConsentService.I.showPrivacyOptions,
            ),
          _linkRow(
            context,
            icon: Icons.health_and_safety_outlined,
            label:
                'Diagnostik'
                '${ErrorReporter.I.hasRecords ? ' (${ErrorReporter.I.records.length})' : ''}',
            onTap: () =>
                Navigator.of(context).push(funRoute(const DiagnosticsScreen())),
          ),
          _linkRow(
            context,
            icon: Icons.auto_awesome_rounded,
            label: 'Tentang English Fun',
            onTap: () =>
                Navigator.of(context).push(funRoute(const AboutScreen())),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.inkSoft, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppText.body(15))),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _adFreeCard(BuildContext context) {
    return ListenableBuilder(
      listenable: MonetizationService.I,
      builder: (context, _) {
        final service = MonetizationService.I;
        final removed = service.adsRemoved;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF3C4), Color(0xFFFFE8A3)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFC857), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                removed ? '✅ Mode tanpa iklan aktif' : '✨ Belajar tanpa iklan',
                style: AppText.heading(19),
              ),
              const SizedBox(height: 5),
              Text(
                removed
                    ? 'Terima kasih! Iklan tidak akan tampil di perangkat ini.'
                    : 'Hapus banner iklan sekali bayar dan buat sesi belajar lebih nyaman.',
                style: AppText.body(14),
              ),
              if (!removed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: 'Hapus Iklan ${service.removeAdsPrice}',
                        emoji: '🛡️',
                        color: AppColors.correct,
                        fontSize: 16,
                        onTap: () async {
                          final approved = await AdultGate.show(
                            context,
                            reason:
                                'Melakukan pembelian dalam aplikasi '
                                '(${service.removeAdsPrice}) melalui Google Play.',
                          );
                          if (!approved || !context.mounted) return;
                          final started = await service.buyRemoveAds();
                          if (!context.mounted || started) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Produk belum siap. Coba lagi setelah Play Store terhubung.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Pulihkan pembelian',
                      onPressed: service.storeAvailable
                          ? service.restorePurchases
                          : null,
                      icon: const Icon(Icons.restore_rounded),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📝 Kata yang Perlu Dilatih', style: AppText.heading(19)),
          const SizedBox(height: 6),
          if (weak.isEmpty)
            Text(
              'Belum ada — hebat! Kata yang sering salah akan muncul di sini.',
              style: AppText.body(14),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in weak)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8EE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.wrong.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${e.key} (${e.value}× salah)',
                      style: AppText.body(14),
                    ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚙️ Pengaturan', style: AppText.heading(19)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '🎯 Target harian (game/hari)',
                  style: AppText.body(15),
                ),
              ),
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
                child: Text(
                  '🐢 Kurangi animasi (untuk anak sensitif)',
                  style: AppText.body(15),
                ),
              ),
              Switch(
                value: Progress.I.reducedMotion,
                onChanged: (v) => Progress.I.setReducedMotion(v),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _linkRow(
            context,
            icon: Icons.logout_rounded,
            label: 'Ganti Profil & Ulangi Onboarding',
            onTap: () => _confirmLogout(context),
          ),
          _linkRow(
            context,
            icon: Icons.delete_forever_rounded,
            label: 'Hapus Akun & Semua Data Lokal',
            onTap: () => _confirmDeleteAccount(context),
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
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
