import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/player.dart';
import 'components/ground.dart';
import 'components/parallax_bg.dart';
import 'components/coin.dart';
import 'components/powerup.dart';
import 'managers/obstacle_manager.dart';
import 'managers/difficulty_manager.dart';
import 'config/game_config.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

enum GameState { playing, paused, gameOver }

/// Main game class that handles game logic and state
class JungleRunnerGame extends FlameGame 
    with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  
  // Game components
  late Player _player;
  late Ground _ground;
  late ParallaxBackground _background;
  late ObstacleManager _obstacleManager;
  late DifficultyManager _difficultyManager;
  
  // Game state
  GameState _gameState = GameState.playing;
  int _coinsCollected = 0;
  bool _hapticsEnabled = true;
  int _currentRunCoins = 0;
  int _highScore = 0;
  bool _highScoreBroken = false;
  String _selectedSkin = 'default';
  
  // Power-up timers
  double _shieldTimer = 0;
  double _magnetTimer = 0;
  
  // Input handling
  double _lastTapTime = 0;
  bool _isSwipeDetected = false;
  
  // Callbacks for UI updates
  Function(int score, int coins)? onScoreChanged;
  Function()? onGameOver;
  Function()? onPause;
  Function()? onHighScoreBroken;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load preferences
    final storageService = await StorageService.getInstance();
    _selectedSkin = await storageService.getSelectedSkin();
    _coinsCollected = await storageService.getTotalCoins();
    _hapticsEnabled = await storageService.getHapticsEnabled();
    _highScore = await storageService.getHighScore();
    
    // Initialize game components
    await _initializeGame();
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
  }
  
  @override
  void update(double dt) {
    if (_gameState != GameState.playing) return;
    
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
  
  void _checkCollisions() {
    final playerBounds = _player.bounds;
    
    // Check obstacle collisions
    if (_obstacleManager.checkObstacleCollision(playerBounds, _player.hasShield)) {
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
    _currentRunCoins += coin.coinValue;
    _vibrate(HapticFeedback.lightImpact);
    // TODO: Play coin collection sound
  }
  
  void _collectPowerUp(PowerUp powerUp) {
    _vibrate(HapticFeedback.mediumImpact);
    switch (powerUp.type) {
      case PowerUpType.shield:
        _player.activateShield(powerUp.getDuration());
        _shieldTimer = powerUp.getDuration();
        break;
        
      case PowerUpType.magnet:
        _player.activateMagnet(powerUp.getDuration());
        _magnetTimer = powerUp.getDuration();
        break;
    }
    // TODO: Play power-up collection sound
  }
  
  void _gameOver() {
    _gameState = GameState.gameOver;
    _vibrate(HapticFeedback.heavyImpact);

    // Camera shake effect
    // In newer Flame versions, we use viewports/viewfinders or custom effects
    // For simplicity, we'll use the viewport shake if available or skip for now
    // Actually, let's use a simpler way if shake is not directly on camera
    
    // Save coins and high score
    _saveGameData();
    
    // Notify UI
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
    
    // Increment death count for ads
    await storageService.incrementDeathCount();
  }
  
  // Input handling
  @override
  void onTapDown(TapDownEvent event) {
    if (_gameState != GameState.playing) return;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Check for double tap (for double jump)
    bool jumped = false;
    if (currentTime - _lastTapTime < 0.3) {
      // Double tap - try double jump
      jumped = _player.jump();
    } else {
      // Single tap - jump
      jumped = _player.jump();
    }

    if (jumped) {
      _vibrate(HapticFeedback.selectionClick);
    }
    
    _lastTapTime = currentTime;
  }
  
  // Handle swipe down for slide
  void _handleSwipeDown() {
    if (_gameState == GameState.playing) {
      _player.slide();
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
    
    // Resume engine if paused
    resumeEngine();
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
    
    // Resume engine
    resumeEngine();
  }
  
  // Getters for game state
  GameState get gameState => _gameState;
  int get currentScore => _difficultyManager.score;
  int get currentRunCoins => _currentRunCoins;
  int get totalCoins => _coinsCollected + _currentRunCoins;
  double get distanceTraveled => _difficultyManager.distanceTraveled;
  bool get hasShield => _player.hasShield;
  bool get hasMagnet => _player.hasMagnet;
  double get shieldTimeRemaining => _shieldTimer;
  double get magnetTimeRemaining => _magnetTimer;
  String get difficultyLevel => _difficultyManager.getDifficultyDescription();
  
  // Handle swipe gestures (called from game screen)
  void handleSwipe(String direction) {
    if (direction == 'down') {
      _handleSwipeDown();
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