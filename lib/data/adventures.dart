/// Branching interactive stories ("Cerita Bercabang") + Simon Says commands.
library;

class AdvChoice {
  final String text;
  final String next;
  const AdvChoice(this.text, this.next);
}

class AdvNode {
  final String emoji;
  final String en;
  final String idn;
  final List<AdvChoice> choices;

  /// >0 marks a happy ending node (coin reward).
  final int coins;
  const AdvNode(this.emoji, this.en, this.idn, this.choices, {this.coins = 0});
}

class Adventure {
  final String title;
  final String titleId;
  final String emoji;
  final String startId;
  final Map<String, AdvNode> nodes;
  const Adventure(this.title, this.titleId, this.emoji, this.startId, this.nodes);
}

AdvNode _n(String emoji, String en, String idn,
        [List<(String, String)> choices = const [], int coins = 0]) =>
    AdvNode(emoji, en, idn, [for (final c in choices) AdvChoice(c.$1, c.$2)], coins: coins);

final kAdventures = <Adventure>[
  Adventure(
    'The Lost Kitten',
    'Anak Kucing Hilang',
    '🐱',
    'start',
    {
      'start': _n('🌳', 'Funky plays in the park. Suddenly he hears: "Meow!"',
          'Funky bermain di taman. Tiba-tiba ia mendengar: "Meong!"', [
        ('Look under the tree 🌳', 'tree'),
        ('Look near the pond 💧', 'pond'),
      ]),
      'tree': _n('🌳', 'Funky looks under the tree. Nobody is here...',
          'Funky melihat ke bawah pohon. Tidak ada siapa-siapa...', [
        ('Follow the sound 👂', 'bush'),
        ('Call the kitten 📣', 'call'),
      ]),
      'pond': _n('🦆', 'Funky sees ducks in the pond, but no kitten.',
          'Funky melihat bebek di kolam, tapi tidak ada anak kucing.', [
        ('Ask the ducks 🦆', 'ducks'),
        ('Go back to the tree 🌳', 'tree'),
      ]),
      'ducks': _n('🦆', 'The ducks say: "The kitten is hiding in the bush!"',
          'Bebek berkata: "Anak kucing bersembunyi di semak-semak!"', [
        ('Go to the bush 🌿', 'bush'),
      ]),
      'call': _n('📣', '"Here, kitty kitty!" ... No answer. Hmm.',
          '"Sini, cing cing!" ... Tidak ada jawaban. Hmm.', [
        ('Follow the sound 👂', 'bush'),
        ('Ask the ducks 🦆', 'ducks'),
      ]),
      'bush': _n('🌿', 'Funky finds a little kitten in the bush. It is scared!',
          'Funky menemukan anak kucing di semak-semak. Ia ketakutan!', [
        ('Give it some milk 🥛', 'milk'),
        ('Pick it up gently 🤲', 'gentle'),
      ]),
      'milk': _n('🥛', 'The kitten drinks the milk. It feels better now!',
          'Anak kucing meminum susunya. Sekarang ia merasa lebih baik!', [
        ('Find its home 🏠', 'home'),
      ]),
      'gentle': _n('🤲', 'Funky holds the kitten softly. It starts to purr!',
          'Funky memegang anak kucing dengan lembut. Ia mulai mendengkur!', [
        ('Find its home 🏠', 'home'),
      ]),
      'home': _n('🏠', 'A girl opens the door: "Luna! My kitten! Thank you, Funky!"',
          'Seorang anak perempuan membuka pintu: "Luna! Kucingku! Terima kasih, Funky!"', [
        ('Finish 🎉', 'end'),
      ]),
      'end': _n('🎉', 'Hooray! The kitten is home. You are a hero, Funky!',
          'Hore! Anak kucing sudah pulang. Kamu pahlawan, Funky!', [], 15),
    },
  ),
  Adventure(
    'Funky Goes to Space',
    'Funky ke Luar Angkasa',
    '🚀',
    'start',
    {
      'start': _n('🚀', 'Funky has a red rocket. "Three, two, one... GO!"',
          'Funky punya roket merah. "Tiga, dua, satu... BERANGKAT!"', [
        ('Fly to the Moon 🌙', 'moon'),
        ('Fly to Mars 🔴', 'mars'),
      ]),
      'moon': _n('🌙', 'The Moon is big and grey. Funky jumps super high here!',
          'Bulan itu besar dan abu-abu. Funky bisa melompat tinggi sekali di sini!', [
        ('Collect moon rocks 🪨', 'rocks'),
        ('Look at the stars ✨', 'stars'),
      ]),
      'mars': _n('🔴', 'Mars is red and dusty. A friendly robot waves at Funky!',
          'Mars itu merah dan berdebu. Robot ramah melambaikan tangan ke Funky!', [
        ('Say hello to the robot 🤖', 'robot'),
        ('Take a photo 📸', 'photo'),
      ]),
      'rocks': _n('🪨', 'The moon rocks sparkle like diamonds. Beautiful!',
          'Batu bulan berkilau seperti berlian. Indah sekali!', [
        ('Fly home 🏠', 'home'),
      ]),
      'stars': _n('✨', 'The stars twinkle: twinkle, twinkle, little star...',
          'Bintang-bintang berkelip: kelip, kelip, bintang kecil...', [
        ('Fly home 🏠', 'home'),
      ]),
      'robot': _n('🤖', 'The robot says: "Welcome to Mars, Funky!" and dances.',
          'Robot berkata: "Selamat datang di Mars, Funky!" lalu menari.', [
        ('Fly home 🏠', 'home'),
      ]),
      'photo': _n('📸', 'Click! What a beautiful photo of red Mars!',
          'Cekrek! Foto Mars yang merah itu indah sekali!', [
        ('Fly home 🏠', 'home'),
      ]),
      'home': _n('🏠', 'Funky lands safely on Earth. What a big adventure!',
          'Funky mendarat dengan selamat di Bumi. Petualangan yang luar biasa!', [
        ('Finish 🎉', 'end'),
      ]),
      'end': _n('🎉', 'Great explorer! You travelled to space. The End!',
          'Penjelajah hebat! Kamu sudah pergi ke luar angkasa. Tamat!', [], 15),
    },
  ),
];

/// Simon Says commands: (English command, emoji answer).
const kSimonCommands = <(String, String)>[
  ('Touch your nose!', '👃'),
  ('Touch your ears!', '👂'),
  ('Clap your hands!', '👏'),
  ('Close your eyes!', '🙈'),
  ('Open your mouth!', '😮'),
  ('Stamp your feet!', '🦶'),
  ('Raise your hands!', '🙌'),
  ('Touch your shoulders!', '🤷'),
  ('Jump up!', '🦘'),
  ('Turn around!', '🔄'),
  ('Sit down!', '🪑'),
  ('Touch your head!', '🙆'),
];
