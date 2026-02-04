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
  
  // Clear all data (for testing)
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}