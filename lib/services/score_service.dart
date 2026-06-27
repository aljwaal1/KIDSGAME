import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  ScoreService._();
  static final ScoreService instance = ScoreService._();

  static const String _starsKey = 'total_stars';

  Future<int> get totalStars async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_starsKey) ?? 0;
  }

  Future<void> addStars(int count) async {
    if (count <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_starsKey) ?? 0;
    await prefs.setInt(_starsKey, current + count);
  }

  Future<int?> getBestMoves(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('best_moves_$key');
  }

  Future<bool> reportMoves(String key, int moves) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = 'best_moves_$key';
    final old = prefs.getInt(prefKey);
    if (old == null || moves < old) {
      await prefs.setInt(prefKey, moves);
      return true;
    }
    return false;
  }

  Future<int?> getBestStreak(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('best_streak_$key');
  }

  Future<bool> reportStreak(String key, int streak) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = 'best_streak_$key';
    final old = prefs.getInt(prefKey);
    if (old == null || streak > old) {
      await prefs.setInt(prefKey, streak);
      return true;
    }
    return false;
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((String key) {
      return key == _starsKey || key.startsWith('best_moves_') || key.startsWith('best_streak_');
    }).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
