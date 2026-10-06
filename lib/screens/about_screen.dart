import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'privacy_screen.dart';

/// Parent-facing information and discovery actions for English Fun.
///
/// This route is intentionally not an ad surface. It is opened from the
/// parent dashboard, so sharing and leaving a rating stay behind the adult
/// gate already used to enter that area.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const appVersion = '1.2.5';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.englishfun.english_fun';
  static const _shareMessage =
      'Coba English Fun — game belajar bahasa Inggris yang seru untuk anak kelas 1–6!\n\n$playStoreUrl';

  Uri get _playStoreUri => Uri.parse(playStoreUrl);

  Future<void> _share(BuildContext context) async {
    try {
      await SharePlus.instance.share(ShareParams(text: _shareMessage));
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Menu berbagi belum tersedia di perangkat ini.');
      }
    }
  }

  Future<void> _rate(BuildContext context) async {
    try {
      final opened = await launchUrl(
        _playStoreUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showMessage(context, 'Google Play belum bisa dibuka sekarang.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Google Play belum bisa dibuka sekarang.');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppText.body(14, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Column(
          children: [
            const KidAppBar(
              title: 'Tentang English Fun',
              emoji: '✨',
              colors: [],
            ),
            Expanded(
              child: ContentWidth(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                  children: [
                    _heroCard(),
                    const SizedBox(height: 14),
                    _actionCard(
                      icon: Icons.share_rounded,
                      title: 'Bagikan aplikasi',
                      subtitle: 'Ajak keluarga lain belajar sambil bermain.',
                      color: const Color(0xFF4361EE),
                      onTap: () => unawaited(_share(context)),
                    ),
                    const SizedBox(height: 12),
                    _actionCard(
                      icon: Icons.star_rounded,
                      title: 'Nilai di Google Play',
                      subtitle:
                          'Dukungan orang tua membantu English Fun tumbuh.',
                      color: const Color(0xFFF4A261),
                      onTap: () => unawaited(_rate(context)),
                    ),
                    const SizedBox(height: 14),
                    _safetyCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4361EE), Color(0xFF7B61FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🎒', style: TextStyle(fontSize: 54)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('English Fun', style: AppText.display(28)),
                const SizedBox(height: 4),
                Text(
                  'Belajar bahasa Inggris lewat game, cerita, dan tantangan kecil setiap hari.',
                  style: AppText.body(14, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versi $appVersion',
                  style: AppText.body(
                    13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.32), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.heading(19)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppText.body(13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _safetyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Text('🛡️ Dibuat untuk keluarga', style: AppText.heading(19)),
          const SizedBox(height: 6),
          Text(
            'Progres belajar tersimpan di perangkat. Iklan disetel non-personalisasi dan child-directed, sementara kontrol pembelian dan privasi tersedia untuk orang tua.',
            style: AppText.body(14),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () =>
                Navigator.of(context).push(funRoute(const PrivacyScreen())),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.inkSoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Kebijakan Privasi', style: AppText.body(15)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
