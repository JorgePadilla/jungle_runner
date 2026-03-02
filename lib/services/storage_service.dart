import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../game/config/game_config.dart';

/// Service to handle persistent storage using SharedPreferences
class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._internal();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._internal();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // High Score
  Future<int> getHighScore() async {
    return _prefs?.getInt(StorageKeys.highScore) ?? 0;
  }

  Future<void> setHighScore(int score) async {
    await _prefs?.setInt(StorageKeys.highScore, score);
  }

  // Total Coins
  Future<int> getTotalCoins() async {
    return _prefs?.getInt(StorageKeys.totalCoins) ?? 0;
  }

  Future<void> setTotalCoins(int coins) async {
    await _prefs?.setInt(StorageKeys.totalCoins, coins);
  }

  Future<void> addCoins(int coins) async {
    final current = await getTotalCoins();
    await setTotalCoins(current + coins);
  }

  Future<bool> spendCoins(int amount) async {
    final current = await getTotalCoins();
    if (current >= amount) {
      await setTotalCoins(current - amount);
      return true;
    }
    return false;
  }

  // Unlocked Skins
  Future<List<String>> getUnlockedSkins() async {
    final skins = _prefs?.getStringList(StorageKeys.unlockedSkins);
    return skins ?? ['default']; // Default skin is always unlocked
  }

  Future<void> unlockSkin(String skinId) async {
    final unlockedSkins = await getUnlockedSkins();
    if (!unlockedSkins.contains(skinId)) {
      unlockedSkins.add(skinId);
      await _prefs?.setStringList(StorageKeys.unlockedSkins, unlockedSkins);
    }
  }

  // Selected Skin
  Future<String> getSelectedSkin() async {
    return _prefs?.getString(StorageKeys.selectedSkin) ?? 'default';
  }

  Future<void> setSelectedSkin(String skinId) async {
    await _prefs?.setString(StorageKeys.selectedSkin, skinId);
  }

  // Death Count (for ad frequency)
  Future<int> getDeathCount() async {
    return _prefs?.getInt(StorageKeys.deathCount) ?? 0;
  }

  Future<void> incrementDeathCount() async {
    final current = await getDeathCount();
    await _prefs?.setInt(StorageKeys.deathCount, current + 1);
  }

  Future<void> resetDeathCount() async {
    await _prefs?.setInt(StorageKeys.deathCount, 0);
  }

  // Daily Reward
  Future<DateTime?> getLastDailyReward() async {
    final timestamp = _prefs?.getInt(StorageKeys.lastDailyReward);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  Future<void> setLastDailyReward(DateTime date) async {
    await _prefs?.setInt(StorageKeys.lastDailyReward, date.millisecondsSinceEpoch);
  }

  Future<bool> canClaimDailyReward() async {
    final lastReward = await getLastDailyReward();
    if (lastReward == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastReward);
    return difference.inHours >= 24;
  }

  Future<int> getDailyRewardStreak() async {
    final lastReward = await getLastDailyReward();
    if (lastReward == null) return 0;

    final now = DateTime.now();
    final daysSinceLastReward = now.difference(lastReward).inDays;

    if (daysSinceLastReward == 1) {
      // Continue streak
      return _prefs?.getInt('daily_streak') ?? 0;
    } else if (daysSinceLastReward == 0) {
      // Same day
      return _prefs?.getInt('daily_streak') ?? 0;
    } else {
      // Streak broken
      return 0;
    }
  }

  Future<void> claimDailyReward() async {
    final streak = await getDailyRewardStreak();
    final rewardIndex = streak % GameConfig.dailyRewards.length;
    final reward = GameConfig.dailyRewards[rewardIndex];

    await addCoins(reward);
    await setLastDailyReward(DateTime.now());
    await _prefs?.setInt('daily_streak', streak + 1);
  }

  // Sound Settings
  Future<bool> getSoundEnabled() async {
    return _prefs?.getBool(StorageKeys.soundEnabled) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(StorageKeys.soundEnabled, enabled);
  }

  // Haptic Settings
  Future<bool> getHapticsEnabled() async {
    return _prefs?.getBool(StorageKeys.hapticsEnabled) ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await _prefs?.setBool(StorageKeys.hapticsEnabled, enabled);
  }

  // Tutorial Settings
  Future<bool> hasSeenTutorial() async {
    return _prefs?.getBool('has_seen_tutorial') ?? false;
  }

  Future<void> setTutorialSeen(bool seen) async {
    await _prefs?.setBool('has_seen_tutorial', seen);
  }

  // === Score History ===

  /// Save a completed run to history
  Future<void> addRunToHistory({
    required int score,
    required int coins,
    required int shields,
    required int magnets,
    required int slides,
    required int jumps,
  }) async {
    final history = _prefs?.getStringList('run_history') ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    // Store as "timestamp|score|coins|shields|magnets|slides|jumps"
    history.insert(0, '$now|$score|$coins|$shields|$magnets|$slides|$jumps');
    // Keep last 100 runs
    if (history.length > 100) history.removeRange(100, history.length);
    await _prefs?.setStringList('run_history', history);

    // Update lifetime stats
    final totalRuns = (_prefs?.getInt('total_runs') ?? 0) + 1;
    final totalDistance = (_prefs?.getInt('total_distance') ?? 0) + score;
    final totalCoinsEarned = (_prefs?.getInt('total_coins_earned') ?? 0) + coins;
    final totalJumps = (_prefs?.getInt('total_jumps') ?? 0) + jumps;
    final totalSlides = (_prefs?.getInt('total_slides') ?? 0) + slides;
    await _prefs?.setInt('total_runs', totalRuns);
    await _prefs?.setInt('total_distance', totalDistance);
    await _prefs?.setInt('total_coins_earned', totalCoinsEarned);
    await _prefs?.setInt('total_jumps', totalJumps);
    await _prefs?.setInt('total_slides', totalSlides);
  }

  /// Get run history as list of maps
  Future<List<Map<String, dynamic>>> getRunHistory({int limit = 50}) async {
    final history = _prefs?.getStringList('run_history') ?? [];
    final runs = <Map<String, dynamic>>[];
    for (final entry in history.take(limit)) {
      final parts = entry.split('|');
      if (parts.length >= 3) {
        runs.add({
          'date': DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
          'score': int.parse(parts[1]),
          'coins': int.parse(parts[2]),
          'shields': parts.length > 3 ? int.parse(parts[3]) : 0,
          'magnets': parts.length > 4 ? int.parse(parts[4]) : 0,
          'slides': parts.length > 5 ? int.parse(parts[5]) : 0,
          'jumps': parts.length > 6 ? int.parse(parts[6]) : 0,
        });
      }
    }
    return runs;
  }

  /// Get lifetime stats
  Future<Map<String, int>> getLifetimeStats() async {
    return {
      'totalRuns': _prefs?.getInt('total_runs') ?? 0,
      'totalDistance': _prefs?.getInt('total_distance') ?? 0,
      'totalCoinsEarned': _prefs?.getInt('total_coins_earned') ?? 0,
      'totalJumps': _prefs?.getInt('total_jumps') ?? 0,
      'totalSlides': _prefs?.getInt('total_slides') ?? 0,
      'highScore': _prefs?.getInt(StorageKeys.highScore) ?? 0,
    };
  }

  // Clear all data (for testing)
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
