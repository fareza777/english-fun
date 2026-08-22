import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

/// One block of the policy.
class _Section {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  const _Section(this.title, this.paragraphs, {this.bullets = const []});
}

/// The privacy policy, shown inside the app.
///
/// Kept in-app rather than opening a browser: Play's Families guidance
/// discourages sending children out to external links, and an offline copy
/// works even with no connection.
///
/// Mirrors `privacy-policy.html` at the repository root, which is the copy
/// published for the Play Store listing. Update both together.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const lastUpdated = '22 Agustus 2026';

  static const List<_Section> _sections = [
    _Section('1. Informasi yang disimpan di perangkat', [
      'English Fun menyimpan preferensi dan progres belajar di perangkat agar petualangan bisa dilanjutkan dari tempat terakhir. Ini mencakup nama panggilan, aktivitas yang selesai, bintang, streak, pengaturan, dan status lokal pembelian penghapusan iklan.',
      'Informasi ini tidak dikirim ke server kami. Orang tua dapat mereset progres dari dasbor orang tua di dalam app, atau menghapus app beserta datanya dari perangkat.',
    ]),
    _Section('2. Suara dan mikrofon', [
      'Aktivitas "Ucapkan!" dapat meminta akses mikrofon agar anak bisa berlatih pengucapan. App memakai layanan pengenalan suara bawaan perangkat. English Fun tidak merekam atau mengunggah suara ke server kami.',
      'Akses mikrofon bisa ditolak atau dicabut lewat pengaturan Android. Aktivitas belajar lainnya tetap bisa dipakai.',
    ]),
    _Section('3. Iklan', [
      'English Fun dapat menampilkan iklan banner (adaptive di layar utama) dan iklan medium rectangle di layar hasil, plus iklan interstitial sesekali saat anak meninggalkan layar hasil. Iklan tidak pernah muncul di tengah permainan, pelajaran, atau aktivitas bicara. Karena app ini dirancang untuk anak, iklan dikonfigurasi non-personalisasi dan child-directed, dengan pembatasan rating konten dan batas frekuensi untuk iklan layar penuh.',
      'Orang tua dapat membeli produk sekali bayar "Hapus Iklan". Pembelian diproses Google Play Billing; English Fun hanya menyimpan status lokal yang diperlukan.',
    ]),
    _Section('4. Informasi yang tidak kami minta', [
      'English Fun tidak memerlukan akun dan tidak meminta lokasi persis, kontak, foto, atau akses berkas. Kami tidak dengan sengaja mengumpulkan data pribadi anak melalui server kami.',
    ]),
    _Section('5. Privasi anak', [
      'English Fun ditujukan untuk anak dan keluarga. Kami merancang pengalaman ini agar penggunaan data seminimal mungkin, progres tersimpan lokal, dan kontrol tersedia untuk orang tua. Orang tua atau wali sebaiknya mengawasi izin perangkat dan pembelian.',
    ]),
    _Section(
      '6. Layanan pihak ketiga',
      ['App ini bergantung pada layanan berikut agar berfungsi:'],
      bullets: [
        'Google Mobile Ads untuk iklan banner dan interstitial non-personalisasi yang aman bagi anak.',
        'Google Play Billing untuk pembelian sekali bayar penghapusan iklan.',
        'Pengenalan suara Android untuk aktivitas pengucapan.',
      ],
    ),
    _Section('7. Kontak', [
      'Pertanyaan, permintaan orang tua, atau kekhawatiran soal privasi dapat dikirim ke fajar.mreza@gmail.com.',
    ]),
    _Section('8. Perubahan kebijakan', [
      'Kami dapat memperbarui kebijakan ini ketika fitur app atau ketentuan hukum berubah. Tanggal "Terakhir diperbarui" di atas menunjukkan versi terbaru.',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Column(
          children: [
            const KidAppBar(title: 'Kebijakan Privasi', emoji: '🔒', colors: []),
            Expanded(
              child: ContentWidth(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('English Fun', style: AppText.heading(24)),
                          const SizedBox(height: 4),
                          Text('Terakhir diperbarui: $lastUpdated', style: AppText.body(14)),
                          const SizedBox(height: 10),
                          Text(
                            'Kebijakan ini menjelaskan informasi apa yang dipakai app dan bagaimana penanganannya.',
                            style: AppText.body(16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._sections.map(_sectionCard),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(_Section section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(section.title, style: AppText.heading(19))),
          const SizedBox(height: 8),
          for (final paragraph in section.paragraphs) ...[
            Text(paragraph, style: AppText.body(15)),
            const SizedBox(height: 8),
          ],
          for (final bullet in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: AppText.body(15)),
                  Expanded(child: Text(bullet, style: AppText.body(15))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
