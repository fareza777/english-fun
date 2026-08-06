import '../models.dart';
import '../theme.dart';

/// KELAS 4 — Grammar Hero (6 unit)
final Grade grade4 = Grade(
  level: 4,
  title: 'Kelas 4',
  subtitle: 'Grammar Hero',
  emoji: '🌟',
  colors: GradePalette.all[3],
  units: [
    Unit.vocab(
      id: 'g4_routines',
      title: 'Daily Routines',
      titleId: 'Rutinitas Harian',
      emoji: '⏰',
      items: [
        v('Wake up', 'Bangun tidur', '⏰', sentence: 'I wake up at six.'),
        v('Brush my teeth', 'Menggosok gigi', '🪥', sentence: 'I brush my teeth.'),
        v('Take a bath', 'Mandi', '🛁', sentence: 'I take a bath.'),
        v('Go to school', 'Pergi ke sekolah', '🏫', sentence: 'I go to school at seven.'),
        v('Study', 'Belajar', '📚', sentence: 'I study English.'),
        v('Play', 'Bermain', '⚽', sentence: 'I play with my friends.'),
        v('Watch TV', 'Menonton TV', '📺', sentence: 'I watch TV with dad.'),
        v('Sleep', 'Tidur', '😴', sentence: 'I sleep at nine.'),
      ],
    ),
    Unit.vocab(
      id: 'g4_describing',
      title: 'Describing People',
      titleId: 'Sifat & Gambaran',
      emoji: '🌺',
      items: [
        v('Beautiful', 'Cantik / Indah', '🌺', sentence: 'The flower is beautiful.'),
        v('Cute', 'Lucu', '🥰', sentence: 'The baby is cute.'),
        v('Funny', 'Lucu / Kocak', '🤪', sentence: 'The clown is funny.'),
        v('Smart', 'Pintar', '🧠', sentence: 'She is smart.'),
        v('Brave', 'Berani', '🦁', sentence: 'He is brave.'),
        v('Kind', 'Baik hati', '💝', sentence: 'She is kind to everyone.'),
        v('Strong', 'Kuat', '💪', sentence: 'Dad is strong.'),
        v('Lazy', 'Malas', '🦥', sentence: 'The sloth is lazy.'),
        v('Friendly', 'Ramah', '🤝', sentence: 'They are friendly.'),
        v('Polite', 'Sopan', '😇', sentence: 'He is polite.'),
      ],
    ),
    Unit.vocab(
      id: 'g4_prep',
      title: 'Where is the Cat?',
      titleId: 'Kata Depan (in, on, under...)',
      emoji: '📦',
      items: [
        v('In', 'Di dalam', '🐱📦', sentence: 'The cat is in the box.'),
        v('On', 'Di atas', '🐱🛏️', sentence: 'The cat is on the bed.'),
        v('Under', 'Di bawah', '🛏️🐱', sentence: 'The cat is under the bed.'),
        v('Behind', 'Di belakang', '🌳🐱', sentence: 'The cat is behind the tree.'),
        v('In front of', 'Di depan', '🐱🌳', sentence: 'The cat is in front of the tree.'),
        v('Next to', 'Di sebelah', '🐱🐶', sentence: 'The cat is next to the dog.'),
        v('Between', 'Di antara', '🐶🐱🐶', sentence: 'The cat is between the dogs.'),
      ],
    ),
    Unit.grammar(
      id: 'g4_tobe',
      title: 'Am, Is, Are',
      titleId: 'Kata Kerja To Be',
      emoji: '🧩',
      pages: [
        GrammarPage(
          title: 'I am ...',
          explain: "'Am' selalu bersama 'I' (saya).",
          examples: [
            ge('I am happy.', 'Saya senang.', '😊'),
            ge('I am a student.', 'Saya seorang murid.', '🧑‍🎓'),
            ge('I am seven years old.', 'Saya berumur tujuh tahun.', '7️⃣'),
          ],
          challenges: [ch('I ___ a good boy.', ['am', 'is', 'are'], 0, 'I am a good boy.')],
        ),
        GrammarPage(
          title: 'He / She / It + is',
          explain: "Pakai 'is' untuk he, she, it (satu orang atau benda).",
          examples: [
            ge('He is tall.', 'Dia (laki-laki) tinggi.', '🧍'),
            ge('She is my mom.', 'Dia (perempuan) ibuku.', '👩'),
            ge('It is a dog.', 'Itu seekor anjing.', '🐶'),
          ],
          challenges: [ch('She ___ my teacher.', ['is', 'am', 'are'], 0, 'She is my teacher.')],
        ),
        GrammarPage(
          title: 'You / We / They + are',
          explain: "Pakai 'are' untuk you, we, dan they.",
          examples: [
            ge('You are my friend.', 'Kamu temanku.', '🧑‍🤝‍🧑'),
            ge('We are happy.', 'Kami senang.', '👨‍👩‍👧'),
            ge('They are students.', 'Mereka murid-murid.', '🧑‍🎓'),
          ],
          challenges: [ch('They ___ playing.', ['are', 'is', 'am'], 0, 'They are playing.')],
        ),
        GrammarPage(
          title: 'Bentuk Tidak (Negatif)',
          explain: "is not = isn't, are not = aren't. Artinya 'bukan/tidak'.",
          examples: [
            ge('I am not sad.', 'Saya tidak sedih.', '😊'),
            ge("He isn't angry.", 'Dia tidak marah.', '😌'),
            ge("They aren't late.", 'Mereka tidak terlambat.', '⏰'),
          ],
          challenges: [ch("He ___ happy. (tidak)", ["isn't", "aren't", "am not"], 0, "He isn't happy.")],
        ),
        GrammarPage(
          title: 'Bertanya dengan To Be',
          explain: 'Tukar posisi! Is she...? Are they...? Am I...?',
          examples: [
            ge('Is she your mom?', 'Apakah dia ibumu?', '👩'),
            ge('Are they friends?', 'Apakah mereka teman?', '👫'),
            ge('Am I late?', 'Apakah saya terlambat?', '⏰'),
          ],
          challenges: [ch('___ she your mom?', ['Is', 'Are', 'Am'], 0, 'Is she your mom?')],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Pilih am, is, atau are. Kamu pasti bisa!',
          challenges: [
            ch('I ___ seven years old.', ['am', 'is', 'are'], 0, 'I am seven years old.'),
            ch('We ___ happy.', ['are', 'is', 'am'], 0, 'We are happy.'),
            ch('It ___ a cat.', ['is', 'are', 'am'], 0, 'It is a cat.'),
            ch('___ you ready?', ['Are', 'Is', 'Am'], 0, 'Are you ready?'),
            ch('They ___ not here.', ['are', 'is', 'am'], 0, 'They are not here.'),
          ],
        ),
      ],
    ),
    Unit.grammar(
      id: 'g4_present',
      title: 'Simple Present',
      titleId: 'Simple Present Tense',
      emoji: '⏰',
      pages: [
        GrammarPage(
          title: 'I / You / We / They + kata kerja',
          explain: 'Untuk kebiasaan sehari-hari. Untuk I, you, we, they: kata kerjanya tetap biasa.',
          examples: [
            ge('I play ball every day.', 'Saya bermain bola setiap hari.', '⚽'),
            ge('They eat rice.', 'Mereka makan nasi.', '🍚'),
            ge('We go to school.', 'Kami pergi ke sekolah.', '🏫'),
          ],
          challenges: [
            ch('They ___ football on Sunday.', ['play', 'plays', 'playing'], 0, 'They play football on Sunday.')
          ],
        ),
        GrammarPage(
          title: 'He / She / It + kata kerja + s/es',
          explain: "Untuk he, she, it: kata kerja tambah 's' atau 'es'. Play → plays, go → goes.",
          examples: [
            ge('He plays ball.', 'Dia bermain bola.', '⚽'),
            ge('She goes to school.', 'Dia pergi ke sekolah.', '🏫'),
            ge('It eats fish.', 'Ia makan ikan.', '🐱'),
          ],
          challenges: [
            ch('She ___ to school every day.', ['goes', 'go', 'going'], 0, 'She goes to school every day.')
          ],
        ),
        GrammarPage(
          title: '+ s/es Spesial',
          explain: 'go → goes, watch → watches, study → studies, have → has. Hafalkan ya!',
          examples: [
            ge('He watches TV.', 'Dia menonton TV.', '📺'),
            ge('She studies English.', 'Dia belajar bahasa Inggris.', '📚'),
            ge('It has four legs.', 'Ia punya empat kaki.', '🐕'),
          ],
          challenges: [ch('She ___ English.', ['studies', 'studys', 'study'], 0, 'She studies English.')],
        ),
        GrammarPage(
          title: 'Bertanya: Do dan Does',
          explain: "Untuk bertanya pakai 'do' (I/you/we/they) dan 'does' (he/she/it).",
          examples: [
            ge('Do you like milk?', 'Apakah kamu suka susu?', '🥛'),
            ge('Does he play ball?', 'Apakah dia bermain bola?', '⚽'),
            ge('Do they swim?', 'Apakah mereka berenang?', '🏊'),
          ],
          challenges: [ch('___ she like ice cream?', ['Does', 'Do', 'Is'], 0, 'Does she like ice cream?')],
        ),
        GrammarPage(
          title: "Tidak: don't dan doesn't",
          explain: "Kalimat tidak: don't untuk I/you/we/they, doesn't untuk he/she/it.",
          examples: [
            ge("I don't like snakes.", 'Saya tidak suka ular.', '🐍'),
            ge("He doesn't eat fish.", 'Dia tidak makan ikan.', '🐟'),
            ge("They don't play at night.", 'Mereka tidak bermain di malam hari.', '🌙'),
          ],
          challenges: [
            ch("He ___ like vegetables.", ["doesn't", "don't", "isn't"], 0, "He doesn't like vegetables.")
          ],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Uji kemampuanmu! Ingat aturan s/es dan do/does.',
          challenges: [
            ch('I ___ up at six.', ['wake', 'wakes', 'waking'], 0, 'I wake up at six.'),
            ch('He ___ TV every night.', ['watches', 'watch', 'watching'], 0, 'He watches TV every night.'),
            ch('___ you like coffee?', ['Do', 'Does', 'Are'], 0, 'Do you like coffee?'),
            ch('My dad ___ to work by car.', ['goes', 'go', 'going'], 0, 'My dad goes to work by car.'),
            ch('They ___ not play inside.', ['do', 'does', 'are'], 0, 'They do not play inside.'),
            ch('She ___ two cats.', ['has', 'have', 'haves'], 0, 'She has two cats.'),
          ],
        ),
      ],
    ),
    Unit.grammar(
      id: 'g4_continuous',
      title: 'Present Continuous',
      titleId: 'Sedang Terjadi (-ing)',
      emoji: '🎬',
      pages: [
        GrammarPage(
          title: 'am/is/are + kata kerja-ing',
          explain: 'Untuk kegiatan yang SEDANG terjadi sekarang: am/is/are + kata kerja + ing.',
          examples: [
            ge('I am reading now.', 'Saya sedang membaca sekarang.', '📖'),
            ge('She is cooking.', 'Dia sedang memasak.', '🍳'),
            ge('They are playing.', 'Mereka sedang bermain.', '⚽'),
          ],
          challenges: [ch('Look! The baby ___ crying.', ['is', 'are', 'am'], 0, 'Look! The baby is crying.')],
        ),
        GrammarPage(
          title: 'Aturan +ing',
          explain: "run → running, swim → swimming (huruf terakhir ganda). write → writing, make → making (huruf 'e' hilang).",
          examples: [
            ge('He is running.', 'Dia sedang berlari.', '🏃'),
            ge('I am writing.', 'Saya sedang menulis.', '✍️'),
            ge('We are swimming.', 'Kami sedang berenang.', '🏊'),
          ],
          challenges: [ch('He is ___ now.', ['running', 'runing', 'run'], 0, 'He is running now.')],
        ),
        GrammarPage(
          title: 'Negatif & Bertanya',
          explain: 'Negatif: is/are + not. Bertanya: Is/Are di depan.',
          examples: [
            ge('She is not sleeping.', 'Dia tidak sedang tidur.', '😴'),
            ge('Are they playing?', 'Apakah mereka sedang bermain?', '⚽'),
            ge('Is it raining?', 'Apakah sedang hujan?', '🌧️'),
          ],
          challenges: [ch('___ they playing?', ['Are', 'Is', 'Am'], 0, 'Are they playing?')],
        ),
        GrammarPage(
          title: 'Kata Kunci Waktu',
          explain: "Tanda sedang terjadi: now (sekarang), Look! (Lihat!), Listen! (Dengar!), today (hari ini).",
          examples: [
            ge('Listen! The birds are singing.', 'Dengar! Burung-burung sedang bernyanyi.', '🐦'),
            ge('Look! It is raining.', 'Lihat! Sedang hujan.', '🌧️'),
            ge('We are studying now.', 'Kami sedang belajar sekarang.', '📚'),
          ],
          challenges: [ch('Listen! The birds ___ singing.', ['are', 'is', 'am'], 0, 'Listen! The birds are singing.')],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Pilih jawaban yang tepat!',
          challenges: [
            ch('I ___ reading now.', ['am', 'is', 'are'], 0, 'I am reading now.'),
            ch('She ___ cooking dinner.', ['is', 'are', 'am'], 0, 'She is cooking dinner.'),
            ch('They ___ playing soccer.', ['are', 'is', 'am'], 0, 'They are playing soccer.'),
            ch('Look! It ___ raining.', ['is', 'are', 'am'], 0, 'Look! It is raining.'),
            ch('We ___ studying English.', ['are', 'is', 'am'], 0, 'We are studying English.'),
            ch('He is ___ a letter.', ['writing', 'writeing', 'write'], 0, 'He is writing a letter.'),
          ],
        ),
      ],
    ),
  ],
);
