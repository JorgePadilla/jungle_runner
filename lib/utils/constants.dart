import 'package:flutter/material.dart';

/// Global constants for the game
class GameConstants {
  // Screen dimensions (will be updated at runtime)
  static double screenWidth = 400;
  static double screenHeight = 800;
  
  // Colors
  static const Color primaryGreen = Color(0xFF228B22);
  static const Color darkGreen = Color(0xFF006400);
  static const Color lightGreen = Color(0xFF90EE90);
  static const Color brown = Color(0xFF8B4513);
  static const Color gold = Color(0xFFFFD700);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color red = Color(0xFFFF0000);
  static const Color purple = Color(0xFF800080);
  
  // UI Constants
  static const double buttonHeight = 60;
  static const double buttonRadius = 15;
  static const double padding = 16;
  static const double hudMargin = 16;
  static const double pauseButtonSize = 48;
  static const Color blue = Color(0xFF1E88E5);
  
  // Text styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: white,
    shadows: [
      Shadow(offset: Offset(2, 2), blurRadius: 4, color: black),
    ],
  );
  
  static const TextStyle buttonStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: white,
  );
  
  static const TextStyle scoreStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: white,
    shadows: [
      Shadow(offset: Offset(1, 1), blurRadius: 2, color: black),
    ],
  );
  
  static const TextStyle hudStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: white,
    shadows: [
      Shadow(offset: Offset(1, 1), blurRadius: 2, color: black),
    ],
  );
}

/// Ad Unit IDs for testing
class AdConstants {
  // Test Ad Unit IDs
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
}

/// Storage keys for SharedPreferences
class StorageKeys {
  static const String highScore = 'high_score';
  static const String totalCoins = 'total_coins';
  static const String unlockedSkins = 'unlocked_skins';
  static const String selectedSkin = 'selected_skin';
  static const String deathCount = 'death_count';
  static const String lastDailyReward = 'last_daily_reward';
  static const String soundEnabled = 'sound_enabled';
  static const String hapticsEnabled = 'haptics_enabled';
}