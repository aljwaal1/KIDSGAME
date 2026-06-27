class ScoreService {
  ScoreService._();
  static final ScoreService instance = ScoreService._();

  int _stars = 0;
  final Map<String, int> _bestMoves = <String, int>{};
  final Map<String, int> _bestStreaks = <String, int>{};

  Future<int> get totalStars async => _stars;

  Future<void> addStars(int count) async {
    if (count <= 0) return;
    _stars += count;
  }

  Future<int?> getBestMoves(String key) async => _bestMoves[key];

  Future<bool> reportMoves(String key, int moves) async {
    final old = _bestMoves[key];
    if (old == null || moves < old) {
      _bestMoves[key] = moves;
      return true;
    }
    return false;
  }

  Future<int?> getBestStreak(String key) async => _bestStreaks[key];

  Future<bool> reportStreak(String key, int streak) async {
    final old = _bestStreaks[key];
    if (old == null || streak > old) {
      _bestStreaks[key] = streak;
      return true;
    }
    return false;
  }

  Future<void> resetProgress() async {
    _stars = 0;
    _bestMoves.clear();
    _bestStreaks.clear();
  }
}
