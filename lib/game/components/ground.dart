import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../../utils/constants.dart';

/// Ground component that scrolls infinitely
class Ground extends Component {
  late List<GroundTile> _tiles;
  double _gameSpeed = GameConfig.playerSpeed;
  
  Ground() {
    _initializeTiles();
  }
  
  void _initializeTiles() {
    _tiles = [];
    final tileWidth = GameConfig.worldWidth / 3; // 3 tiles for seamless scrolling
    
    // Create 4 tiles to ensure smooth scrolling
    for (int i = 0; i < 4; i++) {
      final tile = GroundTile(
        position: Vector2(i * tileWidth, GameConfig.worldHeight - GameConfig.groundHeight),
        size: Vector2(tileWidth, GameConfig.groundHeight),
      );
      _tiles.add(tile);
      add(tile);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move all tiles to the left
    for (final tile in _tiles) {
      tile.position.x -= _gameSpeed * dt;
      
      // If tile is completely off screen to the left, move it to the right
      if (tile.position.x + tile.size.x < 0) {
        final rightmostTile = _tiles.reduce((a, b) => 
            a.position.x > b.position.x ? a : b);
        tile.position.x = rightmostTile.position.x + rightmostTile.size.x;
      }
    }
  }
  
  /// Update game speed
  void updateSpeed(double newSpeed) {
    _gameSpeed = newSpeed;
  }
  
  /// Get ground Y position
  double get groundY => GameConfig.worldHeight - GameConfig.groundHeight;
}

/// Individual ground tile
class GroundTile extends RectangleComponent {
  GroundTile({required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
    anchor = Anchor.topLeft;
  }
  
  @override
  void render(Canvas canvas) {
    // Create gradient for ground
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        GameConstants.primaryGreen,
        GameConstants.darkGreen,
        GameConstants.brown.withOpacity(0.8),
        GameConstants.brown,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    
    final groundPaint = Paint()
      ..shader = groundGradient.createShader(
        Rect.fromLTWH(0, 0, size.x, size.y),
      );
    
    // Draw ground base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      groundPaint,
    );
    
    // Draw grass texture on top
    _drawGrassTexture(canvas);
    
    // Draw some rocks and details
    _drawGroundDetails(canvas);
    
    // TODO: Replace with actual ground sprite/tileset
  }
  
  void _drawGrassTexture(Canvas canvas) {
    final grassPaint = Paint()..color = GameConstants.lightGreen;
    
    // Draw grass blades
    for (double x = 0; x < size.x; x += 8) {
      final grassHeight = 8 + (x % 12); // Vary grass height
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 3, grassHeight),
        grassPaint,
      );
    }
  }
  
  void _drawGroundDetails(Canvas canvas) {
    final rockPaint = Paint()..color = const Color(0xFF696969);
    final random = position.x.hashCode; // Pseudo-random based on position
    
    // Draw some rocks
    for (int i = 0; i < 3; i++) {
      final rockX = (size.x * 0.2 * (i + 1) + (random % 50)) % size.x;
      final rockY = size.y * 0.4 + (random + i * 13) % 20;
      final rockSize = 6.0 + (random + i * 7) % 8;
      
      canvas.drawCircle(
        Offset(rockX, rockY),
        rockSize,
        rockPaint,
      );
    }
    
    // Draw some dirt patches
    final dirtPaint = Paint()..color = GameConstants.brown.withOpacity(0.6);
    for (int i = 0; i < 2; i++) {
      final dirtX = (size.x * 0.3 * (i + 1) + (random % 60)) % size.x;
      final dirtY = size.y * 0.3 + (random + i * 19) % 15;
      final dirtWidth = 20.0 + (random + i * 11) % 15;
      final dirtHeight = 8.0 + (random + i * 17) % 6;
      
      canvas.drawOval(
        Rect.fromLTWH(dirtX, dirtY, dirtWidth, dirtHeight),
        dirtPaint,
      );
    }
  }
}