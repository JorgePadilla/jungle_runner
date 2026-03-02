import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../../utils/constants.dart';

/// 5-layer parallax scrolling background
class ParallaxBackground extends Component {
  late List<BackgroundLayer> _layers;
  double _gameSpeed = GameConfig.playerSpeed;
  
  ParallaxBackground() {
    _initializeLayers();
  }
  
  void _initializeLayers() {
    _layers = [
      // Layer 0: Sky (slowest)
      SkyLayer(speed: GameConfig.parallaxSpeeds[0]),
      // Layer 1: Far mountains
      MountainLayer(speed: GameConfig.parallaxSpeeds[1]),
      // Layer 2: Mid trees
      MidTreesLayer(speed: GameConfig.parallaxSpeeds[2]),
      // Layer 3: Near trees
      NearTreesLayer(speed: GameConfig.parallaxSpeeds[3]),
      // Layer 4: Close vegetation (fastest)
      CloseVegetationLayer(speed: GameConfig.parallaxSpeeds[4]),
    ];
    
    for (final layer in _layers) {
      add(layer);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update all layers with current game speed
    for (final layer in _layers) {
      layer.updateSpeed(_gameSpeed);
    }
  }
  
  /// Update game speed for all layers
  void updateSpeed(double newSpeed) {
    _gameSpeed = newSpeed;
  }
}

/// Base class for background layers
abstract class BackgroundLayer extends Component {
  final double baseSpeed;
  double _currentGameSpeed = GameConfig.playerSpeed;
  
  BackgroundLayer({required this.baseSpeed});
  
  void updateSpeed(double gameSpeed) {
    _currentGameSpeed = gameSpeed;
  }
  
  double get effectiveSpeed => _currentGameSpeed * baseSpeed;
}

/// Sky layer with gradient and clouds
class SkyLayer extends BackgroundLayer {
  late List<CloudComponent> _clouds;
  
  SkyLayer({required double speed}) : super(baseSpeed: speed) {
    _initializeClouds();
  }
  
  void _initializeClouds() {
    _clouds = [];
    
    // Create several clouds for variety
    for (int i = 0; i < 5; i++) {
      final cloud = CloudComponent(
        position: Vector2(
          i * GameConfig.worldWidth * 0.4,
          50 + (i * 30) % 80,
        ),
        size: Vector2(100 + (i * 20) % 60, 40 + (i * 10) % 30),
      );
      _clouds.add(cloud);
      add(cloud);
    }
  }
  
  @override
  void render(Canvas canvas) {
    // Draw sky gradient with more colors for quality
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF01579B), // Dark blue (Top)
        const Color(0xFF0288D1), // Medium blue
        const Color(0xFF29B6F6), // Sky blue
        const Color(0xFF81D4FA), // Light blue
        const Color(0xFFE1F5FE), // Very light blue (Horizon)
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
    
    final skyPaint = Paint()
      ..shader = skyGradient.createShader(
        Rect.fromLTWH(0, 0, GameConfig.worldWidth, GameConfig.worldHeight * 0.6),
      );
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, GameConfig.worldWidth * 2, GameConfig.worldHeight * 0.6),
      skyPaint,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Move clouds
    for (final cloud in _clouds) {
      cloud.position.x -= effectiveSpeed * dt * 0.3; // Clouds move slower
      
      // Reset cloud position when off screen
      if (cloud.position.x + cloud.size.x < 0) {
        cloud.position.x = GameConfig.worldWidth + 100;
      }
    }
  }
}

/// Cloud component
class CloudComponent extends RectangleComponent {
  CloudComponent({required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
    anchor = Anchor.topLeft;
  }
  
  @override
  void render(Canvas canvas) {
    // Enhanced puffy cloud rendering
    final mainPaint = Paint()..color = Colors.white.withOpacity(0.9);
    final shadowPaint = Paint()..color = Colors.blueGrey.withOpacity(0.2);
    
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Draw cloud shadow/bottom part
    canvas.drawCircle(Offset(centerX, centerY + 2), size.y * 0.35, shadowPaint);
    
    // Main body (multiple circles for puffiness)
    canvas.drawCircle(Offset(centerX, centerY), size.y * 0.4, mainPaint);
    canvas.drawCircle(Offset(centerX - size.x * 0.3, centerY + 2), size.y * 0.3, mainPaint);
    canvas.drawCircle(Offset(centerX + size.x * 0.3, centerY + 2), size.y * 0.3, mainPaint);
    canvas.drawCircle(Offset(centerX - size.x * 0.15, centerY - size.y * 0.2), size.y * 0.25, mainPaint);
    canvas.drawCircle(Offset(centerX + size.x * 0.15, centerY - size.y * 0.2), size.y * 0.25, mainPaint);
  }
}

/// Mountain layer in the far background
class MountainLayer extends BackgroundLayer {
  MountainLayer({required double speed}) : super(baseSpeed: speed);
  
  @override
  void render(Canvas canvas) {
    final mountainPaint = Paint()..color = const Color(0xFF708090).withOpacity(0.7);
    
    // Draw mountain silhouettes
    final mountainPath = Path();
    mountainPath.moveTo(0, GameConfig.worldHeight * 0.6);
    
    // Create mountain peaks
    for (double x = 0; x <= GameConfig.worldWidth * 2; x += 150) {
      final peakHeight = GameConfig.worldHeight * (0.3 + (x % 200) / 1000);
      mountainPath.lineTo(x, peakHeight);
      mountainPath.lineTo(x + 75, GameConfig.worldHeight * (0.4 + (x % 150) / 1500));
    }
    
    mountainPath.lineTo(GameConfig.worldWidth * 2, GameConfig.worldHeight * 0.6);
    mountainPath.close();
    
    canvas.drawPath(mountainPath, mountainPaint);
    
    // TODO: Replace with actual mountain sprite
  }
}

/// Mid-distance trees layer
class MidTreesLayer extends BackgroundLayer {
  MidTreesLayer({required double speed}) : super(baseSpeed: speed);
  
  @override
  void render(Canvas canvas) {
    final treePaint = Paint()..color = GameConstants.primaryGreen.withOpacity(0.6);
    final trunkPaint = Paint()..color = GameConstants.brown.withOpacity(0.6);
    
    // Draw forest silhouette
    for (double x = 0; x <= GameConfig.worldWidth * 2; x += 40) {
      final treeHeight = 60 + (x % 80);
      final treeTop = GameConfig.worldHeight * 0.65 - treeHeight;
      
      // Tree trunk
      canvas.drawRect(
        Rect.fromLTWH(x + 15, GameConfig.worldHeight * 0.65 - 20, 10, 20),
        trunkPaint,
      );
      
      // Tree crown (triangle)
      final treePath = Path();
      treePath.moveTo(x + 20, treeTop);
      treePath.lineTo(x, GameConfig.worldHeight * 0.65 - 20);
      treePath.lineTo(x + 40, GameConfig.worldHeight * 0.65 - 20);
      treePath.close();
      
      canvas.drawPath(treePath, treePaint);
    }
    
    // TODO: Replace with actual tree sprites
  }
}

/// Near trees layer
class NearTreesLayer extends BackgroundLayer {
  NearTreesLayer({required double speed}) : super(baseSpeed: speed);
  
  @override
  void render(Canvas canvas) {
    final treePaint = Paint()..color = GameConstants.primaryGreen.withOpacity(0.8);
    final trunkPaint = Paint()..color = GameConstants.brown.withOpacity(0.8);
    
    // Draw closer, larger trees
    for (double x = 0; x <= GameConfig.worldWidth * 2; x += 80) {
      final treeHeight = 100 + (x % 100);
      final treeTop = GameConfig.worldHeight * 0.7 - treeHeight;
      
      // Tree trunk
      canvas.drawRect(
        Rect.fromLTWH(x + 25, GameConfig.worldHeight * 0.7 - 30, 15, 30),
        trunkPaint,
      );
      
      // Tree crown (oval)
      canvas.drawOval(
        Rect.fromLTWH(x, treeTop, 65, treeHeight - 30),
        treePaint,
      );
    }
    
    // TODO: Replace with actual tree sprites
  }
}

/// Close vegetation layer (bushes, grass)
class CloseVegetationLayer extends BackgroundLayer {
  CloseVegetationLayer({required double speed}) : super(baseSpeed: speed);
  
  @override
  void render(Canvas canvas) {
    final bushPaint = Paint()..color = GameConstants.darkGreen;
    final grassPaint = Paint()..color = GameConstants.lightGreen;
    
    // Draw bushes and tall grass
    for (double x = 0; x <= GameConfig.worldWidth * 2; x += 30) {
      final bushHeight = 30 + (x % 40);
      final bushY = GameConfig.worldHeight - GameConfig.groundHeight - bushHeight;
      
      // Bush
      canvas.drawOval(
        Rect.fromLTWH(x, bushY, 25, bushHeight),
        bushPaint,
      );
      
      // Tall grass
      for (int i = 0; i < 3; i++) {
        final grassX = x + 30 + i * 5;
        final grassHeight = 15 + (grassX % 20);
        canvas.drawRect(
          Rect.fromLTWH(
            grassX, 
            GameConfig.worldHeight - GameConfig.groundHeight - grassHeight, 
            2, 
            grassHeight,
          ),
          grassPaint,
        );
      }
    }
    
    // TODO: Replace with actual vegetation sprites
  }
}