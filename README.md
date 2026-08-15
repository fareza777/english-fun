# English Fun Adventure 🦊

Aplikasi Android belajar Bahasa Inggris untuk anak SD kelas 1–6. Penuh animasi,
gambar besar, suara pelafalan (TTS), dan permainan — tanpa "wall of text".

Maskot: **Funky si Rubah** 🦊

## Fitur

- **6 kelas, 56 unit, 440+ kartu kosakata** bergambar dengan terjemahan Indonesia
- **Kelas 1: 20 unit, 211 kartu** — Alfabet, Angka 1–10 & 11–20, Warna, Hewan, Hewan Kecil, Buah, Makanan, Tubuh, Keluarga, Mainan, Bentuk, Barang, Pakaian, Alam, Rumah, Sekolah, Kendaraan, Kata Kerja, Perasaan
- **Kurikulum berjenjang**
  - Kelas 2: Hewan Liar, Hewan Laut, Burung, Sayur, Camilan, Tempat, Pekerjaan, Cuaca, Kata Sifat + *This is / These are*
  - Kelas 3: Kata Kerja 1 & 2, Olahraga, Hobi, Hari & Waktu + *I like...*
  - Kelas 4: Rutinitas, Sifat, Preposisi + *To Be*, *Simple Present*, *Present Continuous* (masing-masing 10+ soal latihan)
  - Kelas 5: Kota, Kendaraan 2, Profesi 2 + *Simple Past*, *Comparatives & Superlatives*, *Going To*, *5W1H*
  - Kelas 6: Negara, Mapel + *Have/Has*, *There is/are*, *And-But-Because* + 3 Cerita Reading
- **Onboarding nama** — Funky menyapa anak dengan namanya
- **Streak harian 🔥** — motivasi belajar tiap hari
- **Koleksi 48 stiker 🎒** — stiker acak tiap menang game (2+ bintang), lengkap dengan album
- **Layar Orang Tua 📊** — progres per kelas, kata yang perlu dilatih, target harian, reset
- **Pujian bervariasi** — "Great job!", "Awesome!", "You are a superstar!"

## Fitur v3 (AAA)

- **🎙️ Voice-over studio (1002 file)** — semua kata & kalimat direkam via ElevenLabs (3 suara: Alice si guru, Carla si pendongeng, Jessica si pemberi semangat), konsisten di semua HP; TTS perangkat jadi fallback otomatis
- **🦊 Funky v2** — maskot yang digambar & dianimasikan penuh via CustomPainter: berkedip, melompat kegirangan, sedih, dan bisa pakai topi dari toko
- **🎤 Game "Ucapkan!"** — latihan pelafalan dengan speech recognition on-device (pencocokan toleran untuk anak)
- **🐉 Boss Battle per kelas** — naga kuis dengan timer + HP bar; soal diambil dari kata yang sering salah (spaced repetition)
- **🪙 Ekonomi koin → Toko Kostum** — bintang menghasilkan koin, beli 8 topi untuk Funky
- **🗺️ 6 dunia tema** — Hutan, Lautan, Kota, Permen, Luar Angkasa, Istana Sihir; peta unit dengan jalur titik-titik + node boss
- **😀 Emoji konsisten** — font Noto Color Emoji subset (1,3 MB) dibundel, tampilan sama di semua Android
- **🐢 Mode kurangi animasi** — aksesibilitas untuk anak sensitif (di layar Orang Tua)
- **🎯 Target harian** — 3/5/10 game per hari, bisa diatur orang tua

## Fitur v4 (Arena Arcade & Peliharaan)

- **🕹️ Arena Arcade** — hub game aksi dengan pilihan kelas (memakai kata yang sudah dipelajari):
  - **🎈 Balon Pop** — dengar kata, letuskan balon yang benar (fisika real-time)
  - **🧺 Tangkap Kata** — geser keranjang menangkap kata yang jatuh, 3 nyawa
  - **🏃 Lari Kata** — Funky berlari, ketuk gerbang jawaban sebelum lewat
- **🧩 Susun Kalimat** — game ke-2 di semua unit grammar: susun kata acak jadi kalimat benar
- **🧍 Simon Says** — ikuti perintah bahasa Inggris, hati-hati jebakan "tanpa Simon says"!
- **🗺️ Cerita Bercabang** — 2 petualangan interaktif (Anak Kucing Hilang 🐱, ke Luar Angkasa 🚀), pilihan anak menentukan jalan cerita
- **🥚 Peliharaan Telur** — beli telur (40 koin) atau menangkan dari Boss, tetaskan 12 hewan koleksi (common→legendary 🦄🐉), beri makan tiap hari lewat kuis 3 kata; peliharaan aktif menemani Funky di beranda
- **🎡 Roda Harian** — 1 putaran gratis per hari: koin, stiker, atau telur
- **🏅 15 Lencana Prestasi** — dari "Bintang Pertama" sampai "Penakluk Naga" (tab baru di album)
- **5 permainan per unit kosakata**
  - 📖 Belajar — flashcard besar dengan flip 3D + pelafalan otomatis
  - 🎯 Tebak Kata — lihat gambar, pilih kata Inggris
  - 🎧 Tebak Suara — dengarkan pelafalan, pilih gambar
  - 🃏 Memory Match — pasangkan gambar & kata
  - 🔤 Susun Huruf — spelling bee dengan ubin huruf
- **Unit grammar interaktif** — pola kalimat + contoh bersuara + tantangan "Coba Jawab!"
- **Unit cerita** — baca per kalimat dengan TTS + kuis pemahaman
- **Suara pelafalan native** (Text-to-Speech English, kecepatan lambat & jelas)
- **Sound effect ceria** (ding, pop, fanfare) yang di-synthesize sendiri (`tools/make_sfx.py`)
- **Animasi di mana-mana** — confetti, bintang elastis, tombol memantul, awan bergerak, maskot hidup
- **Sistem bintang & progres** tersimpan otomatis (SharedPreferences), unit terbuka berurutan
- **Ikon launcher rubah** yang digambar programatis (`tools/make_icon.py`)
- **Offline-first** — progres belajar tersimpan di perangkat; banner iklan ramah anak bersifat non-personalized dan dapat dihapus permanen dari area Orang Tua

## Menjalankan

```powershell
flutter pub get
flutter run            # di HP Android yang terhubung / emulator
```

## Build

```powershell
flutter build apk --release        # APK untuk instal langsung
flutter build appbundle --release  # AAB untuk Play Store
```

Hasil:
- `build\app\outputs\flutter-apk\app-release.apk`
- `build\app\outputs\bundle\release\app-release.aab`

## Test

```powershell
flutter test     # integritas konten + smoke test navigasi end-to-end
flutter analyze
```

## Publish ke Play Store

1. **Buat keystore release** (sekali saja, simpan baik-baik):
   ```powershell
   keytool -genkey -v -keystore %USERPROFILE%\englishfun-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias englishfun
   ```
2. Buat `android\key.properties`:
   ```properties
   storePassword=<password-keystore>
   keyPassword=<password-key>
   keyAlias=englishfun
   storeFile=<path-lengkap-ke englishfun-key.jks>
   ```
3. Daftarkan di `android\app\build.gradle.kts` (signingConfigs release dari key.properties)
   lalu `flutter build appbundle --release`.
4. Upload AAB di [Play Console](https://play.google.com/console):
   - Kategori: Edukasi; Target audiens: Anak-anak (isi bagian Families/Designed for Children)
   - Kebijakan privasi: aplikasi offline, tidak mengumpulkan data — cukup nyatakan itu
   - Rating konten: Everyone
   - Screenshot: ambil dari emulator/HP (splash, home, flashcard, kuis)

## Catatan teknis

- Pelafalan memakai TTS perangkat (bahasa Inggris/en-US). Di sebagian besar HP Android
  sudah tersedia (Google Speech Services). Jika belum, unduh suara English di
  Pengaturan > Bahasa > Text-to-speech.
- minSdk 23 (Android 6.0+), target SDK terbaru.
- Font: Baloo 2 & Nunito (OFL), tersimpan lokal di `assets/fonts`.
