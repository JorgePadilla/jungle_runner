import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/player.dart';
import 'components/ground.dart';
import 'components/parallax_bg.dart';
import 'components/coin.dart';
import 'components/powerup.dart';
import 'components/particles.dart';
import 'managers/obstacle_manager.dart';
import 'managers/difficulty_manager.dart';
import 'managers/audio_manager.dart';
import 'effects/screen_shake.dart';
import 'config/game_config.dart';
import '../services/storage_service.dart';
import '../services/play_games_service.dart';

enum GameState { playing, paused, gameOver }

/// Main game class that handles game logic and state
class JungleRunnerGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {

  /// Fill any sub-pixel viewport gaps with sky's top color instead of black
  @override
  Color backgroundColor() => const Color(0xFF191E50);

  // Game components
  late Player _player;
  late Ground _ground;
  late ParallaxBackground _background;
  late ObstacleManager _obstacleManager;
  late DifficultyManager _difficultyManager;
  late ScreenShakeEffect _screenShake;

  // Initialization flag
  bool _isLoaded = false;

  // Game state
  GameState _gameState = GameState.playing;
  int _coinsCollected = 0;
  bool _hapticsEnabled = true;
  int _currentRunCoins = 0;
  int _highScore = 0;
  bool _highScoreBroken = false;
  String _selectedSkin = 'default';

  // Upgrades and Boosters
  int _shieldLevel = 1;
  int _magnetLevel = 1;
  bool _isDoubleCoinsActive = false;

  // Per-run stats for missions
  int _runShieldsUsed = 0;
  int _runMagnetsUsed = 0;
  int _runSlides = 0;
  int _runJumps = 0;

  // Power-up timers
  double _shieldTimer = 0;
  double _magnetTimer = 0;

  // Input handling
  double _lastTapTime = 0;

  // Particle effects
  double _dustParticleTimer = 0;
  static const double dustSpawnInterval = 0.1;

  // Callbacks for UI updates
  Function(int score, int coins)? onScoreChanged;
  Function()? onGameOver;
  Function()? onPause;
  Function()? onHighScoreBroken;

  /// Called on game over with per-run stats.
  /// (distance, coinsCollected, shieldsUsed, magnetsUsed, slides, jumps)
  Function(int distance, int coins, int shields, int magnets, int slides, int jumps)? onGameOverStats;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set up fixed-resolution viewport so the 400x720 game world
    // scales properly to any device screen (portrait mode).
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(GameConfig.worldWidth, GameConfig.worldHeight),
    );

    // Initialize audio manager
    await AudioManager.instance.init();

    // Load player skin preference
    final storageService = await StorageService.getInstance();
    _selectedSkin = await storageService.getSelectedSkin();
    _coinsCollected = await storageService.getTotalCoins();
    _hapticsEnabled = await storageService.getHapticsEnabled();
    _highScore = await storageService.getHighScore();

    // Load upgrades and boosters
    _shieldLevel = await storageService.getShieldLevel();
    _magnetLevel = await storageService.getMagnetLevel();
    _isDoubleCoinsActive = await storageService.isDoubleCoinsPurchased();

    // Initialize game components
    await _initializeGame();

    // Start background music
    await AudioManager.instance.startBackgroundMusic();
  }

  Future<void> _initializeGame() async {
    // Create parallax background
    _background = ParallaxBackground();
    add(_background);

    // Create ground
    _ground = Ground();
    add(_ground);

    // Create player
    _player = Player(groundY: _ground.groundY);
    _player.setSkin(_selectedSkin);
    add(_player);

    // Create obstacle manager
    _obstacleManager = ObstacleManager();
    add(_obstacleManager);

    // Create difficulty manager
    _difficultyManager = DifficultyManager(
      onSpeedChanged: (speed) {
        _background.updateSpeed(speed);
        _ground.updateSpeed(speed);
        _obstacleManager.updateSpeed(speed);
      },
      onObstacleIntervalChanged: (interval) {
        _obstacleManager.updateSpawnInterval(interval);
      },
    );
    add(_difficultyManager);

    // Create screen shake effect
    _screenShake = ScreenShakeEffect();
    add(_screenShake);

    _isLoaded = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded) {
      super.render(canvas);
      return;
    }
    // Apply screen shake offset
    if (_screenShake.isShaking) {
      canvas.save();
      canvas.translate(_screenShake.shakeOffset.x, _screenShake.shakeOffset.y);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  @override
  void update(double dt) {
    if (!_isLoaded || _gameState != GameState.playing) return;

    super.update(dt);

    // Update power-up timers
    _updatePowerUpTimers(dt);

    // Check collisions
    _checkCollisions();

    // Apply magnet effect
    if (_player.hasMagnet) {
      _obstacleManager.applyMagnetEffect(
        _player.position,
        _player.magnetRange,
      );
    }

    // Spawn dust particles when player is running
    _updateDustParticles(dt);

    // Update UI
    onScoreChanged?.call(
      _difficultyManager.score,
      _coinsCollected + _currentRunCoins,
    );

    // Check for high score break
    if (!_highScoreBroken && _difficultyManager.score > _highScore && _difficultyManager.score > 0) {
      _highScoreBroken = true;
      _onHighScoreBroken();
    }
  }

  void _onHighScoreBroken() {
    // Visual feedback for breaking high score
    _vibrate(HapticFeedback.mediumImpact);
    onHighScoreBroken?.call();
  }

  void _updatePowerUpTimers(double dt) {
    if (_shieldTimer > 0) {
      _shieldTimer -= dt;
      if (_shieldTimer <= 0 && _player.hasShield) {
        // Shield expired - handled by player component
      }
    }

    if (_magnetTimer > 0) {
      _magnetTimer -= dt;
      if (_magnetTimer <= 0 && _player.hasMagnet) {
        // Magnet expired - handled by player component
      }
    }
  }

  void _updateDustParticles(double dt) {
    // Only spawn dust when player is running (on ground)
    if (_player.state == PlayerState.running) {
      _dustParticleTimer += dt;

      if (_dustParticleTimer >= dustSpawnInterval) {
        _dustParticleTimer = 0;

        // Spawn dust particles at player's feet
        final dustPosition = Vector2(
          _player.position.x - 10, // Behind the player
          _player.position.y + _player.size.y / 2, // At player's feet
        );

        final dustParticles = ParticleSpawner.spawnRunDust(dustPosition);
        for (final particle in dustParticles) {
          add(particle);
        }
      }
    }
  }

  void _checkCollisions() {
    final playerBounds = _player.bounds;

    // Check obstacle collisions (skip during transition invincibility)
    if (!_player.isInvincible &&
        _obstacleManager.checkObstacleCollision(playerBounds, _player.hasShield)) {
      _gameOver();
      return;
    }

    // Check coin collisions
    final collectedCoins = _obstacleManager.checkCoinCollisions(playerBounds);
    for (final coin in collectedCoins) {
      _collectCoin(coin);
    }

    // Check power-up collisions
    final collectedPowerUps = _obstacleManager.checkPowerUpCollisions(playerBounds);
    for (final powerUp in collectedPowerUps) {
      _collectPowerUp(powerUp);
    }
  }

  void _collectCoin(Coin coin) {
    final value = _isDoubleCoinsActive ? coin.coinValue * 2 : coin.coinValue;
    _currentRunCoins += value;
    _vibrate(HapticFeedback.lightImpact);

    // Play coin collection sound
    AudioManager.instance.playCoinCollect();

    // Spawn coin collection particles
    final coinParticles = ParticleSpawner.spawnCoinCollect(coin.position);
    for (final particle in coinParticles) {
      add(particle);
    }
  }

  void _collectPowerUp(PowerUp powerUp) {
    _vibrate(HapticFeedback.mediumImpact);

    // Play power-up collection sound
    AudioManager.instance.playPowerUp();

    // Spawn power-up particles
    final isShield = powerUp.type == PowerUpType.shield;
    final powerUpParticles = ParticleSpawner.spawnPowerUpBurst(powerUp.position, isShield);
    for (final particle in powerUpParticles) {
      add(particle);
    }

    switch (powerUp.type) {
      case PowerUpType.shield:
        final duration = GameConfig.shieldDurations[_shieldLevel] ?? powerUp.getDuration();
        _player.activateShield(duration);
        _shieldTimer = duration;
        _runShieldsUsed++;
        break;

      case PowerUpType.magnet:
        final duration = GameConfig.magnetDurations[_magnetLevel] ?? powerUp.getDuration();
        _player.activateMagnet(duration);
        _magnetTimer = duration;
        _runMagnetsUsed++;
        break;
    }
  }

  void _gameOver() {
    _gameState = GameState.gameOver;
    _vibrate(HapticFeedback.heavyImpact);

    // Pause the engine to freeze the game state
    pauseEngine();

    // Stop ALL music immediately
    AudioManager.instance.stopBackgroundMusic();

    // Play death sound
    AudioManager.instance.playDeath();

    // Double-stop music after a brief delay (Flame audio can be unreliable)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_gameState == GameState.gameOver) {
        AudioManager.instance.stopBackgroundMusic();
      }
    });

    // Trigger screen shake
    _screenShake.triggerShake(8.0, 0.5);

    // Spawn death explosion particles
    final deathParticles = ParticleSpawner.spawnDeathExplosion(_player.position);
    for (final particle in deathParticles) {
      add(particle);
    }

    // Save coins and high score
    _saveGameData();

    // Pause the engine after a short delay (let shake/particles play out)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_gameState == GameState.gameOver) {
        pauseEngine();
      }
    });

    // Notify UI
    onGameOverStats?.call(
      _difficultyManager.score,
      _currentRunCoins,
      _runShieldsUsed,
      _runMagnetsUsed,
      _runSlides,
      _runJumps,
    );
    onGameOver?.call();
  }

  Future<void> _saveGameData() async {
    final storageService = await StorageService.getInstance();

    // Add coins from current run
    await storageService.addCoins(_currentRunCoins);

    // Update high score
    final currentScore = _difficultyManager.score;
    final highScore = await storageService.getHighScore();
    if (currentScore > highScore) {
      await storageService.setHighScore(currentScore);
    }

    // Submit score to Google Play Games leaderboard
    await PlayGamesService.instance.submitScore(currentScore);

    // Save run to history
    await storageService.addRunToHistory(
      score: currentScore,
      coins: _currentRunCoins,
      shields: _runShieldsUsed,
      magnets: _runMagnetsUsed,
      slides: _runSlides,
      jumps: _runJumps,
    );

    // Increment death count for ads
    await storageService.incrementDeathCount();
  }

  // --- Public input handlers (called from game_screen Listener) ---

  /// Handle a tap (jump / double-jump)
  void handleTap() {
    if (!_isLoaded || _gameState != GameState.playing) return;

    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

    AudioManager.instance.playJump();

    if (currentTime - _lastTapTime < 0.3) {
      _player.jump(); // double jump
    } else {
      _player.jump();
    }
    _vibrate(HapticFeedback.selectionClick);
    _runJumps++;
    _lastTapTime = currentTime;
  }

  /// Handle swipe-down (slide)
  void handleSlide() {
    if (_gameState == GameState.playing) {
      _player.slide();
      _runSlides++;
    }
  }

  // Game control methods
  void pauseGame() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      pauseEngine();
      onPause?.call();
    }
  }

  void resumeGame() {
    if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      resumeEngine();
    }
  }

  void resetGame() {
    _gameState = GameState.playing;
    _currentRunCoins = 0;
    _highScoreBroken = false;
    _shieldTimer = 0;
    _magnetTimer = 0;
    _dustParticleTimer = 0;
    _runShieldsUsed = 0;
    _runMagnetsUsed = 0;
    _runSlides = 0;
    _runJumps = 0;

    // Reset screen shake
    _screenShake.reset();

    // Reset difficulty
    _difficultyManager.reset();

    // Clear obstacles
    _obstacleManager.clearAll();

    // Reset player
    _player.setState(PlayerState.running);
    _player.position = Vector2(
      100,
      _ground.groundY - GameConfig.playerHeight,
    );

    // Resume engine and restart music
    resumeEngine();
    AudioManager.instance.startBackgroundMusic();
  }

  void continueGame(double continueFromDistance) {
    // Set distance in difficulty manager
    _difficultyManager.setDistance(continueFromDistance);

    // Reset game state but maintain progress
    _gameState = GameState.playing;
    _shieldTimer = 0;
    _magnetTimer = 0;

    // Clear current obstacles but don't reset difficulty
    _obstacleManager.clearAll();

    // Reset player position
    _player.setState(PlayerState.running);
    _player.position = Vector2(
      100,
      _ground.groundY - GameConfig.playerHeight,
    );

    // Resume engine and restart music
    resumeEngine();
    AudioManager.instance.startBackgroundMusic();
  }

  // Getters for game state (safe before onLoad completes)
  GameState get gameState => _gameState;
  int get currentScore => _isLoaded ? _difficultyManager.score : 0;
  int get currentRunCoins => _currentRunCoins;
  int get totalCoins => _coinsCollected + _currentRunCoins;
  double get distanceTraveled => _isLoaded ? _difficultyManager.distanceTraveled : 0;
  bool get hasShield => _isLoaded ? _player.hasShield : false;
  bool get hasMagnet => _isLoaded ? _player.hasMagnet : false;
  double get shieldTimeRemaining => _shieldTimer;
  double get magnetTimeRemaining => _magnetTimer;
  String get difficultyLevel => _isLoaded ? _difficultyManager.getDifficultyDescription() : 'Easy';
  int get runShieldsUsed => _runShieldsUsed;
  int get runMagnetsUsed => _runMagnetsUsed;
  int get runSlides => _runSlides;
  int get runJumps => _runJumps;

  // Legacy swipe handler (kept for compatibility)
  void handleSwipe(String direction) {
    if (direction == 'down') {
      handleSlide();
      _vibrate(HapticFeedback.selectionClick);
    }
  }

  void _vibrate(Future<void> Function() feedback) {
    if (_hapticsEnabled) {
      feedback();
    }
  }

  // Update skin
  Future<void> updatePlayerSkin(String skinId) async {
    _selectedSkin = skinId;
    _player.setSkin(skinId);

    final storageService = await StorageService.getInstance();
    await storageService.setSelectedSkin(skinId);
  }
}
