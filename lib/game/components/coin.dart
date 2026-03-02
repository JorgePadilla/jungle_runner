import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/game_config.dart';

class Coin extends SpriteAnimationComponent {
  double _gameSpeed = 1.0;
  double _bounceTimer = 0;
  final double _bounceAmplitude = 5.0;
  final double _bounceFrequency = 2.0;
  late double _baseY;
  bool _collected = false;
  bool _movingToPlayer = false;
  Vector2? _playerPosition;

  // Collection animation properties
  bool _isCollecting = false;
  double _collectTimer = 0;
  double _initialScale = 1.0;
  double _initialOpacity = 1.0;
  Vector2? _collectStartPos;

  final int coinValue = 10;

  Coin({Vector2? position}) {
    size = Vector2(GameConfig.coinSize.toDouble(), GameConfig.coinSize.toDouble());
    anchor = Anchor.center;
    if (position != null) {
      this.position = position;
      _baseY = position.y;
    }
  }

  @override
  Future<void> onLoad() async {
    // Load coin animation from sprite sheet (17 frames)
    final coinImage = await Flame.images.load('collectibles/coin_sheet.png');
    animation = SpriteAnimation.fromFrameData(
      coinImage,
      SpriteAnimationData.sequenced(
        amount: 17,
        stepTime: 0.05,
        textureSize: Vector2(32, 32),
      ),
    );

    _baseY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_collected && !_isCollecting) {
      return;
    }

    if (_isCollecting) {
      _collectTimer += dt;

      // Scale animation: 1.0 -> 1.5 over 0.2s
      const scaleUpDuration = 0.2;
      if (_collectTimer <= scaleUpDuration) {
        final progress = _collectTimer / scaleUpDuration;
        scale = Vector2.all(_initialScale + progress * 0.5);
      }

      // Opacity fade: 1.0 -> 0.0 over 0.3s
      const fadeDuration = 0.3;
      if (_collectTimer <= fadeDuration) {
        final progress = _collectTimer / fadeDuration;
        opacity = _initialOpacity * (1.0 - progress);
      }

      // Move upward slightly during animation
      if (_collectStartPos != null) {
        const upwardSpeed = 50.0;
        position.y = _collectStartPos!.y - upwardSpeed * _collectTimer;
      }

      // Remove when animation is complete
      if (_collectTimer >= fadeDuration) {
        removeFromParent();
      }

      return;
    }

    // Update bounce animation
    _bounceTimer += dt;
    final bounceOffset = math.sin(_bounceTimer * _bounceFrequency * 2 * math.pi) * _bounceAmplitude;
    position.y = _baseY + bounceOffset;

    if (_movingToPlayer && _playerPosition != null) {
      // Move towards player when magnet is active
      final direction = (_playerPosition! - position).normalized();
      const magnetSpeed = 300.0;
      position += direction * magnetSpeed * dt;
    } else {
      // Normal scrolling movement
      position.x -= _gameSpeed * GameConfig.baseScrollSpeed * dt;
    }
  }

  void updateSpeed(double speed) {
    _gameSpeed = speed;
  }

  bool get isOffScreen => position.x + size.x < 0;

  /// Collection bounds -- 50% larger than visual for generous pickup.
  Rect get bounds {
    final expand = size.x * 0.5; // 50% expansion
    return Rect.fromLTWH(
      position.x - size.x / 2 - expand,
      position.y - size.y / 2 - expand,
      size.x + expand * 2,
      size.y + expand * 2,
    );
  }

  void collect() {
    if (_collected || _isCollecting) return;

    _collected = true;
    _isCollecting = true;
    _collectTimer = 0;
    _collectStartPos = position.clone();
    _initialScale = scale.x;
    _initialOpacity = opacity;
  }

  void moveTowardsPlayer(Vector2 playerPos, double magnetRange, double dt) {
    _movingToPlayer = true;
    _playerPosition = playerPos;
  }

  bool get isCollected => _collected;
}
