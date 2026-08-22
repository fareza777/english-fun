import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/ad_diagnostics.dart';
import '../services/consent.dart';
import '../services/error_reporter.dart';
import '../services/monetization.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

/// Shows the rolling error log so a parent can report a problem with real
/// detail instead of "it just closes".
///
/// Sits behind the adult gate together with the rest of the parents' area.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  @override
  Widget build(BuildContext context) {
    final records = ErrorReporter.I.records;
    return Scaffold(
      body: AnimatedBackground(
        child: Column(
          children: [
            KidAppBar(
              title: 'Diagnostik',
              emoji: '🩺',
              colors: const [],
              trailing: records.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Salin semua',
                      icon: const Icon(Icons.copy_rounded, color: AppColors.ink),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: ErrorReporter.I.exportAsText()),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Log disalin')));
                      },
                    ),
            ),
            Expanded(
              child: ContentWidth(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                  children: [
                    const _AdStatusCard(),
                    const SizedBox(height: 14),
                    if (records.isEmpty)
                      _empty()
                    else ...[
                      Text(
                        '${records.length} kejadian terakhir tersimpan di perangkat ini. '
                        'Tidak ada yang dikirim ke mana pun.',
                        style: AppText.body(15),
                      ),
                      const SizedBox(height: 12),
                      ...records.map(_recordCard),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await ErrorReporter.I.clear();
                            if (mounted) setState(() {});
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text('Hapus log', style: AppText.body(16)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            'Tidak ada masalah tercatat',
            style: AppText.heading(20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'App berjalan tanpa error sejak terakhir dibuka.',
            style: AppText.body(16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _recordCard(ErrorRecord record) {
    final time = record.time;
    final stamp =
        '${time.day}/${time.month} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Theme(
        // Keep the chunky app style rather than the default divider look.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (_) => Sfx.I.click(),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Text(record.fatal ? '🛑' : '⚠️', style: const TextStyle(fontSize: 24)),
          title: Text(record.shortError, style: AppText.body(14)),
          subtitle: Text(
            '$stamp • ${record.context.isEmpty ? 'app' : record.context}',
            style: AppText.body(12, color: Colors.grey),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            if (record.stack.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  record.stack,
                  style: const TextStyle(fontSize: 11, height: 1.35),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Live answer to "kenapa tidak ada iklan?": SDK state, consent state, and
/// per-slot load results, all collected by [AdDiagnostics] from the real ad
/// callbacks. Read-only; refreshes itself as callbacks arrive.
class _AdStatusCard extends StatelessWidget {
  const _AdStatusCard();

  static String _stamp(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AdDiagnostics.I,
        MonetizationService.I,
        ConsentService.I,
      ]),
      builder: (context, _) {
        final ads = AdDiagnostics.I;
        final money = MonetizationService.I;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
                  const Text('📢', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text('Status Iklan', style: AppText.heading(18)),
                  const Spacer(),
                  if (MonetizationService.useTestUnits)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'MODE UJI COBA',
                        style: AppText.heading(11, color: AppColors.star),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _row(
                'SDK iklan',
                ads.sdkReady
                    ? 'Siap ✅'
                    : ads.sdkInitFailed
                        ? 'Gagal inisialisasi 🛑 (lihat log)'
                        : 'Belum siap…',
              ),
              _row('Persetujuan (consent)', _consentLabel()),
              _row(
                'Iklan boleh tampil',
                money.adsRemoved
                    ? 'Tidak — sudah dibeli bebas iklan'
                    : money.canShowAds
                        ? 'Ya ✅'
                        : 'Tidak',
              ),
              const Divider(height: 20),
              _slotRow('Banner beranda', ads.slot(AdDiagnostics.slotBanner)),
              _slotRow('Kotak di layar hasil', ads.slot(AdDiagnostics.slotMrec)),
              _slotRow(
                'Interstitial',
                ads.slot(AdDiagnostics.slotInterstitial),
              ),
              const SizedBox(height: 10),
              Text(
                'Kode 3 "No fill" berarti integrasi sudah benar, tetapi AdMob '
                'belum punya iklan untuk unit baru yang child-directed — '
                'normal di hari-hari pertama. Cek dasbor AdMob: aplikasi '
                'tertaut ke Play, app-ads.txt, dan status penayangan.',
                style: AppText.body(12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _consentLabel() {
    switch (ConsentService.I.state) {
      case ConsentState.obtained:
        return 'OK ✅';
      case ConsentState.required:
        return 'Formulir wajib belum selesai ⏳';
      case ConsentState.unavailable:
        return 'Gagal dimuat — lanjut non-personal ⚠️';
      case ConsentState.unknown:
        return 'Memeriksa…';
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppText.body(14))),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              style: AppText.heading(13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotRow(String label, AdSlotStatus slot) {
    final String value;
    if (slot.lastLoadedAt != null && slot.lastErrorAt != null) {
      value = slot.lastLoadedAt!.isAfter(slot.lastErrorAt!)
          ? 'Termuat ✅ ${_stamp(slot.lastLoadedAt)}'
          : 'Gagal (kode ${slot.lastErrorCode ?? '?'}): ${slot.lastError} • ${_stamp(slot.lastErrorAt)}';
    } else if (slot.lastLoadedAt != null) {
      value = 'Termuat ✅ ${_stamp(slot.lastLoadedAt)} (${slot.loads}×)';
    } else if (slot.lastErrorAt != null) {
      value =
          'Gagal ${slot.failures}× • kode ${slot.lastErrorCode ?? '?'}: '
          '${slot.lastError} • ${_stamp(slot.lastErrorAt)}';
    } else {
      value = 'Belum diminta';
    }
    return _row(label, value);
  }
}
