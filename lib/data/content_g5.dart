import '../models.dart';
import '../theme.dart';

/// KELAS 5 — Penjelajah Tenses (7 unit)
final Grade grade5 = Grade(
  level: 5,
  title: 'Kelas 5',
  subtitle: 'Penjelajah Tenses',
  emoji: '🏆',
  colors: GradePalette.all[4],
  units: [
    Unit.vocab(
      id: 'g5_city',
      title: 'In the City',
      titleId: 'Di Kota',
      emoji: '🌆',
      items: [
        v('Bank', 'Bank', '🏦', sentence: 'Dad goes to the bank.'),
        v('Post Office', 'Kantor pos', '🏤', sentence: 'Mom sends a letter at the post office.'),
        v('Airport', 'Bandara', '🛫', sentence: 'The plane is at the airport.'),
        v('Train Station', 'Stasiun kereta', '🚉', sentence: 'We wait at the train station.'),
        v('Hotel', 'Hotel', '🏨', sentence: 'We sleep at the hotel.'),
        v('Cinema', 'Bioskop', '🎦', sentence: 'We watch a movie at the cinema.'),
        v('Mall', 'Mal', '🏬', sentence: 'We shop at the mall.'),
        v('Bakery', 'Toko roti', '🥖', sentence: 'The bakery smells good.'),
        v('Museum', 'Museum', '🏛️', sentence: 'The museum is interesting.'),
        v('Bridge', 'Jembatan', '🌉', sentence: 'The bridge is long.'),
      ],
    ),
    Unit.vocab(
      id: 'g5_transport2',
      title: 'More Vehicles',
      titleId: 'Kendaraan Keren',
      emoji: '🚀',
      items: [
        v('Rocket', 'Roket', '🚀', sentence: 'The rocket flies to space.'),
        v('Sailboat', 'Perahu layar', '⛵', sentence: 'The sailboat is white.'),
        v('Canoe', 'Kano', '🛶', sentence: 'We row the canoe.'),
        v('Scooter', 'Skuter', '🛴', sentence: 'I ride my scooter.'),
        v('Skateboard', 'Papan luncur', '🛹', sentence: 'He plays skateboard.'),
        v('Van', 'Van', '🚐', sentence: 'The van is big.'),
        v('Ambulance', 'Ambulans', '🚑', sentence: 'The ambulance helps sick people.'),
        v('Police Car', 'Mobil polisi', '🚓', sentence: 'The police car is fast.'),
        v('Fire Truck', 'Mobil pemadam', '🚒', sentence: 'The fire truck is red.'),
        v('Tractor', 'Traktor', '🚜', sentence: 'The farmer drives a tractor.'),
      ],
    ),
    Unit.vocab(
      id: 'g5_jobs2',
      title: 'Cool Jobs',
      titleId: 'Profesi Keren',
      emoji: '🧑‍🔬',
      items: [
        v('Scientist', 'Ilmuwan', '🧑‍🔬', sentence: 'The scientist does experiments.'),
        v('Astronaut', 'Astronot', '🧑‍🚀', sentence: 'The astronaut goes to space.'),
        v('Singer', 'Penyanyi', '🧑‍🎤', sentence: 'The singer sings beautifully.'),
        v('Judge', 'Hakim', '🧑‍⚖️', sentence: 'The judge is fair.'),
        v('Mechanic', 'Mekanik', '🧑‍🔧', sentence: 'The mechanic fixes cars.'),
        v('Barber', 'Tukang cukur', '💈', sentence: 'The barber cuts hair.'),
        v('Photographer', 'Fotografer', '📷', sentence: 'The photographer takes photos.'),
        v('Writer', 'Penulis', '📝', sentence: 'The writer writes stories.'),
      ],
    ),
    Unit.grammar(
      id: 'g5_past',
      title: 'Simple Past',
      titleId: 'Kejadian Lampau',
      emoji: '⏮️',
      pages: [
        GrammarPage(
          title: 'Kata kerja + ed',
          explain: 'Untuk kegiatan yang SUDAH lewat (kemarin, tadi malam): kata kerja + ed. play → played.',
          examples: [
            ge('I played ball yesterday.', 'Saya bermain bola kemarin.', '⚽'),
            ge('We visited grandma.', 'Kami mengunjungi nenek.', '👵'),
            ge('She watched TV last night.', 'Dia menonton TV tadi malam.', '📺'),
          ],
          challenges: [
            ch('Yesterday, I ___ football.', ['played', 'play', 'plays'], 0, 'Yesterday, I played football.')
          ],
        ),
        GrammarPage(
          title: 'Kata Kerja Spesial 1',
          explain: 'Beberapa kata berubah total! go → went, eat → ate, drink → drank, see → saw.',
          examples: [
            ge('I went to the zoo.', 'Saya pergi ke kebun binatang.', '🦁'),
            ge('He ate cake.', 'Dia makan kue.', '🍰'),
            ge('We drank milk.', 'Kami minum susu.', '🥛'),
          ],
          challenges: [
            ch('Last week, we ___ to the beach.', ['went', 'go', 'goes'], 0, 'Last week, we went to the beach.')
          ],
        ),
        GrammarPage(
          title: 'Kata Kerja Spesial 2',
          explain: 'buy → bought, take → took, give → gave, write → wrote, read → read (dibaca "red").',
          examples: [
            ge('She bought a doll.', 'Dia membeli boneka.', '🎎'),
            ge('He took my pencil.', 'Dia mengambil pensilku.', '✏️'),
            ge('Mom gave me a gift.', 'Ibu memberiku hadiah.', '🎁'),
          ],
          challenges: [ch('She ___ a doll yesterday.', ['bought', 'buy', 'buys'], 0, 'She bought a doll yesterday.')],
        ),
        GrammarPage(
          title: 'Negatif & Bertanya',
          explain: "Pakai didn't untuk tidak, dan 'Did' untuk bertanya. Kata kerjanya kembali biasa!",
          examples: [
            ge("I didn't go out.", 'Saya tidak pergi keluar.', '🏠'),
            ge('Did you go to school?', 'Apakah kamu pergi ke sekolah?', '🏫'),
            ge("He didn't eat breakfast.", 'Dia tidak makan pagi.', '🍳'),
          ],
          challenges: [ch('___ you go to school yesterday?', ['Did', 'Do', 'Does'], 0, 'Did you go to school yesterday?')],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Ingat: kemarin = lampau = +ed atau kata spesial!',
          challenges: [
            ch('He ___ TV last night.', ['watched', 'watch', 'watches'], 0, 'He watched TV last night.'),
            ch('I ___ an egg this morning.', ['ate', 'eat', 'eats'], 0, 'I ate an egg this morning.'),
            ch('They ___ happy yesterday.', ['were', 'was', 'are'], 0, 'They were happy yesterday.'),
            ch('___ she visit grandma?', ['Did', 'Does', 'Do'], 0, 'Did she visit grandma?'),
            ch('We ___ not go out.', ['did', 'do', 'does'], 0, 'We did not go out.'),
            ch('Mom ___ me a gift.', ['gave', 'give', 'gives'], 0, 'Mom gave me a gift.'),
          ],
        ),
      ],
    ),
    Unit.grammar(
      id: 'g5_compare',
      title: 'Comparatives',
      titleId: 'Membandingkan (lebih & paling)',
      emoji: '📏',
      pages: [
        GrammarPage(
          title: 'Lebih ... : + er',
          explain: 'Membandingkan 2 hal: kata sifat + er, lalu "than". big → bigger, fast → faster.',
          examples: [
            ge('A car is faster than a bike.', 'Mobil lebih cepat dari sepeda.', '🚗'),
            ge('An elephant is bigger than a cat.', 'Gajah lebih besar dari kucing.', '🐘'),
            ge('Dad is taller than me.', 'Ayah lebih tinggi dariku.', '🧍'),
          ],
          challenges: [
            ch('A cheetah is ___ than a turtle.', ['faster', 'fast', 'fastest'], 0, 'A cheetah is faster than a turtle.')
          ],
        ),
        GrammarPage(
          title: 'Kata panjang: more ...',
          explain: 'Kata sifat panjang pakai "more": beautiful → more beautiful, interesting → more interesting.',
          examples: [
            ge('A rose is more beautiful than grass.', 'Mawar lebih indah dari rumput.', '🌹'),
            ge('This book is more interesting.', 'Buku ini lebih menarik.', '📖'),
          ],
          challenges: [
            ch('A peacock is ___ than a chicken.', ['more beautiful', 'beautifuller', 'most beautiful'], 0,
                'A peacock is more beautiful than a chicken.')
          ],
        ),
        GrammarPage(
          title: 'Paling ... : the + est',
          explain: 'Untuk yang PALING dari semua: the + kata sifat + est. fast → the fastest.',
          examples: [
            ge('The cheetah is the fastest animal.', 'Cheetah adalah hewan tercepat.', '🐆'),
            ge('The blue whale is the biggest.', 'Paus biru adalah yang terbesar.', '🐳'),
            ge('She is the smartest in class.', 'Dia yang terpintar di kelas.', '🧠'),
          ],
          challenges: [
            ch('The cheetah is the ___ animal.', ['fastest', 'faster', 'fast'], 0, 'The cheetah is the fastest animal.')
          ],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Pilih jawaban yang tepat!',
          challenges: [
            ch('An ant is ___ than an elephant.', ['smaller', 'small', 'smallest'], 0, 'An ant is smaller than an elephant.'),
            ch('My bag is the ___.', ['heaviest', 'heavier', 'heavy'], 0, 'My bag is the heaviest.'),
            ch('A plane is ___ than a car.', ['faster', 'fastest', 'fast'], 0, 'A plane is faster than a car.'),
            ch('She is the ___ student in class.', ['smartest', 'smarter', 'smart'], 0, 'She is the smartest student in class.'),
            ch('Today is ___ than yesterday.', ['hotter', 'hottest', 'hot'], 0, 'Today is hotter than yesterday.'),
          ],
        ),
      ],
    ),
    Unit.grammar(
      id: 'g5_goingto',
      title: 'Going To',
      titleId: 'Rencana Masa Depan',
      emoji: '🔮',
      pages: [
        GrammarPage(
          title: 'am/is/are + going to + kata kerja',
          explain: 'Untuk rencana yang AKAN dilakukan: am/is/are + going to + kata kerja.',
          examples: [
            ge('I am going to swim.', 'Saya akan berenang.', '🏊'),
            ge('She is going to cook.', 'Dia akan memasak.', '🍳'),
            ge('They are going to play.', 'Mereka akan bermain.', '⚽'),
          ],
          challenges: [ch('I ___ going to swim.', ['am', 'is', 'are'], 0, 'I am going to swim.')],
        ),
        GrammarPage(
          title: 'Kata Kunci Waktu',
          explain: 'Tanda masa depan: tomorrow (besok), next week (minggu depan), tonight (nanti malam).',
          examples: [
            ge('We are going to the zoo tomorrow.', 'Kami akan ke kebun binatang besok.', '🦁'),
            ge('He is going to read tonight.', 'Dia akan membaca nanti malam.', '📖'),
          ],
          challenges: [
            ch('She ___ going to visit grandma tomorrow.', ['is', 'are', 'am'], 0, 'She is going to visit grandma tomorrow.')
          ],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Pilih jawaban yang tepat!',
          challenges: [
            ch('They ___ going to play.', ['are', 'is', 'am'], 0, 'They are going to play.'),
            ch('We are going ___ the zoo.', ['to', 'too', 'two'], 0, 'We are going to the zoo.'),
            ch('He ___ going to read.', ['is', 'are', 'am'], 0, 'He is going to read.'),
            ch('I am going to ___ a book.', ['read', 'reads', 'reading'], 0, 'I am going to read a book.'),
          ],
        ),
      ],
    ),
    Unit.grammar(
      id: 'g5_questions',
      title: 'Question Words',
      titleId: 'Kata Tanya (5W1H)',
      emoji: '❓',
      pages: [
        GrammarPage(
          title: 'What & Who',
          explain: 'What = apa (benda). Who = siapa (orang).',
          examples: [
            ge('What is your name?', 'Apa namamu?', '📛'),
            ge('Who is your teacher?', 'Siapa gurumu?', '👩‍🏫'),
          ],
          challenges: [ch('___ is your name?', ['What', 'Who', 'Where'], 0, 'What is your name?')],
        ),
        GrammarPage(
          title: 'Where & When',
          explain: 'Where = di mana (tempat). When = kapan (waktu).',
          examples: [
            ge('Where do you live?', 'Di mana kamu tinggal?', '🏠'),
            ge('When is your birthday?', 'Kapan ulang tahunmu?', '🎂'),
          ],
          challenges: [ch('___ do you live?', ['Where', 'When', 'What'], 0, 'Where do you live?')],
        ),
        GrammarPage(
          title: 'Why & How',
          explain: 'Why = mengapa (alasan). How = bagaimana (cara).',
          examples: [
            ge('Why are you sad?', 'Mengapa kamu sedih?', '😢'),
            ge('How are you?', 'Bagaimana kabarmu?', '👋'),
          ],
          challenges: [ch('___ are you sad?', ['Why', 'How', 'What'], 0, 'Why are you sad?')],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Pilih kata tanya yang tepat!',
          challenges: [
            ch('___ is that? It is a cat.', ['What', 'Who', 'Where'], 0, 'What is that? It is a cat.'),
            ch('___ is your teacher? Mrs. Ana.', ['Who', 'What', 'When'], 0, 'Who is your teacher? Mrs. Ana.'),
            ch('___ do you go to school? At seven.', ['When', 'Where', 'Why'], 0, 'When do you go to school? At seven.'),
            ch('___ old are you?', ['How', 'What', 'Who'], 0, 'How old are you?'),
            ch('___ do you study? At school.', ['Where', 'When', 'Why'], 0, 'Where do you study? At school.'),
          ],
        ),
      ],
    ),
  ],
);
