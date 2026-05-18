import 'package:hive_flutter/hive_flutter.dart';

class ScoreService {
  static const String _boxName = 'orbit_scores';
  static const String _bestScoreKey = 'best_score';

  static Box? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static int getBestScore() {
    return _box?.get(_bestScoreKey, defaultValue: 0) ?? 0;
  }

  static Future<void> saveBestScore(int score) async {
    final current = getBestScore();
    if (score > current) {
      await _box?.put(_bestScoreKey, score);
    }
  }
}
