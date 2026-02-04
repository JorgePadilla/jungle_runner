import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../../utils/constants.dart';

enum PowerUpType { shield, magnet }

/// Base power-up component
abstract class PowerUp extends RectangleComponent {
  final PowerUpType type;
  double _gameSpeed = GameConfig.playerSpeed;
  double _animationTimer = 0;
  double _rotationAngle = 0;
  double _pulseScale = 1.0;
  bool _isCollected = false;
  
  PowerUp({required this.type, required Vector2 position}) {
    this.position = position;
    size = Vector2(GameConfig.powerUpSize, GameConfig.powerUpSize);
    anchor = Anchor.center;
    
    // Add some random offset for variety
    _animationTimer = (position.x % 100) / 20;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isCollected) return;
    
    // Move power-up left
    position.x -= _gameSpeed * dt;
    
    // Update animations
    _animationTimer += dt;
    _rotationAngle += dt * 2; // Slow rotation
    _pulseScale = 1.0 + sin(_animationTimer * 6) * 0.1; // Gentle pulsing
  }
  
  @override
  void render(Canvas canvas) {
    if (_isCollected) return;
    
    canvas.save();
    
    // Apply transformations
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(_pulseScale);
    canvas.rotate(_rotationAngle);
    canvas.translate(-size.x / 2, -size.y / 2);
    
    // Render specific power-up type
    renderPowerUp(canvas);
    
    // Add glow effect
    _drawGlowEffect(canvas);
    
    canvas.restore();
  }
  
  /// Override in subclasses to render specific power-up
  void renderPowerUp(Canvas canvas);
  
  void _drawGlowEffect(Canvas canvas) {
    final glowPaint = Paint()
      ..color = getGlowColor().withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 5,
      glowPaint,
    );
  }
  
  /// Get glow color for this power-up type
  Color getGlowColor();
  
  /// Update game speed
  void updateSpeed(double newSpeed) {
    _gameSpeed = newSpeed;
  }
  
  /// Check if power-up is off screen
  bool get isOffScreen => position.x + size.x < -50;
  
  /// Get collision bounds
  Rect get bounds => Rect.fromLTWH(
    position.x - size.x / 2,
    position.y - size.y / 2,
    size.x,
    size.y,
  );
  
  /// Collect the power-up
  void collect() {
    if (_isCollected) return;
    
    _isCollected = true;
    
    // Play collection animation
    _playCollectionAnimation();
  }
  
  void _playCollectionAnimation() {
    // Scale up and fade out animation
    Future.delayed(const Duration(milliseconds: 300), () {
      removeFromParent();
    });
  }
  
  /// Check if power-up is collected
  bool get isCollected => _isCollected;
  
  /// Get power-up duration
  double getDuration();
}

/// Shield power-up that makes player invincible
class ShieldPowerUp extends PowerUp {
  ShieldPowerUp({required Vector2 position}) 
      : super(type: PowerUpType.shield, position: position);
  
  @override
  void renderPowerUp(Canvas canvas) {
    // Draw shield shape
    final shieldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.lightBlue[300]!,
          Colors.blue[600]!,
          Colors.blue[800]!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    
    // Shield outline
    final shieldPath = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x * 0.4;
    
    // Create shield shape (rounded rectangle with pointed bottom)
    shieldPath.moveTo(centerX - radius, centerY - radius);
    shieldPath.lineTo(centerX + radius, centerY - radius);
    shieldPath.lineTo(centerX + radius, centerY);
    shieldPath.lineTo(centerX, centerY + radius);
    shieldPath.lineTo(centerX - radius, centerY);
    shieldPath.close();
    
    canvas.drawPath(shieldPath, shieldPaint);
    
    // Shield border
    final borderPaint = Paint()
      ..color = Colors.blue[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(shieldPath, borderPaint);
    
    // Shield emblem (cross)
    final emblemPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    
    // Vertical line
    canvas.drawLine(
      Offset(centerX, centerY - radius * 0.6),
      Offset(centerX, centerY + radius * 0.3),
      emblemPaint,
    );
    
    // Horizontal line
    canvas.drawLine(
      Offset(centerX - radius * 0.4, centerY - radius * 0.2),
      Offset(centerX + radius * 0.4, centerY - radius * 0.2),
      emblemPaint,
    );
    
    // TODO: Replace with actual shield sprite
  }
  
  @override
  Color getGlowColor() => Colors.blue;
  
  @override
  double getDuration() => GameConfig.shieldDuration;
}

/// Magnet power-up that attracts coins
class MagnetPowerUp extends PowerUp {
  MagnetPowerUp({required Vector2 position}) 
      : super(type: PowerUpType.magnet, position: position);
  
  @override
  void renderPowerUp(Canvas canvas) {
    // Draw magnet shape (horseshoe)
    final magnetPaint = Paint()..strokeWidth = 4;
    
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final magnetWidth = size.x * 0.6;
    final magnetHeight = size.y * 0.7;
    
    // North pole (red)
    magnetPaint.color = Colors.red[600]!;
    final northPath = Path();
    northPath.moveTo(centerX - magnetWidth / 2, centerY + magnetHeight / 2);
    northPath.lineTo(centerX - magnetWidth / 2, centerY - magnetHeight / 4);
    northPath.quadraticBezierTo(
      centerX - magnetWidth / 2, centerY - magnetHeight / 2,
      centerX - magnetWidth / 4, centerY - magnetHeight / 2,
    );
    canvas.drawPath(northPath, magnetPaint);
    
    // South pole (blue)
    magnetPaint.color = Colors.blue[600]!;
    final southPath = Path();
    southPath.moveTo(centerX + magnetWidth / 2, centerY + magnetHeight / 2);
    southPath.lineTo(centerX + magnetWidth / 2, centerY - magnetHeight / 4);
    southPath.quadraticBezierTo(
      centerX + magnetWidth / 2, centerY - magnetHeight / 2,
      centerX + magnetWidth / 4, centerY - magnetHeight / 2,
    );
    canvas.drawPath(southPath, magnetPaint);
    
    // Magnetic field lines (animated)
    final fieldPaint = Paint()
      ..color = Colors.purple.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final fieldAnimation = (_animationTimer * 3) % 1.0;
    
    // Draw curved field lines
    for (int i = 0; i < 3; i++) {
      final offsetY = (i - 1) * 8.0;
      final alpha = (1.0 - fieldAnimation + i * 0.3) % 1.0;
      
      fieldPaint.color = Colors.purple.withOpacity(alpha * 0.6);
      
      final fieldPath = Path();
      fieldPath.moveTo(centerX - magnetWidth / 4, centerY - magnetHeight / 2);
      fieldPath.quadraticBezierTo(
        centerX, centerY - magnetHeight / 2 - 15 - offsetY,
        centerX + magnetWidth / 4, centerY - magnetHeight / 2,
      );
      
      canvas.drawPath(fieldPath, fieldPaint);
    }
    
    // Magnet labels
    final textPaint = Paint()..color = Colors.white;
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 8,
      fontWeight: FontWeight.bold,
    );
    
    // N label
    final nPainter = TextPainter(
      text: TextSpan(text: 'N', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    nPainter.layout();
    nPainter.paint(canvas, Offset(
      centerX - magnetWidth / 2 - 5,
      centerY - magnetHeight / 4,
    ));
    
    // S label
    final sPainter = TextPainter(
      text: TextSpan(text: 'S', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    sPainter.layout();
    sPainter.paint(canvas, Offset(
      centerX + magnetWidth / 2 - 5,
      centerY - magnetHeight / 4,
    ));
    
    // TODO: Replace with actual magnet sprite
  }
  
  @override
  Color getGlowColor() => Colors.purple;
  
  @override
  double getDuration() => GameConfig.magnetDuration;
}

/// Factory class to create power-ups
class PowerUpFactory {
  static PowerUp createPowerUp(PowerUpType type, Vector2 position) {
    switch (type) {
      case PowerUpType.shield:
        return ShieldPowerUp(position: position);
      case PowerUpType.magnet:
        return MagnetPowerUp(position: position);
    }
  }
  
  static PowerUpType getRandomPowerUpType() {
    final types = PowerUpType.values;
    final random = DateTime.now().millisecondsSinceEpoch % types.length;
    return types[random];
  }
}