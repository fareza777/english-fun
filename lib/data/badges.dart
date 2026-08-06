import '../services/progress.dart';

/// Achievement badges checked against live progress.
class Badge {
  final String id;
  final String emoji;
  final String name;
  final String desc;
  final bool Function(Progress p) check;
  const Badge(this.id, this.emoji, this.name, this.desc, this.check);
}

final kBadges = <Badge>[
  Badge('star1', '🌟', 'Bintang Pertama', 'Dapatkan 1 bintang', (p) => p.totalStars >= 1),
  Badge('star50', '⭐', 'Kolektor 50', 'Kumpulkan 50 bintang', (p) => p.totalStars >= 50),
  Badge('star150', '🏆', 'Kolektor 150', 'Kumpulkan 150 bintang', (p) => p.totalStars >= 150),
  Badge('star300', '💫', 'Kolektor 300', 'Kumpulkan 300 bintang', (p) => p.totalStars >= 300),
  Badge('streak3', '🔥', 'Semangat 3 Hari', 'Belajar 3 hari beruntun', (p) => p.streak >= 3),
  Badge('streak7', '🗓️', 'Semangat 7 Hari', 'Belajar 7 hari beruntun', (p) => p.streak >= 7),
  Badge('games10', '🎮', 'Pemain Aktif', 'Selesaikan 10 game', (p) => p.gamesTotal >= 10),
  Badge('games50', '🕹️', 'Raja Game', 'Selesaikan 50 game', (p) => p.gamesTotal >= 50),
  Badge('stickers10', '🎒', 'Kolektor Stiker', 'Kumpulkan 10 stiker', (p) => p.stickers.length >= 10),
  Badge('stickers24', '🧸', 'Master Stiker', 'Kumpulkan 24 stiker', (p) => p.stickers.length >= 24),
  Badge('boss', '🐉', 'Penakluk Naga', 'Kalahkan 1 boss battle', (p) => p.anyBossWin),
  Badge('speak', '🎤', 'Bintang Suara', 'Menangkan game Ucapkan!', (p) => p.anySpeakStar),
  Badge('pet1', '🥚', 'Penetas Telur', 'Tetaskan 1 peliharaan', (p) => p.pets.isNotEmpty),
  Badge('pet6', '🐾', 'Kolektor Hewan', 'Miliki 6 peliharaan', (p) => p.pets.length >= 6),
  Badge('coins200', '🪙', 'Juragan Koin', 'Pegang 200 koin sekaligus', (p) => p.coins >= 200),
];

/// Unlocks all badges whose condition is met. Returns newly unlocked ones.
List<Badge> checkNewBadges() {
  final fresh = <Badge>[];
  for (final b in kBadges) {
    if (!Progress.I.badges.contains(b.id) && b.check(Progress.I)) {
      if (Progress.I.unlockBadge(b.id)) fresh.add(b);
    }
  }
  return fresh;
}
