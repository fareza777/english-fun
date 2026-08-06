import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

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
  /// wrong-answer count per English word (lowercased) -> "weak words".
  final Map<String, int> _wrong = {};
  int _coins = 0;
  final Set<String> _owned = {};
  String _hat = '';
  int _gamesToday = 0;
  int _gamesTotal = 0;
  int _dailyGoal = 3;
  bool _reducedMotion = false;

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
  bool get anySpeakStar => _stars.keys.any((k) => k.endsWith(':speak') && (_stars[k] ?? 0) > 0);

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
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
      final rawWrong = _prefs!.getString('wrong_map') ?? '';
      if (rawWrong.isNotEmpty) {
        final decoded = jsonDecode(rawWrong);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v is int) _wrong['$k'] = v;
          });
        }
      }
      _updateStreak();
      _rollDailyCounters();
      notifyListeners();
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

  int unitsDone(Grade grade) => grade.units.where((u) => unitStars(u) > 0).length;

  // ---- word mastery (spaced repetition data) ----

  /// Call whenever the kid answers a word incorrectly.
  void recordWrong(String word) {
    final k = word.trim().toLowerCase();
    if (k.isEmpty) return;
    _wrong[k] = (_wrong[k] ?? 0) + 1;
    notifyListeners();
    try {
      _prefs?.setString('wrong_map', jsonEncode(_wrong));
    } catch (_) {}
  }

  /// Call when the kid answers a word correctly: it slowly heals mastery.
  void recordCorrect(String word) {
    final k = word.trim().toLowerCase();
    if (k.isEmpty || !(_wrong[k] != null && _wrong[k]! > 0)) return;
    _wrong[k] = _wrong[k]! - 1;
    try {
      _prefs?.setString('wrong_map', jsonEncode(_wrong));
    } catch (_) {}
  }

  int wrongCount(String word) => _wrong[word.trim().toLowerCase()] ?? 0;

  /// Words the kid struggles with, weakest first.
  List<MapEntry<String, int>> weakWords({int limit = 10}) {
    final entries = _wrong.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
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
    _wrong.clear();
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
      final keys = _prefs?.getKeys().where((k) => k.startsWith(_prefix)).toList() ?? [];
      for (final k in keys) {
        await _prefs?.remove(k);
      }
      for (final k in [
        'stickers',
        'streak',
        'last_open',
        'wrong_map',
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
