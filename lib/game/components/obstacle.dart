import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../../utils/constants.dart';

enum ObstacleType { log, vine, gap }

/// Base obstacle class
abstract class Obstacle extends RectangleComponent {
  final ObstacleType type;
  double _gameSpeed = GameConfig.playerSpeed;
  
  Obstacle({required this.type, required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
    anchor = Anchor.bottomLeft;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move obstacle left
    position.x -= _gameSpeed * dt;
  }
  
  /// Update game speed
  void updateSpeed(double newSpeed) {
    _gameSpeed = newSpeed;
  }
  
  /// Check if obstacle is off screen
  bool get isOffScreen => position.x + size.x < -50;
  
  /// Get collision bounds for this obstacle
  Rect get bounds => Rect.fromLTWH(position.x, position.y, size.x, size.y);
  
  /// Check if obstacle requires jumping
  bool get requiresJump => type == ObstacleType.log || type == ObstacleType.gap;
  
  /// Check if obstacle requires sliding
  bool get requiresSlide => type == ObstacleType.vine;
}

/// Log obstacle that player must jump over
class LogObstacle extends Obstacle {
  LogObstacle({required Vector2 position}) 
      : super(
          type: ObstacleType.log, 
          position: position,
          size: Vector2(GameConfig.obstacleWidth, GameConfig.logHeight),
        );
  
  @override
  void render(Canvas canvas) {
    // Draw log
    final logPaint = Paint()..color = GameConstants.brown;
    final logRect = Rect.fromLTWH(0, 0, size.x, size.y);
    
    // Main log body
    canvas.drawRRect(
      RRect.fromRectAndRadius(logRect, const Radius.circular(8)),
      logPaint,
    );
    
    // Log texture lines
    final texturePaint = Paint()
      ..color = GameConstants.brown.withOpacity(0.6)
      ..strokeWidth = 2;
    
    // Horizontal lines for wood grain
    for (double y = 5; y < size.y; y += 8) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.x, y),
        texturePaint,
      );
    }
    
    // End caps (darker)
    final endCapPaint = Paint()..color = GameConstants.brown.withOpacity(0.7);
    canvas.drawCircle(Offset(0, size.y / 2), size.y / 2, endCapPaint);
    canvas.drawCircle(Offset(size.x, size.y / 2), size.y / 2, endCapPaint);
    
    // Tree rings on end caps
    final ringPaint = Paint()
      ..color = GameConstants.brown.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (double r = 5; r < size.y / 2; r += 4) {
      canvas.drawCircle(Offset(0, size.y / 2), r, ringPaint);
      canvas.drawCircle(Offset(size.x, size.y / 2), r, ringPaint);
    }
    
    // TODO: Replace with actual log sprite
  }
}

/// Vine obstacle that player must slide under
class VineObstacle extends Obstacle {
  VineObstacle({required Vector2 position}) 
      : super(
          type: ObstacleType.vine, 
          position: position,
          size: Vector2(GameConfig.obstacleWidth, GameConfig.vineHeight),
        );
  
  @override
  void render(Canvas canvas) {
    // Draw hanging vine
    final vinePaint = Paint()..color = GameConstants.darkGreen;
    final leafPaint = Paint()..color = GameConstants.primaryGreen;
    
    // Main vine stem
    final vineWidth = 8.0;
    final vineRect = Rect.fromLTWH(
      (size.x - vineWidth) / 2, 
      -200, // Extend upward off-screen
      vineWidth, 
      200 + size.y,
    );
    canvas.drawRect(vineRect, vinePaint);
    
    // Vine leaves along the stem
    for (double y = -180; y < size.y; y += 25) {
      // Left leaf
      canvas.drawOval(
        Rect.fromLTWH(vineRect.left - 15, y, 15, 20),
        leafPaint,
      );
      
      // Right leaf
      canvas.drawOval(
        Rect.fromLTWH(vineRect.right, y + 12, 15, 20),
        leafPaint,
      );
    }
    
    // Hanging vine bottom (thicker part)
    final bottomPaint = Paint()..color = GameConstants.brown;
    canvas.drawOval(
      Rect.fromLTWH(
        (size.x - 20) / 2,
        size.y - 30,
        20,
        30,
      ),
      bottomPaint,
    );
    
    // TODO: Replace with actual vine sprite
  }
}

/// Gap obstacle that player must jump over
class GapObstacle extends Obstacle {
  GapObstacle({required Vector2 position}) 
      : super(
          type: ObstacleType.gap, 
          position: position,
          size: Vector2(GameConfig.gapWidth, GameConfig.groundHeight),
        );
  
  @override
  void render(Canvas canvas) {
    // Draw gap (darker area to show depth)
    final gapPaint = Paint()..color = const Color(0xFF2F2F2F);
    
    // Main gap
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      gapPaint,
    );
    
    // Add some depth shading
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2F2F2F),
          const Color(0xFF1F1F1F),
          const Color(0xFF0F0F0F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      shadowPaint,
    );
    
    // Add some rocky edges
    final rockPaint = Paint()..color = GameConstants.brown;
    
    // Left edge rocks
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(-5, i * 20.0 + 10),
        5 + (i * 2),
        rockPaint,
      );
    }
    
    // Right edge rocks
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.x + 5, i * 25.0 + 15),
        4 + (i * 2),
        rockPaint,
      );
    }
    
    // TODO: Replace with actual gap/pit sprite
  }
}

/// Factory class to create obstacles
class ObstacleFactory {
  static Obstacle createObstacle(ObstacleType type, Vector2 position) {
    switch (type) {
      case ObstacleType.log:
        return LogObstacle(position: position);
      case ObstacleType.vine:
        return VineObstacle(position: position);
      case ObstacleType.gap:
        return GapObstacle(position: position);
    }
  }
  
  static ObstacleType getRandomObstacleType() {
    final types = ObstacleType.values;
    final random = DateTime.now().millisecondsSinceEpoch % types.length;
    return types[random];
  }
}