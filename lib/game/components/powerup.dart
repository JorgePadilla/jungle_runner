import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/game_config.dart';

enum PowerUpType { shield, magnet }

abstract class PowerUp extends SpriteComponent {
  double _gameSpeed = 1.0;
  double _pulseTimer = 0;
  final double _pulseFrequency = 1.5;
  bool _collected = false;
  
  PowerUpType get type;
  double getDuration();
  
  PowerUp() {
    size = Vector2(GameConfig.powerUpSize.toDouble(), GameConfig.powerUpSize.toDouble());
    anchor = Anchor.center;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_collected) {
      return;
    }
    
    // Update pulsing animation
    _pulseTimer += dt;
    final pulseScale = 1.0 + math.sin(_pulseTimer * _pulseFrequency * 2 * math.pi) * 0.1;
    scale = Vector2.all(pulseScale);
    
    // Move left with game speed
    position.x -= _gameSpeed * GameConfig.baseScrollSpeed * dt;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw glow effect
    _drawGlowEffect(canvas);
  }
  
  void _drawGlowEffect(Canvas canvas) {
    final glowPaint = Paint()
      ..color = _getGlowColor().withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final center = size / 2;
    canvas.drawCircle(center.toOffset(), size.x / 2 + 5, glowPaint);
  }
  
  Color _getGlowColor() {
    switch (type) {
      case PowerUpType.shield:
        return Colors.blue;
      case PowerUpType.magnet:
        return Colors.yellow;
    }
  }
  
  void updateSpeed(double speed) {
    _gameSpeed = speed;
  }
  
  bool get isOffScreen => position.x + size.x < 0;
  
  /// Collection bounds — 40% larger than visual for generous pickup.
  Rect get bounds {
    final expand = size.x * 0.4;
    return Rect.fromLTWH(
      position.x - size.x / 2 - expand,
      position.y - size.y / 2 - expand,
      size.x + expand * 2,
      size.y + expand * 2,
    );
  }
  
  void collect() {
    _collected = true;
    removeFromParent();
  }
  
  bool get isCollected => _collected;
}

class ShieldPowerUp extends PowerUp {
  @override
  PowerUpType get type => PowerUpType.shield;
  
  @override
  double getDuration() => 5.0; // 5 seconds of shield
  
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('powerups/shield.png');
  }
}

class MagnetPowerUp extends PowerUp {
  @override
  PowerUpType get type => PowerUpType.magnet;
  
  @override
  double getDuration() => 8.0; // 8 seconds of magnet
  
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('powerups/magnet.png');
  }
}

class PowerUpFactory {
  static final math.Random _random = math.Random();
  
  static List<PowerUpType> get availableTypes => [
    PowerUpType.shield,
    PowerUpType.magnet,
  ];
  
  static PowerUpType getRandomPowerUpType() {
    return availableTypes[_random.nextInt(availableTypes.length)];
  }
  
  static PowerUp createPowerUp(PowerUpType type, Vector2 position) {
    PowerUp powerUp;
    switch (type) {
      case PowerUpType.shield:
        powerUp = ShieldPowerUp();
        break;
      case PowerUpType.magnet:
        powerUp = MagnetPowerUp();
        break;
    }
    powerUp.position = position;
    return powerUp;
  }
}