import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../../utils/constants.dart';

/// Coin collectible component
class Coin extends RectangleComponent {
  double _gameSpeed = GameConfig.playerSpeed;
  double _rotationAngle = 0;
  double _bounceOffset = 0;
  double _animationTimer = 0;
  bool _isCollected = false;
  double _collectTimer = 0;
  final int value = GameConfig.coinValue;
  
  Coin({required Vector2 position}) {
    this.position = position;
    size = Vector2(GameConfig.coinSize, GameConfig.coinSize);
    anchor = Anchor.center;
    
    // Add some random offset to animation timer for variety
    _animationTimer = (position.x % 100) / 10;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isCollected) {
      _collectTimer += dt;
      // Fly up and fade out
      position.y -= 200 * dt;
      scale = Vector2.all(1.0 + _collectTimer * 2);
      if (_collectTimer >= 0.3) {
        removeFromParent();
      }
      return;
    }
    
    // Move coin left
    position.x -= _gameSpeed * dt;
    
    // Update animations
    _animationTimer += dt;
    _rotationAngle += dt * 5; // Rotation speed
    _bounceOffset = sin(_animationTimer * 4) * 3; // Gentle bounce
    
    // Apply bounce offset
    position.y += _bounceOffset * dt * 10;
  }
  
  @override
  void render(Canvas canvas) {
    canvas.save();
    
    if (_isCollected) {
      // Fade out effect
      final opacity = (1.0 - (_collectTimer / 0.3)).clamp(0.0, 1.0);
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }

    // Apply rotation for spinning effect
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_rotationAngle);
    canvas.translate(-size.x / 2, -size.y / 2);
    
    // Draw coin with gradient
    final coinGradient = RadialGradient(
      center: Alignment.topLeft,
      radius: 1.0,
      colors: [
        const Color(0xFFFFD700), // Bright gold
        const Color(0xFFDAA520), // Golden rod
        const Color(0xFFB8860B), // Dark golden rod
      ],
      stops: const [0.0, 0.7, 1.0],
    );
    
    final coinPaint = Paint()
      ..shader = coinGradient.createShader(
        Rect.fromLTWH(0, 0, size.x, size.y),
      );
    
    // Main coin body (circle)
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      coinPaint,
    );
    
    // Inner circle for depth
    final innerPaint = Paint()
      ..color = const Color(0xFFFFE55C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 - 3,
      innerPaint,
    );
    
    // Draw coin symbol (dollar sign or custom symbol)
    _drawCoinSymbol(canvas);
    
    // Add shine effect
    _drawShineEffect(canvas);
    
    if (_isCollected) {
      canvas.restore();
    }

    canvas.restore();
    
    // TODO: Replace with actual coin sprite
  }
  
  void _drawCoinSymbol(Canvas canvas) {
    final symbolPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    
    // Draw a simple "C" for coin
    final symbolPath = Path();
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: size.x * 0.6,
      height: size.y * 0.6,
    );
    
    symbolPath.addArc(rect, pi / 2, pi); // Half circle
    canvas.drawPath(symbolPath, symbolPaint);
    
    // Add horizontal lines for currency symbol
    canvas.drawLine(
      Offset(centerX - 2, centerY - size.y * 0.2),
      Offset(centerX + 2, centerY - size.y * 0.2),
      symbolPaint,
    );
    canvas.drawLine(
      Offset(centerX - 2, centerY + size.y * 0.2),
      Offset(centerX + 2, centerY + size.y * 0.2),
      symbolPaint,
    );
  }
  
  void _drawShineEffect(Canvas canvas) {
    // Animated shine effect
    final shineProgress = (_animationTimer * 2) % 3.0;
    if (shineProgress < 1.0) {
      final shinePaint = Paint()
        ..color = Colors.white.withOpacity(0.6 * (1.0 - shineProgress))
        ..strokeWidth = 2;
      
      final shineOffset = shineProgress * size.x;
      canvas.drawLine(
        Offset(shineOffset - size.x * 0.3, 0),
        Offset(shineOffset + size.x * 0.3, size.y),
        shinePaint,
      );
    }
  }
  
  /// Update game speed
  void updateSpeed(double newSpeed) {
    _gameSpeed = newSpeed;
  }
  
  /// Check if coin is off screen
  bool get isOffScreen => position.x + size.x < -50;
  
  /// Get collision bounds
  Rect get bounds => Rect.fromLTWH(
    position.x - size.x / 2,
    position.y - size.y / 2,
    size.x,
    size.y,
  );
  
  /// Collect the coin (plays animation and marks as collected)
  void collect() {
    if (_isCollected) return;
    _isCollected = true;
    _collectTimer = 0;
  }
  
  /// Check if coin is collected
  bool get isCollected => _isCollected;
  
  /// Get coin value
  int get coinValue => value;
  
  /// Move coin towards player (for magnet effect)
  void moveTowardsPlayer(Vector2 playerPosition, double magnetStrength, double dt) {
    if (_isCollected) return;
    
    final direction = playerPosition - position;
    final distance = direction.length;
    
    if (distance > 0) {
      direction.normalize();
      final moveSpeed = magnetStrength * dt * (100 / max(distance, 10));
      position += direction * moveSpeed;
    }
  }
}