import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  ScoreService._();
  static final ScoreService instance = ScoreService._();

  static const String _starsKey = 'total_stars';

  final ValueNotifier<int> totalStarsNotifier = ValueNotifier<int>(0);
  Future<void> _writeQueue = Future<void>.value();

  Future<void> init() async {
    totalStarsNotifier.value = await totalStars;
  }

  Future<int> get totalStars async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_starsKey) ?? 0;
  }

  Future<void> addStars(int count) {
    if (count <= 0) return Future<void>.value();

    final operation = _writeQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_starsKey) ?? 0;
      final updated = current + count;
      await prefs.setInt(_starsKey, updated);
      totalStarsNotifier.value = updated;
    });
    _writeQueue = operation.catchError((Object _, StackTrace __) {});
    return operation;
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
    await _writeQueue;
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((String key) {
      return key == _starsKey || key.startsWith('best_moves_') || key.startsWith('best_streak_');
    }).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    totalStarsNotifier.value = 0;
  }
}
