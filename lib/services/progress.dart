import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'srs.dart';

/// Tracks stars, player name, daily streak, stickers, word mastery,
/// coins, shop items, daily goal and accessibility options.
class Progress extends ChangeNotifier {
  Progress._();
  static final Progress I = Progress._();

  static const _prefix = 'st_';
  SharedPreferences? _prefs;
  final Map<String, int> _stars = {};
  String _name = '';
  int _streak = 0;
  final Set<String> _stickers = {};

  // ---- v2: mastery / economy / stats ----
  /// Spaced-repetition memory per English word (lowercased).
  /// Replaces the v2 plain wrong-counter; old data is migrated on load.
  final Map<String, WordMemory> _memory = {};
  int _coins = 0;
  final Set<String> _owned = {};
  String _hat = '';
  int _gamesToday = 0;
  int _gamesTotal = 0;
  int _dailyGoal = 3;
  bool _reducedMotion = false;

  /// Grade chosen during onboarding (1-6). 0 = not chosen yet.
  int _selectedGrade = 0;

  // ---- v3: pets, spin, badges ----
  int _eggs = 0;
  final List<String> _pets = [];
  String _activePet = '';
  String _lastFed = '';
  String _lastSpin = '';
  final Set<String> _badges = {};

  String get playerName => _name;
  int get streak => _streak;
  Set<String> get stickers => Set.unmodifiable(_stickers);

  int get coins => _coins;
  Set<String> get ownedItems => Set.unmodifiable(_owned);
  String get equippedHat => _hat;
  int get gamesToday => _gamesToday;
  int get gamesTotal => _gamesTotal;
  int get dailyGoal => _dailyGoal;
  bool get reducedMotion => _reducedMotion;
  bool get dailyGoalReached => _gamesToday >= _dailyGoal;

  /// Grade picked in onboarding, or 0 when the child skipped that step.
  int get selectedGrade => _selectedGrade;

  /// Grade to open by default across the app (never 0).
  int get preferredGrade => _selectedGrade == 0 ? 1 : _selectedGrade;

  /// True once onboarding has run at least once.
  bool get onboarded => _prefs?.getBool('onboarded') ?? false;

  int get eggs => _eggs;
  List<String> get pets => List.unmodifiable(_pets);
  String get activePet => _activePet;
  Set<String> get badges => Set.unmodifiable(_badges);
  bool get canFeedToday => _lastFed != _fmtDate(DateTime.now());
  bool get canSpinToday => _lastSpin != _fmtDate(DateTime.now());

  /// Any boss battle won (for badges).
  bool get anyBossWin =>
      _stars.keys.any((k) => k.startsWith('boss_g') && (_stars[k] ?? 0) > 0);

  /// Any speaking-game star earned (for badges).
  bool get anySpeakStar =>
      _stars.keys.any((k) => k.endsWith(':speak') && (_stars[k] ?? 0) > 0);

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // Start from a clean slate so a reload never merges two profiles.
      _stars.clear();
      _stickers.clear();
      _memory.clear();
      _owned.clear();
      _pets.clear();
      _badges.clear();
      for (final key in _prefs!.getKeys()) {
        if (key.startsWith(_prefix)) {
          final v = _prefs!.getInt(key);
          if (v != null) _stars[key.substring(_prefix.length)] = v;
        }
      }
      _name = _prefs!.getString('name') ?? '';
      _stickers.addAll(_prefs!.getStringList('stickers') ?? const []);
      _coins = _prefs!.getInt('coins') ?? 0;
      _owned.addAll(_prefs!.getStringList('owned_items') ?? const []);
      _hat = _prefs!.getString('equipped_hat') ?? '';
      _gamesTotal = _prefs!.getInt('games_total') ?? 0;
      _dailyGoal = _prefs!.getInt('daily_goal') ?? 3;
      _reducedMotion = _prefs!.getBool('reduced_motion') ?? false;
      _eggs = _prefs!.getInt('eggs') ?? 0;
      _pets.addAll(_prefs!.getStringList('pets') ?? const []);
      _activePet = _prefs!.getString('active_pet') ?? '';
      _lastFed = _prefs!.getString('last_fed') ?? '';
      _lastSpin = _prefs!.getString('last_spin') ?? '';
      _badges.addAll(_prefs!.getStringList('badges') ?? const []);
      _selectedGrade = (_prefs!.getInt('selected_grade') ?? 0).clamp(0, 6);
      _loadMemory();
      _updateStreak();
      _rollDailyCounters();
      notifyListeners();
    } catch (_) {}
  }

  /// Reads the v3 memory map, falling back to migrating the v2 wrong-counter
  /// so players who update the app keep the words they were struggling with.
  void _loadMemory() {
    final rawMemory = _prefs?.getString('memory_v3') ?? '';
    if (rawMemory.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMemory);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            final memory = WordMemory.fromJson(v);
            if (memory != null) _memory['$k'] = memory;
          });
          return;
        }
      } catch (_) {
        // Corrupt payload: fall through to the legacy migration below.
      }
    }

    final rawWrong = _prefs?.getString('wrong_map') ?? '';
    if (rawWrong.isEmpty) return;
    try {
      final decoded = jsonDecode(rawWrong);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          if (v is int && v > 0) {
            _memory['$k'] = WordMemory.fromLegacyWrongCount(v);
          }
        });
        _persistMemory();
      }
    } catch (_) {}
  }

  void _persistMemory() {
    try {
      final payload = {
        for (final entry in _memory.entries) entry.key: entry.value.toJson(),
      };
      _prefs?.setString('memory_v3', jsonEncode(payload));
    } catch (_) {}
  }

  void _updateStreak() {
    final now = DateTime.now();
    final today = _fmtDate(now);
    final yesterday = _fmtDate(now.subtract(const Duration(days: 1)));
    final last = _prefs?.getString('last_open') ?? '';
    _streak = _prefs?.getInt('streak') ?? 0;
    if (last == today) return;
    _streak = (last == yesterday) ? _streak + 1 : 1;
    _prefs?.setString('last_open', today);
    _prefs?.setInt('streak', _streak);
  }

  /// Resets per-day counters when the calendar day changes.
  void _rollDailyCounters() {
    final today = _fmtDate(DateTime.now());
    if (_prefs?.getString('games_date') == today) {
      _gamesToday = _prefs?.getInt('games_today') ?? 0;
    } else {
      _gamesToday = 0;
      _prefs?.setString('games_date', today);
      _prefs?.setInt('games_today', 0);
    }
  }

  Future<void> setName(String name) async {
    _name = name;
    notifyListeners();
    try {
      await _prefs?.setString('name', name);
    } catch (_) {}
  }

  /// Returns false if the sticker was already earned.
  bool awardSticker(String emoji) {
    if (_stickers.contains(emoji)) return false;
    _stickers.add(emoji);
    notifyListeners();
    try {
      _prefs?.setStringList('stickers', _stickers.toList());
    } catch (_) {}
    return true;
  }

  String _key(String unitId, String game) => '$unitId:$game';

  int stars(String unitId, String game) => _stars[_key(unitId, game)] ?? 0;

  Future<void> setStars(String unitId, String game, int value) async {
    final old = stars(unitId, game);
    if (value <= old) return;
    _stars[_key(unitId, game)] = value;
    _coins += (value - old) * 10; // new stars pay out coins
    notifyListeners();
    try {
      await _prefs?.setInt('$_prefix${_key(unitId, game)}', value);
      await _prefs?.setInt('coins', _coins);
    } catch (_) {}
  }

  int unitStars(Unit u) => u.games.fold(0, (sum, g) => sum + stars(u.id, g));

  int gradeStars(Grade g) => g.units.fold(0, (sum, u) => sum + unitStars(u));

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  /// Sequential unlock inside a grade: a unit opens when the previous one
  /// has earned at least one star.
  bool unitUnlocked(Grade grade, int index) {
    if (index <= 0) return true;
    return unitStars(grade.units[index - 1]) > 0;
  }

  int unitsDone(Grade grade) =>
      grade.units.where((u) => unitStars(u) > 0).length;

  // ---- word mastery (spaced repetition) ----

  static String _wordKey(String word) => word.trim().toLowerCase();

  /// Memory for one word, or null when it has never been studied.
  WordMemory? memoryFor(String word) => _memory[_wordKey(word)];

  /// Records one answer and reschedules the word. This is the single entry
  /// point every game uses, so scheduling stays consistent app-wide.
  void recordAnswer(String word, {required bool correct}) {
    final k = _wordKey(word);
    if (k.isEmpty) return;
    final previous = _memory[k] ?? const WordMemory();
    _memory[k] = previous.answer(correct: correct, now: DateTime.now());
    notifyListeners();
    _persistMemory();
  }

  /// Call whenever the kid answers a word incorrectly.
  void recordWrong(String word) => recordAnswer(word, correct: false);

  /// Call when the kid answers a word correctly: it promotes the word to the
  /// next Leitner box and pushes the next review further out.
  void recordCorrect(String word) => recordAnswer(word, correct: true);

  int wrongCount(String word) => memoryFor(word)?.wrong ?? 0;

  /// How many studied words are ready for review right now.
  int get dueWordCount {
    final now = DateTime.now();
    return _memory.values.where((m) => !m.isNew && m.isDue(now)).length;
  }

  /// Words the kid struggles with, weakest first.
  List<MapEntry<String, int>> weakWords({int limit = 10}) {
    final entries =
        _memory.entries
            .where((e) => e.value.wrong > 0 && e.value.box <= 2)
            .map((e) => MapEntry(e.key, e.value.wrong))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Seeds memory from an onboarding placement check so the very first
  /// session is already personalised.
  void seedPlacement(
    Iterable<String> knownWords,
    Iterable<String> missedWords,
  ) {
    final now = DateTime.now();
    for (final word in knownWords) {
      final k = _wordKey(word);
      if (k.isEmpty) continue;
      _memory[k] = const WordMemory(box: 2).answer(correct: true, now: now);
    }
    for (final word in missedWords) {
      final k = _wordKey(word);
      if (k.isEmpty) continue;
      _memory[k] = const WordMemory().answer(correct: false, now: now);
    }
    notifyListeners();
    _persistMemory();
  }

  // ---- coins & shop ----

  void addCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    notifyListeners();
    try {
      _prefs?.setInt('coins', _coins);
    } catch (_) {}
  }

  bool buyItem(String id, int price) {
    if (_owned.contains(id) || _coins < price) return false;
    _coins -= price;
    _owned.add(id);
    notifyListeners();
    try {
      _prefs?.setInt('coins', _coins);
      _prefs?.setStringList('owned_items', _owned.toList());
    } catch (_) {}
    return true;
  }

  void equipHat(String id) {
    if (id.isNotEmpty && !_owned.contains(id)) return;
    _hat = id;
    notifyListeners();
    try {
      _prefs?.setString('equipped_hat', id);
    } catch (_) {}
  }

  // ---- daily stats & goal ----

  /// Count one finished game (drives the daily goal + parent stats).
  void countGame() {
    _rollDailyCounters();
    _gamesToday++;
    _gamesTotal++;
    notifyListeners();
    try {
      _prefs?.setInt('games_today', _gamesToday);
      _prefs?.setInt('games_total', _gamesTotal);
    } catch (_) {}
  }

  void setDailyGoal(int goal) {
    _dailyGoal = goal.clamp(1, 20);
    notifyListeners();
    try {
      _prefs?.setInt('daily_goal', _dailyGoal);
    } catch (_) {}
  }

  void setReducedMotion(bool value) {
    _reducedMotion = value;
    notifyListeners();
    try {
      _prefs?.setBool('reduced_motion', value);
    } catch (_) {}
  }

  /// Stores the grade chosen during onboarding (1-6).
  Future<void> setSelectedGrade(int grade) async {
    _selectedGrade = grade.clamp(0, 6);
    notifyListeners();
    try {
      await _prefs?.setInt('selected_grade', _selectedGrade);
    } catch (_) {}
  }

  /// Marks onboarding as finished so it never shows again.
  Future<void> markOnboarded() async {
    try {
      await _prefs?.setBool('onboarded', true);
    } catch (_) {}
    notifyListeners();
  }

  /// Clears the local profile identity so onboarding can be run again.
  ///
  /// Learning progress intentionally stays on the device. The parent-facing
  /// reset action remains the separate, destructive way to wipe progress.
  Future<void> logout() async {
    _name = '';
    _selectedGrade = 0;
    notifyListeners();
    try {
      await _prefs?.remove('name');
      await _prefs?.remove('onboarded');
      await _prefs?.remove('selected_grade');
    } catch (_) {}
  }

  /// Deletes the local child profile and all learning data so the next app
  /// launch can start a completely fresh onboarding flow.
  ///
  /// The one-time remove-ads entitlement is intentionally not touched: it is
  /// owned by the Google Play account, not by this on-device profile.
  Future<void> deleteAccount() async {
    _name = '';
    _stars.clear();
    _stickers.clear();
    _memory.clear();
    _owned.clear();
    _hat = '';
    _coins = 0;
    _gamesToday = 0;
    _gamesTotal = 0;
    _dailyGoal = 3;
    _reducedMotion = false;
    _selectedGrade = 0;
    _streak = 0;
    _eggs = 0;
    _pets.clear();
    _activePet = '';
    _lastFed = '';
    _lastSpin = '';
    _badges.clear();
    notifyListeners();

    try {
      for (final key in [
        'name',
        'onboarded',
        'selected_grade',
        'daily_goal',
        'reduced_motion',
        'stickers',
        'streak',
        'last_open',
        'wrong_map',
        'memory_v3',
        'coins',
        'owned_items',
        'equipped_hat',
        'games_today',
        'games_total',
        'games_date',
        'eggs',
        'pets',
        'active_pet',
        'last_fed',
        'last_spin',
        'badges',
      ]) {
        await _prefs?.remove(key);
      }
      final starKeys =
          _prefs?.getKeys().where((key) => key.startsWith(_prefix)).toList() ??
          const <String>[];
      for (final key in starKeys) {
        await _prefs?.remove(key);
      }
    } catch (_) {}
  }

  // ---- pets, spin, badges ----

  void addEggs(int n) {
    if (n <= 0) return;
    _eggs += n;
    notifyListeners();
    try {
      _prefs?.setInt('eggs', _eggs);
    } catch (_) {}
  }

  /// Buy an egg with coins. Returns false when coins are insufficient.
  bool buyEgg([int price = 40]) {
    if (_coins < price) return false;
    _coins -= price;
    _eggs++;
    notifyListeners();
    try {
      _prefs?.setInt('coins', _coins);
      _prefs?.setInt('eggs', _eggs);
    } catch (_) {}
    return true;
  }

  /// Hatch one egg into a pet id. Returns null when no eggs are left.
  String? hatchEgg(String petId) {
    if (_eggs <= 0) return null;
    _eggs--;
    _pets.add(petId);
    _activePet = petId;
    notifyListeners();
    try {
      _prefs?.setInt('eggs', _eggs);
      _prefs?.setStringList('pets', _pets);
      _prefs?.setString('active_pet', _activePet);
    } catch (_) {}
    return petId;
  }

  void setActivePet(String petId) {
    _activePet = petId;
    notifyListeners();
    try {
      _prefs?.setString('active_pet', petId);
    } catch (_) {}
  }

  void markFedToday() {
    _lastFed = _fmtDate(DateTime.now());
    try {
      _prefs?.setString('last_fed', _lastFed);
    } catch (_) {}
  }

  void markSpunToday() {
    _lastSpin = _fmtDate(DateTime.now());
    notifyListeners();
    try {
      _prefs?.setString('last_spin', _lastSpin);
    } catch (_) {}
  }

  /// Returns true the first time a badge is unlocked.
  bool unlockBadge(String id) {
    if (_badges.contains(id)) return false;
    _badges.add(id);
    notifyListeners();
    try {
      _prefs?.setStringList('badges', _badges.toList());
    } catch (_) {}
    return true;
  }

  /// Wipes stars, streak, stickers, mastery, coins and items (keeps the name).
  Future<void> reset() async {
    _stars.clear();
    _stickers.clear();
    _memory.clear();
    _owned.clear();
    _hat = '';
    _coins = 0;
    _gamesToday = 0;
    _gamesTotal = 0;
    _streak = 0;
    _eggs = 0;
    _pets.clear();
    _activePet = '';
    _lastFed = '';
    _lastSpin = '';
    _badges.clear();
    notifyListeners();
    try {
      final keys =
          _prefs?.getKeys().where((k) => k.startsWith(_prefix)).toList() ?? [];
      for (final k in keys) {
        await _prefs?.remove(k);
      }
      for (final k in [
        'stickers',
        'streak',
        'last_open',
        'wrong_map',
        'memory_v3',
        'coins',
        'owned_items',
        'equipped_hat',
        'games_today',
        'games_total',
        'games_date',
        'eggs',
        'pets',
        'active_pet',
        'last_fed',
        'last_spin',
        'badges',
      ]) {
        await _prefs?.remove(k);
      }
      _updateStreak();
      _rollDailyCounters();
      notifyListeners();
    } catch (_) {}
  }
}
