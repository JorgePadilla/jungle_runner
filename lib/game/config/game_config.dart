/// Game configuration with all tunable parameters
class GameConfig {
  // World settings
  static const double worldWidth = 1000;
  static const double worldHeight = 600;
  static const double groundHeight = 100;
  
  // Player settings
  static const double playerWidth = 40;
  static const double playerHeight = 60;
  static const double playerSpeed = 200; // Initial speed
  static const double jumpVelocity = 400;
  static const double doubleJumpVelocity = 350;
  static const double gravity = 1200;
  static const double slideHeight = 30;
  static const double slideDuration = 0.8; // seconds
  
  // Parallax background
  static const List<double> parallaxSpeeds = [
    0.1,  // Sky (slowest)
    0.2,  // Far mountains
    0.4,  // Mid trees
    0.7,  // Near trees
    1.0,  // Ground (full speed)
  ];
  
  // Obstacle settings
  static const double obstacleSpawnInterval = 2.0; // seconds
  static const double minObstacleSpacing = 150;
  static const double maxObstacleSpacing = 300;
  static const double obstacleWidth = 50;
  static const double logHeight = 50;
  static const double vineHeight = 40;
  static const double gapWidth = 120;
  
  // Collectibles
  static const double coinSize = 20;
  static const double coinSpawnChance = 0.7; // 70% chance per obstacle
  static const int coinValue = 10;
  static const double coinSpacing = 30;
  
  // Power-ups
  static const double powerUpSize = 30;
  static const double powerUpSpawnChance = 0.1; // 10% chance per obstacle
  static const double shieldDuration = 5.0; // seconds
  static const double magnetDuration = 5.0; // seconds
  static const double magnetRange = 100;
  
  // Difficulty progression
  static const double speedIncreaseRate = 5; // speed increase per 100m
  static const double maxSpeed = 400;
  static const double obstacleFrequencyIncrease = 0.95; // multiply interval by this every 200m
  static const double minObstacleInterval = 1.0;
  
  // Scoring
  static const double scoreMultiplier = 0.1; // score = distance * multiplier
  
  // Game mechanics
  static const double despawnDistance = 200; // Distance behind player to remove objects
  static const double spawnDistance = 800; // Distance ahead to spawn objects
  
  // Audio
  static const double masterVolume = 0.7;
  static const double sfxVolume = 0.8;
  static const double musicVolume = 0.5;
  
  // UI
  static const double hudMargin = 20;
  static const double pauseButtonSize = 50;
  
  // Ads
  static const int interstitialAdInterval = 3; // Show ad every 3rd death
  
  // Shop
  static const Map<String, int> skinPrices = {
    'default': 0,
    'golden': 500,
    'dark': 300,
    'rainbow': 1000,
    'ninja': 750,
  };
  
  static const Map<String, String> skinNames = {
    'default': 'Classic Monkey',
    'golden': 'Golden Monkey',
    'dark': 'Shadow Monkey',
    'rainbow': 'Rainbow Monkey',
    'ninja': 'Ninja Monkey',
  };
  
  // Daily rewards
  static const List<int> dailyRewards = [50, 75, 100, 150, 200, 300, 500];
}