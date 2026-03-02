import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/obstacle.dart';
import '../components/coin.dart';
import '../components/powerup.dart';
import '../config/game_config.dart';

/// Manages obstacle, coin, and power-up spawning
class ObstacleManager extends Component {
  final List<Obstacle> _obstacles = [];
  final List<Coin> _coins = [];
  final List<PowerUp> _powerUps = [];
  
  double _spawnTimer = 0;
  double _currentSpawnInterval = GameConfig.obstacleSpawnInterval;
  double _gameSpeed = GameConfig.playerSpeed;
  final double _groundY = GameConfig.worldHeight - GameConfig.groundHeight;
  final Random _random = Random();
  
  /// Grace period at game start — no obstacles for the first 2.5 seconds
  double _gracePeriod = 2.5;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Countdown grace period before any obstacles spawn
    if (_gracePeriod > 0) {
      _gracePeriod -= dt;
      return; // Skip all spawning during grace period
    }
    
    // Update spawn timer
    _spawnTimer += dt;
    
    // Spawn new obstacles when timer expires
    if (_spawnTimer >= _currentSpawnInterval) {
      _spawnObstacle();
      _spawnTimer = 0;
    }
    
    // Update all obstacles
    for (final obstacle in _obstacles) {
      obstacle.updateSpeed(_gameSpeed);
    }
    
    // Update all coins
    for (final coin in _coins) {
      coin.updateSpeed(_gameSpeed);
    }
    
    // Update all power-ups
    for (final powerUp in _powerUps) {
      powerUp.updateSpeed(_gameSpeed);
    }
    
    // Remove off-screen objects
    _cleanupOffScreenObjects();
  }
  
  void _spawnObstacle() {
    // Determine spawn position
    double spawnX = GameConfig.worldWidth + GameConfig.spawnDistance;
    
    // Ensure minimum spacing from last obstacle
    if (_obstacles.isNotEmpty) {
      final lastObstacle = _obstacles.last;
      final minX = lastObstacle.position.x + GameConfig.minObstacleSpacing;
      if (spawnX < minX) {
        spawnX = minX;
      }
    }
    
    // Add some random spacing
    spawnX += _random.nextDouble() * 
             (GameConfig.maxObstacleSpacing - GameConfig.minObstacleSpacing);
    
    // Create obstacle
    final obstacleType = ObstacleFactory.getRandomObstacleType();
    final obstacle = ObstacleFactory.createObstacle(
      obstacleType, 
      Vector2(spawnX, _groundY),
    );
    
    _obstacles.add(obstacle);
    parent?.add(obstacle);
    
    // Spawn coins near obstacle
    _spawnCoinsForObstacle(obstacle);
    
    // Chance to spawn power-up
    if (_random.nextDouble() < GameConfig.powerUpSpawnChance) {
      _spawnPowerUp(spawnX);
    }
  }
  
  void _spawnCoinsForObstacle(Obstacle obstacle) {
    if (_random.nextDouble() > GameConfig.coinSpawnChance) return;
    
    final coinCount = 1 + _random.nextInt(3); // 1-3 coins
    final baseX = obstacle.position.x;
    final baseY = _groundY - 50; // Above ground
    
    // Adjust coin placement based on obstacle type
    late Vector2 startPosition;
    late Vector2 direction;
    
    switch (obstacle.type) {
      case ObstacleType.log:
      case ObstacleType.rockHead:
      case ObstacleType.fire:
        // Coins above ground obstacles (jump to collect)
        startPosition = Vector2(baseX, baseY - 50);
        direction = Vector2(GameConfig.coinSpacing, -10);
        break;
        
      case ObstacleType.vine:
      case ObstacleType.saw:
        // Coins low (slide to collect while dodging overhead)
        startPosition = Vector2(baseX - 40, baseY + 20);
        direction = Vector2(GameConfig.coinSpacing, 0);
        break;
        
      case ObstacleType.gap:
        // Coins over the gap
        startPosition = Vector2(baseX + 20, baseY - 30);
        direction = Vector2(GameConfig.coinSpacing, 0);
        break;
    }
    
    // Create coins
    for (int i = 0; i < coinCount; i++) {
      final coinPosition = startPosition + direction * i.toDouble();
      final coin = Coin(position: coinPosition);
      
      _coins.add(coin);
      parent?.add(coin);
    }
  }
  
  void _spawnPowerUp(double spawnX) {
    final powerUpType = PowerUpFactory.getRandomPowerUpType();
    final position = Vector2(
      spawnX + 50, // Slightly offset from obstacle
      _groundY - 60, // Above ground
    );
    
    final powerUp = PowerUpFactory.createPowerUp(powerUpType, position);
    _powerUps.add(powerUp);
    parent?.add(powerUp);
  }
  
  void _cleanupOffScreenObjects() {
    // Remove off-screen obstacles
    _obstacles.removeWhere((obstacle) {
      if (obstacle.isOffScreen) {
        obstacle.removeFromParent();
        return true;
      }
      return false;
    });
    
    // Remove off-screen or collected coins
    _coins.removeWhere((coin) {
      if (coin.isOffScreen || coin.isCollected) {
        if (!coin.isCollected) coin.removeFromParent();
        return true;
      }
      return false;
    });
    
    // Remove off-screen or collected power-ups
    _powerUps.removeWhere((powerUp) {
      if (powerUp.isOffScreen || powerUp.isCollected) {
        if (!powerUp.isCollected) powerUp.removeFromParent();
        return true;
      }
      return false;
    });
  }
  
  /// Update game speed for all objects
  void updateSpeed(double newSpeed) {
    _gameSpeed = newSpeed;
  }
  
  /// Update spawn interval (for difficulty progression)
  void updateSpawnInterval(double newInterval) {
    _currentSpawnInterval = newInterval;
  }
  
  /// Get all active obstacles
  List<Obstacle> get obstacles => _obstacles;
  
  /// Get all active coins
  List<Coin> get coins => _coins;
  
  /// Get all active power-ups
  List<PowerUp> get powerUps => _powerUps;
  
  /// Check collision with obstacles
  bool checkObstacleCollision(Rect playerBounds, bool hasShield) {
    if (hasShield) return false; // Shield protects from obstacles
    
    for (final obstacle in _obstacles) {
      if (obstacle.isLethal && playerBounds.overlaps(obstacle.bounds)) {
        return true;
      }
    }
    return false;
  }
  
  /// Check collision with coins
  List<Coin> checkCoinCollisions(Rect playerBounds) {
    final collectedCoins = <Coin>[];
    
    for (final coin in _coins) {
      if (!coin.isCollected && playerBounds.overlaps(coin.bounds)) {
        coin.collect();
        collectedCoins.add(coin);
      }
    }
    
    return collectedCoins;
  }
  
  /// Check collision with power-ups
  List<PowerUp> checkPowerUpCollisions(Rect playerBounds) {
    final collectedPowerUps = <PowerUp>[];
    
    for (final powerUp in _powerUps) {
      if (!powerUp.isCollected && playerBounds.overlaps(powerUp.bounds)) {
        powerUp.collect();
        collectedPowerUps.add(powerUp);
      }
    }
    
    return collectedPowerUps;
  }
  
  /// Apply magnet effect to coins
  void applyMagnetEffect(Vector2 playerPosition, double magnetRange) {
    for (final coin in _coins) {
      if (!coin.isCollected) {
        final distance = (coin.position - playerPosition).length;
        if (distance <= magnetRange) {
          coin.moveTowardsPlayer(playerPosition, magnetRange, 1.0 / 60); // Assume 60 FPS
        }
      }
    }
  }
  
  /// Clear all objects (for game reset)
  void clearAll() {
    // Remove all obstacles
    for (final obstacle in _obstacles) {
      obstacle.removeFromParent();
    }
    _obstacles.clear();
    
    // Remove all coins
    for (final coin in _coins) {
      coin.removeFromParent();
    }
    _coins.clear();
    
    // Remove all power-ups
    for (final powerUp in _powerUps) {
      powerUp.removeFromParent();
    }
    _powerUps.clear();
    
    // Reset spawn timer and grace period
    _spawnTimer = 0;
    _gracePeriod = 2.5;
  }
}