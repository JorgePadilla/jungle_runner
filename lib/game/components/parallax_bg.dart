import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import '../config/game_config.dart';

class ParallaxBackground extends Component {
  final List<BackgroundLayer> _layers = [];
  double _gameSpeed = 1.0;

  @override
  Future<void> onLoad() async {
    // Create 5 background layers with their respective speeds
    // Layer 0 (sky) stretches to fill; layers 1-4 render at proportional
    // height anchored to the bottom so jungle canopy sits at ground level.
    final layerConfigs = [
      {'image': 'background/sky.png', 'speed': GameConfig.parallaxSpeeds[0], 'isSky': true},
      {'image': 'background/mountains.png', 'speed': GameConfig.parallaxSpeeds[1], 'isSky': false},
      {'image': 'background/mid_trees.png', 'speed': GameConfig.parallaxSpeeds[2], 'isSky': false},
      {'image': 'background/near_trees.png', 'speed': GameConfig.parallaxSpeeds[3], 'isSky': false},
      {'image': 'background/vegetation.png', 'speed': GameConfig.parallaxSpeeds[4], 'isSky': false},
    ];

    for (final config in layerConfigs) {
      final layer = BackgroundLayer(
        imagePath: config['image'] as String,
        scrollSpeed: config['speed'] as double,
        isSky: config['isSky'] as bool,
      );
      await add(layer);
      _layers.add(layer);
    }
  }

  void updateSpeed(double speed) {
    _gameSpeed = speed;
    for (final layer in _layers) {
      layer.updateSpeed(speed);
    }
  }
}

class BackgroundLayer extends Component {
  final String imagePath;
  final double scrollSpeed;
  final bool isSky;
  
  late SpriteComponent _sprite1;
  late SpriteComponent _sprite2;
  double _currentSpeed = 1.0;

  /// Single scroll offset — both tile positions are derived from this
  /// so they can never drift apart.
  double _scrollOffset = 0;

  // Original aspect-ratio height for the jungle layers (384x216 source)
  static const double _sourceW = 384;
  static const double _sourceH = 216;

  // Extra width on each side to bleed past the viewport edge
  static const double _bleed = 8.0;

  BackgroundLayer({
    required this.imagePath,
    required this.scrollSpeed,
    this.isSky = false,
  });

  @override
  Future<void> onLoad() async {
    final loadedSprite = await Sprite.load(imagePath);

    // Paint with nearest-neighbor filtering to prevent edge blending artifacts
    final crisp = Paint()..filterQuality = FilterQuality.none;

    // Each tile = worldWidth + 2*bleed so it extends past both viewport edges
    final tileW = GameConfig.worldWidth + _bleed * 2;

    if (isSky) {
      _sprite1 = SpriteComponent(
        sprite: loadedSprite,
        size: Vector2(tileW, GameConfig.worldHeight.toDouble()),
        position: Vector2(-_bleed, 0),
        paint: crisp,
      );
      _sprite2 = SpriteComponent(
        sprite: loadedSprite,
        size: Vector2(tileW, GameConfig.worldHeight.toDouble()),
        position: Vector2(GameConfig.worldWidth - _bleed, 0),
        paint: crisp,
      );
    } else {
      final layerH = GameConfig.worldWidth * (_sourceH / _sourceW);
      final yPos = GameConfig.worldHeight - layerH;

      _sprite1 = SpriteComponent(
        sprite: loadedSprite,
        size: Vector2(tileW, layerH),
        position: Vector2(-_bleed, yPos),
        paint: crisp,
      );
      _sprite2 = SpriteComponent(
        sprite: loadedSprite,
        size: Vector2(tileW, layerH),
        position: Vector2(GameConfig.worldWidth - _bleed, yPos),
        paint: crisp,
      );
    }

    add(_sprite1);
    add(_sprite2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    final moveSpeed = scrollSpeed * _currentSpeed * GameConfig.baseScrollSpeed;

    // Advance single offset and wrap to prevent overflow
    _scrollOffset += moveSpeed * dt;
    _scrollOffset %= GameConfig.worldWidth;

    // Derive both positions from one value — zero drift
    // Offset by -bleed so tiles always extend past viewport edges
    final x1 = -_scrollOffset - _bleed;
    final x2 = GameConfig.worldWidth - _scrollOffset - _bleed;

    // Floor to whole pixels to eliminate sub-pixel seams
    _sprite1.position.x = x1.floorToDouble();
    _sprite2.position.x = x2.floorToDouble();
  }

  void updateSpeed(double speed) {
    _currentSpeed = speed;
  }
}