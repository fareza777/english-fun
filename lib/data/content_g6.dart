import '../models.dart';
import '../theme.dart';

/// KELAS 6 — Master Muda (8 unit)
final Grade grade6 = Grade(
  level: 6,
  title: 'Kelas 6',
  subtitle: 'Master Muda',
  emoji: '👑',
  colors: GradePalette.all[5],
  units: [
    Unit.vocab(
      id: 'g6_countries',
      title: 'Countries',
      titleId: 'Negara-Negara',
      emoji: '🌍',
      items: [
        v('Indonesia', 'Indonesia', '🇮🇩', sentence: 'I am from Indonesia.'),
        v('Japan', 'Jepang', '🇯🇵', sentence: 'Japan has beautiful sakura.'),
        v('America', 'Amerika', '🇺🇸', sentence: 'America is far away.'),
        v('England', 'Inggris', '🇬🇧', sentence: 'They speak English in England.'),
        v('Australia', 'Australia', '🇦🇺', sentence: 'Kangaroos live in Australia.'),
        v('Egypt', 'Mesir', '🇪🇬', sentence: 'The pyramids are in Egypt.'),
        v('China', 'Tiongkok', '🇨🇳', sentence: 'China has the Great Wall.'),
        v('India', 'India', '🇮🇳', sentence: 'The Taj Mahal is in India.'),
        v('Korea', 'Korea', '🇰🇷', sentence: 'K-pop is from Korea.'),
        v('Brazil', 'Brasil', '🇧🇷', sentence: 'Brazil loves soccer.'),
      ],
    ),
    Unit.vocab(
      id: 'g6_subjects',
      title: 'School Subjects',
      titleId: 'Mata Pelajaran',
      emoji: '📚',
      items: [
        v('Math', 'Matematika', '➗', sentence: 'I like Math.'),
        v('Science', 'IPA', '🔬', sentence: 'Science is fun.'),
        v('Music', 'Musik', '🎵', sentence: 'We sing in Music class.'),
        v('Art', 'Seni', '🖼️', sentence: 'I draw in Art class.'),
        v('Sports', 'Olahraga', '🏅', sentence: 'We run in Sports class.'),
        v('Computer', 'Komputer', '💻', sentence: 'I type in Computer class.'),
        v('History', 'Sejarah', '📜', sentence: 'History tells old stories.'),
        v('Geography', 'Geografi', '🌍', sentence: 'Geography is about the world.'),
      ],
    ),
    Unit.grammar(
      id: 'g6_havehas',
      title: 'Have & Has',
      titleId: 'Punya: have / has',
      emoji: '🎁',
      pages: [
        GrammarPage(
          title: 'I / You / We / They + have',
          explain: "Pakai 'have' untuk I, you, we, they. Artinya: punya.",
          examples: [
            ge('I have two eyes.', 'Saya punya dua mata.', '👁️'),
            ge('They have a big house.', 'Mereka punya rumah besar.', '🏠'),
            ge('We have lunch at noon.', 'Kami makan siang jam dua belas.', '🍚'),
          ],
          challenges: [ch('I ___ two eyes.', ['have', 'has', 'haves'], 0, 'I have two eyes.')],
        ),
        GrammarPage(
          title: 'He / She / It + has',
          explain: "Pakai 'has' untuk he, she, it.",
          examples: [
            ge('She has a cat.', 'Dia punya seekor kucing.', '🐱'),
            ge('He has a new bike.', 'Dia punya sepeda baru.', '🚲'),
            ge('It has four legs.', 'Ia punya empat kaki.', '🐕'),
          ],
          challenges: [ch('She ___ a cat.', ['has', 'have', 'haves'], 0, 'She has a cat.')],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Pilih have atau has!',
          challenges: [
            ch('They ___ many books.', ['have', 'has', 'haves'], 0, 'They have many books.'),
            ch('He ___ a new bike.', ['has', 'have', 'haves'], 0, 'He has a new bike.'),
            ch('We ___ lunch at noon.', ['have', 'has', 'haves'], 0, 'We have lunch at noon.'),
            ch('The dog ___ four legs.', ['has', 'have', 'haves'], 0, 'The dog has four legs.'),
          ],
        ),
      ],
    ),
    Unit.grammar(
      id: 'g6_thereis',
      title: 'There is / There are',
      titleId: 'Ada: there is / there are',
      emoji: '👀',
      pages: [
        GrammarPage(
          title: 'There is (satu)',
          explain: "Pakai 'There is' untuk SATU benda. Artinya: ada.",
          examples: [
            ge('There is a cat on the bed.', 'Ada kucing di atas tempat tidur.', '🐱'),
            ge('There is a book on the table.', 'Ada buku di atas meja.', '📖'),
          ],
          challenges: [ch('There ___ a cat on the bed.', ['is', 'are', 'am'], 0, 'There is a cat on the bed.')],
        ),
        GrammarPage(
          title: 'There are (banyak)',
          explain: "Pakai 'There are' untuk BANYAK benda.",
          examples: [
            ge('There are three birds.', 'Ada tiga burung.', '🐦🐦🐦'),
            ge('There are many stars.', 'Ada banyak bintang.', '⭐'),
          ],
          challenges: [ch('There ___ three birds.', ['are', 'is', 'am'], 0, 'There are three birds.')],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Pilih is atau are!',
          challenges: [
            ch('There ___ a book on the table.', ['is', 'are', 'am'], 0, 'There is a book on the table.'),
            ch('There ___ five apples.', ['are', 'is', 'am'], 0, 'There are five apples.'),
            ch('___ there a park near here?', ['Is', 'Are', 'Am'], 0, 'Is there a park near here?'),
            ch('There ___ some water.', ['is', 'are', 'be'], 0, 'There is some water.'),
          ],
        ),
      ],
    ),
    Unit.grammar(
      id: 'g6_conjunction',
      title: 'And, But, Because',
      titleId: 'Kata Sambung',
      emoji: '🔗',
      pages: [
        GrammarPage(
          title: 'and (dan)',
          explain: "Pakai 'and' untuk menggabungkan dua hal yang sejalan.",
          examples: [
            ge('I like cats and dogs.', 'Saya suka kucing dan anjing.', '🐱🐶'),
            ge('She sings and dances.', 'Dia bernyanyi dan menari.', '🎤💃'),
          ],
          challenges: [ch('I like cats ___ dogs.', ['and', 'but', 'because'], 0, 'I like cats and dogs.')],
        ),
        GrammarPage(
          title: 'but (tetapi) & because (karena)',
          explain: "'But' untuk hal yang berlawanan. 'Because' untuk alasan.",
          examples: [
            ge('I like fish but I don\'t like shrimp.', 'Saya suka ikan tetapi tidak suka udang.', '🐟'),
            ge('I am sad because it rains.', 'Saya sedih karena hujan.', '🌧️'),
          ],
          challenges: [ch('I am sad ___ it rains.', ['because', 'but', 'and'], 0, 'I am sad because it rains.')],
        ),
        GrammarPage(
          title: 'Latihan! 💪',
          explain: 'Pilih kata sambung yang tepat!',
          challenges: [
            ch('She is smart ___ kind.', ['and', 'but', 'because'], 0, 'She is smart and kind.'),
            ch("I like fish ___ I don't like shrimp.", ['but', 'and', 'because'], 0, "I like fish but I don't like shrimp."),
            ch('He sleeps early ___ he is tired.', ['because', 'but', 'and'], 0, 'He sleeps early because he is tired.'),
            ch('We play ___ study every day.', ['and', 'but', 'because'], 0, 'We play and study every day.'),
          ],
        ),
      ],
    ),
    Unit.story(
      id: 'g6_story1',
      title: 'A Day at the Zoo',
      titleId: 'Cerita: Sehari di Kebun Binatang',
      emoji: '🦁',
      story: Story(
        title: 'A Day at the Zoo',
        emoji: '🦁',
        lines: const [
          StoryLine('Today is Sunday.', 'Hari ini hari Minggu.', '🌞'),
          StoryLine('I go to the zoo with my family.', 'Aku pergi ke kebun binatang bersama keluargaku.', '👨‍👩‍👧'),
          StoryLine('I see a big elephant.', 'Aku melihat gajah yang besar.', '🐘'),
          StoryLine('The monkeys are funny.', 'Monyet-monyet itu lucu.', '🐵'),
          StoryLine('I eat ice cream with my brother.', 'Aku makan es krim bersama kakakku.', '🍦'),
          StoryLine('We are happy today.', 'Kami senang hari ini.', '😊'),
        ],
        questions: const [
          Challenge('What day is it?', ['Sunday', 'Monday', 'Friday'], 0, 'Today is Sunday.'),
          Challenge('Where does he go?', ['To the zoo', 'To school', 'To the beach'], 0, 'He goes to the zoo.'),
          Challenge('What does he eat?', ['Ice cream', 'Rice', 'Bread'], 0, 'He eats ice cream.'),
        ],
      ),
    ),
    Unit.story(
      id: 'g6_story2',
      title: 'My Birthday Party',
      titleId: 'Cerita: Pesta Ulang Tahunku',
      emoji: '🎂',
      story: Story(
        title: 'My Birthday Party',
        emoji: '🎂',
        lines: const [
          StoryLine('Today is my birthday.', 'Hari ini ulang tahunku.', '🎂'),
          StoryLine('I am eight years old now.', 'Aku sekarang berumur delapan tahun.', '8️⃣'),
          StoryLine('My friends come to my house.', 'Teman-temanku datang ke rumahku.', '🏠'),
          StoryLine('We sing and dance together.', 'Kami bernyanyi dan menari bersama.', '🎤'),
          StoryLine('Mom gives me a big cake.', 'Ibu memberiku kue yang besar.', '🍰'),
          StoryLine('I am very happy!', 'Aku sangat senang!', '🥳'),
        ],
        questions: const [
          Challenge('How old is she?', ['Eight', 'Seven', 'Ten'], 0, 'She is eight years old.'),
          Challenge('Who comes to the house?', ['Her friends', 'The doctor', 'A teacher'], 0,
              'Her friends come to the house.'),
          Challenge('What does Mom give?', ['A big cake', 'A ball', 'A book'], 0, 'Mom gives a big cake.'),
        ],
      ),
    ),
    Unit.story(
      id: 'g6_story3',
      title: 'A Rainy Day',
      titleId: 'Cerita: Hari Hujan',
      emoji: '🌧️',
      story: Story(
        title: 'A Rainy Day',
        emoji: '🌧️',
        lines: const [
          StoryLine('It is raining today.', 'Hari ini sedang hujan.', '🌧️'),
          StoryLine('I cannot play outside.', 'Aku tidak bisa bermain di luar.', '🏠'),
          StoryLine('I read my favorite book.', 'Aku membaca buku kesukaanku.', '📖'),
          StoryLine('Mom makes hot chocolate for me.', 'Ibu membuatkanku cokelat panas.', '🍫'),
          StoryLine('The rain stops in the afternoon.', 'Hujan berhenti di sore hari.', '🌤️'),
          StoryLine('I see a beautiful rainbow!', 'Aku melihat pelangi yang indah!', '🌈'),
        ],
        questions: const [
          Challenge('How is the weather?', ['Raining', 'Sunny', 'Snowing'], 0, 'It is raining.'),
          Challenge('What does he read?', ['A book', 'A letter', 'A map'], 0, 'He reads a book.'),
          Challenge('What does he see at the end?', ['A rainbow', 'A star', 'The moon'], 0, 'He sees a rainbow.'),
        ],
      ),
    ),
  ],
);
