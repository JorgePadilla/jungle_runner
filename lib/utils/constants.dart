import 'package:flutter/material.dart';

/// Global constants for the game
class GameConstants {
  // Screen dimensions (will be updated at runtime)
  static double screenWidth = 400;
  static double screenHeight = 800;

  // ── Legacy Colors (keep for backward compat) ──────────────────────
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
  static const Color blue = Color(0xFF1E88E5);

  // ── Semantic Color Palette ────────────────────────────────────────
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252542);
  static const Color onSurface = Color(0xFFE8E8F0);
  static const Color onSurfaceDim = Color(0xFF9E9EB8);
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentLight = Color(0xFF33FFCC);
  static const Color danger = Color(0xFFFF4757);
  static const Color dangerLight = Color(0xFFFF6B81);
  static const Color success = Color(0xFF2ED573);
  static const Color successLight = Color(0xFF7BED9F);
  static const Color warning = Color(0xFFFFD700);
  static const Color warningDark = Color(0xFFE6A800);
  static const Color coinGold = Color(0xFFFFD700);
  static const Color coinGoldDark = Color(0xFFCC9900);
  static const Color cardBg = Color(0xFF16213E);
  static const Color cardBgLight = Color(0xFF1A2744);
  static const Color shimmer = Color(0xFF3A3A5C);

  // ── UI Constants (legacy) ─────────────────────────────────────────
  static const double buttonHeight = 60;
  static const double buttonRadius = 15;
  static const double padding = 16;
  static const double hudMargin = 16;
  static const double pauseButtonSize = 48;

  // ── Spacing ───────────────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ── Border Radius ─────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ── Animation Durations ───────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationEntrance = Duration(milliseconds: 600);
  static const Duration durationPageTransition = Duration(milliseconds: 400);

  // ── Legacy Text Styles ────────────────────────────────────────────
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

  // ── Text Style Hierarchy ──────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    color: onSurface,
    letterSpacing: 2.0,
    shadows: [
      Shadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x80000000)),
    ],
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: onSurface,
    letterSpacing: 1.5,
    shadows: [
      Shadow(offset: Offset(0, 2), blurRadius: 6, color: Color(0x60000000)),
    ],
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: onSurface,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: onSurface,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: onSurfaceDim,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: onSurface,
    letterSpacing: 1.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: onSurfaceDim,
    letterSpacing: 0.8,
  );

  // ── Gradients ─────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F0C29),
      Color(0xFF302B63),
      Color(0xFF24243E),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF00B894)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFA502)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4757), Color(0xFFFF6348)],
  );

  // ── Google Play Games Services ────────────────────────────────────
  static const String androidLeaderboardId = 'CgkI5uy33KUPEAIQAA';
}

/// Ad Unit IDs - Production (Jungle Runner)
class AdConstants {
  // Production Ad Unit IDs
  static const String testBannerId = 'ca-app-pub-1170851332113980/6190263855';
  static const String testInterstitialId = 'ca-app-pub-1170851332113980/4354438009';
  static const String testRewardedId = 'ca-app-pub-1170851332113980/5513177241';
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
  static const String activeMissions = 'active_missions';
  static const String completedMissionsCount = 'completed_missions_count';
}
