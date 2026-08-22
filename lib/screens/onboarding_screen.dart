import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../models.dart';
import '../services/lesson_builder.dart';
import '../services/progress.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'home_screen.dart';

/// First-launch flow: name, grade, a short placement check, then a tour.
///
/// The placement check is the important part. Its answers seed the spaced
/// repetition memory, so the very first quiz the child plays is already
/// tuned to what they do and do not know, instead of being random.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  final TextEditingController _name = TextEditingController();

  int _step = 0;
  int _grade = 0;

  /// Placement questions, built once the grade is known.
  List<_PlacementQuestion> _questions = const [];
  int _questionIndex = 0;
  final List<String> _known = [];
  final List<String> _missed = [];
  int? _selectedOption;
  bool _locked = false;

  static const _stepCount = 4;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      Sfx.I.speak("Hello! I'm Funky! What's your name?");
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    // Leaving the name field must also dismiss the keyboard, otherwise it
    // covers half of the next step.
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submitName() async {
    final name = _name.text.trim();
    if (name.isNotEmpty) {
      await Progress.I.setName(name);
      Sfx.I.speak('Hello, $name!');
    }
    _goTo(1);
  }

  Future<void> _chooseGrade(int grade) async {
    await Progress.I.setSelectedGrade(grade);
    setState(() {
      _grade = grade;
      _questions = _buildPlacement(grade);
      _questionIndex = 0;
      _selectedOption = null;
      _locked = false;
      _known.clear();
      _missed.clear();
    });
    if (_questions.isEmpty) {
      _goTo(3);
      return;
    }
    _goTo(2);
    Future.delayed(const Duration(milliseconds: 450), _speakQuestion);
  }

  /// Five quick picture questions drawn from across the chosen grade.
  List<_PlacementQuestion> _buildPlacement(int grade) {
    final units = kGrades[(grade - 1).clamp(0, kGrades.length - 1)].units;
    final pool = units.where((u) => u.kind == UnitKind.vocab).expand((u) => u.items).toList();
    if (pool.length < 4) return const [];

    final picked = LessonBuilder.pickItems(pool, 5);
    return [
      for (final item in picked) _PlacementQuestion(item, LessonBuilder.optionsFor(item, pool)),
    ];
  }

  void _speakQuestion() {
    if (_questionIndex < _questions.length) {
      Sfx.I.speak(_questions[_questionIndex].target.en);
    }
  }

  Future<void> _answerPlacement(int index) async {
    if (_locked) return;
    final question = _questions[_questionIndex];
    final chosen = question.options[index];
    final correct = chosen == question.target;

    setState(() {
      _selectedOption = index;
      _locked = true;
    });

    if (correct) {
      _known.add(question.target.en);
      Sfx.I.ding();
    } else {
      _missed.add(question.target.en);
      Sfx.I.wrong();
    }

    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex++;
        _selectedOption = null;
        _locked = false;
      });
      _speakQuestion();
    } else {
      // Seed the SRS so the first real session is already personalised.
      Progress.I.seedPlacement(_known, _missed);
      _goTo(3);
    }
  }

  void _skipPlacement() {
    Sfx.I.click();
    _goTo(3);
  }

  Future<void> _finish() async {
    await Progress.I.markOnboarded();
    if (_grade == 0) await Progress.I.setSelectedGrade(1);
    Sfx.I.fanfare();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(funRoute(const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: ContentWidth(
            child: Column(
              children: [
                _StepDots(current: _step, total: _stepCount),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_nameStep(), _gradeStep(), _placementStep(), _tourStep()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- step 1: name ----

  Widget _nameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Mascot(size: 120 * context.displayScale),
          const SizedBox(height: 14),
          Text('Halo! Aku Funky! 🦊', style: AppText.heading(30)),
          const SizedBox(height: 6),
          Text('Siapa namamu?', style: AppText.body(22)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF7ED6FF), width: 4),
              boxShadow: const [
                BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: TextField(
              controller: _name,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              maxLength: 14,
              style: AppText.heading(28),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]"))],
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'Tulis namamu di sini',
                hintStyle: AppText.body(20, color: Colors.grey.shade400),
              ),
              onSubmitted: (_) => _submitName(),
            ),
          ),
          const SizedBox(height: 22),
          PillButton(
            label: 'Lanjut',
            emoji: '👉',
            color: AppColors.correct,
            fontSize: 22,
            onTap: _submitName,
          ),
        ],
      ),
    );
  }

  // ---- step 2: grade ----

  Widget _gradeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          Mascot(size: 88 * context.displayScale),
          const SizedBox(height: 10),
          Text('Kamu kelas berapa?', style: AppText.heading(28)),
          const SizedBox(height: 4),
          Text('Biar Funky pilihkan pelajaran yang pas ✨', style: AppText.body(16)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final grade in kGrades)
                Semantics(
                  button: true,
                  label: 'Kelas ${grade.level}, ${grade.subtitle}',
                  excludeSemantics: true,
                  child: BouncyButton(
                    onTap: () => _chooseGrade(grade.level),
                    child: Container(
                      width: 132,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: grade.colors),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: grade.colors.last.withValues(alpha: 0.45),
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(grade.emoji, style: const TextStyle(fontSize: 34)),
                          const SizedBox(height: 2),
                          Text('Kelas ${grade.level}', style: AppText.display(20)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          BouncyButton(
            onTap: () {
              Progress.I.setSelectedGrade(1);
              setState(() => _grade = 1);
              _goTo(3);
            },
            child: Text(
              'Nanti saja',
              style: AppText.body(16, color: AppColors.inkSoft.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }

  // ---- step 3: placement check ----

  Widget _placementStep() {
    if (_questions.isEmpty) {
      return const SizedBox.shrink();
    }
    final question = _questions[_questionIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        children: [
          Text('Tes Cepat 🎯', style: AppText.heading(26)),
          Text(
            'Soal ${_questionIndex + 1} dari ${_questions.length} • tidak apa-apa kalau belum tahu!',
            style: AppText.body(14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF7ED6FF), width: 4),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(question.target.emoji, style: const TextStyle(fontSize: 96)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 4,
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final option = question.options[i];
                final isTarget = option == question.target;
                Color color = Colors.white;
                if (_selectedOption != null) {
                  if (isTarget) {
                    color = AppColors.correct;
                  } else if (_selectedOption == i) {
                    color = AppColors.wrong;
                  }
                }
                final onColor = color == Colors.white ? AppColors.ink : Colors.white;
                return BouncyButton(
                  onTap: _locked ? null : () => _answerPlacement(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Text(
                      option.en,
                      textAlign: TextAlign.center,
                      style: AppText.heading(22, color: onColor),
                    ),
                  ),
                );
              },
            ),
          ),
          TextButton(
            onPressed: _skipPlacement,
            child: Text('Lewati tes', style: AppText.body(15, color: AppColors.inkSoft)),
          ),
        ],
      ),
    );
  }

  // ---- step 4: tour ----

  Widget _tourStep() {
    final name = Progress.I.playerName;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          Mascot(size: 96 * context.displayScale),
          const SizedBox(height: 8),
          Text(name.isEmpty ? 'Siap bertualang?' : 'Siap, $name?', style: AppText.heading(28)),
          const SizedBox(height: 4),
          Text('Ini cara mainnya:', style: AppText.body(17)),
          const SizedBox(height: 16),
          const _TourCard(
            emoji: '⭐',
            title: 'Kumpulkan bintang',
            body: 'Selesaikan permainan di tiap unit untuk membuka unit berikutnya.',
          ),
          const _TourCard(
            emoji: '🪙',
            title: 'Belanja dengan koin',
            body: 'Tiap bintang baru memberi koin untuk topi, telur, dan peliharaan.',
          ),
          const _TourCard(
            emoji: '🔥',
            title: 'Main tiap hari',
            body: 'Main setiap hari untuk menjaga api streak tetap menyala!',
          ),
          const SizedBox(height: 18),
          PillButton(
            label: 'Mulai Petualangan!',
            emoji: '🚀',
            color: AppColors.correct,
            fontSize: 22,
            onTap: _finish,
          ),
        ],
      ),
    );
  }
}

class _PlacementQuestion {
  final VocabItem target;
  final List<VocabItem> options;
  const _PlacementQuestion(this.target, this.options);
}

class _TourCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _TourCard({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading(18)),
                Text(body, style: AppText.body(14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress dots across the top of the flow.
class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Langkah ${current + 1} dari $total',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final active = i <= current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == current ? 26 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: active ? AppColors.correct : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ),
    );
  }
}
