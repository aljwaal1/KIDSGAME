import 'package:shared_preferences/shared_preferences.dart';

/// Stores light gamification data across app restarts: total stars earned,
/// best (fewest) puzzle moves per difficulty, and best bubble streak.
class ScoreService {
  ScoreService._internal();

  static final ScoreService instance = ScoreService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsInstance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<int> get totalStars async {
    final prefs = await _prefsInstance;
    return prefs.getInt('kga_total_stars') ?? 0;
  }

  Future<int> addStars(int amount) async {
    final prefs = await _prefsInstance;
    final total = (prefs.getInt('kga_total_stars') ?? 0) + amount;
    await prefs.setInt('kga_total_stars', total);
    return total;
  }

  Future<int?> getBestMoves(String puzzleKey) async {
    final prefs = await _prefsInstance;
    return prefs.getInt('kga_best_moves_$puzzleKey');
  }

  /// Saves [moves] as the new best for [puzzleKey] if it beats the
  /// previous record. Returns true when a new record was set.
  Future<bool> reportMoves(String puzzleKey, int moves) async {
    final prefs = await _prefsInstance;
    final key = 'kga_best_moves_$puzzleKey';
    final current = prefs.getInt(key);
    if (current == null || moves < current) {
      await prefs.setInt(key, moves);
      return true;
    }
    return false;
  }

  Future<int> getBestStreak(String gameKey) async {
    final prefs = await _prefsInstance;
    return prefs.getInt('kga_best_streak_$gameKey') ?? 0;
  }

  /// Saves [streak] as the new best for [gameKey] if it beats the previous
  /// record. Returns true when a new record was set.
  Future<bool> reportStreak(String gameKey, int streak) async {
    final prefs = await _prefsInstance;
    final key = 'kga_best_streak_$gameKey';
    final current = prefs.getInt(key) ?? 0;
    if (streak > current) {
      await prefs.setInt(key, streak);
      return true;
    }
    return false;
  }

  /// Clears all stars and best-result records (does not touch the mute
  /// preference).
  Future<void> resetProgress() async {
    final prefs = await _prefsInstance;
    final keys = prefs.getKeys().where(
          (k) => k.startsWith('kga_total_stars') || k.startsWith('kga_best_'),
        );
    for (final key in keys.toList()) {
      await prefs.remove(key);
    }
  }
}
