import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/game_config.dart';

enum ObstacleType { log, vine, gap, rockHead, fire, saw }

abstract class Obstacle extends PositionComponent {
  double _gameSpeed = 1.0;
  
  // Hitbox shrink — makes near-misses feel fair
  static const double _hitboxShrink = 0.18; // 18% inset on each side
  
  ObstacleType get type;
  bool get requiresJump;
  bool get requiresSlide;

  /// Whether this obstacle participates in lethal collision.
  /// Override to false for cosmetic-only obstacles (e.g. gap).
  bool get isLethal => true;
  
  @override
  void update(double dt) {
    super.update(dt);
    position.x -= _gameSpeed * GameConfig.baseScrollSpeed * dt;
  }
  
  void updateSpeed(double speed) {
    _gameSpeed = speed;
  }
  
  bool get isOffScreen => position.x + size.x < 0;
  
  /// Collision bounds — shrunk for forgiving gameplay.
  Rect get bounds {
    final shrinkX = size.x * _hitboxShrink;
    final shrinkY = size.y * _hitboxShrink;
    return Rect.fromLTWH(
      position.x + shrinkX,
      position.y + shrinkY,
      size.x - shrinkX * 2,
      size.y - shrinkY * 2,
    );
  }
}

class LogObstacle extends Obstacle {
  late SpriteComponent _sprite;
  @override
  ObstacleType get type => ObstacleType.log;
  
  @override
  bool get requiresJump => true;
  
  @override
  bool get requiresSlide => false;
  
  LogObstacle() {
    size = Vector2(GameConfig.obstacleWidth.toDouble(), GameConfig.logHeight.toDouble());
    anchor = Anchor.topLeft;
  }
  
  @override
  Future<void> onLoad() async {
    final logSprite = await Sprite.load('obstacles/log.png');
    _sprite = SpriteComponent(
      sprite: logSprite,
      size: size,
    );
    add(_sprite);
  }
}

class VineObstacle extends Obstacle {
  late SpriteComponent _sprite;
  @override
  ObstacleType get type => ObstacleType.vine;
  
  @override
  bool get requiresJump => false;
  
  @override
  bool get requiresSlide => true;
  
  VineObstacle() {
    size = Vector2(GameConfig.obstacleWidth.toDouble(), GameConfig.vineHeight.toDouble());
    anchor = Anchor.topLeft;
  }
  
  @override
  Future<void> onLoad() async {
    final vineSprite = await Sprite.load('obstacles/vine.png');
    _sprite = SpriteComponent(
      sprite: vineSprite,
      size: size,
    );
    add(_sprite);
  }
}

class GapObstacle extends Obstacle {
  late SpriteComponent _sprite;
  @override
  ObstacleType get type => ObstacleType.gap;
  
  @override
  bool get requiresJump => true;
  
  @override
  bool get requiresSlide => false;
  
  /// Gap is cosmetic-only — no falling mechanic implemented yet.
  @override
  bool get isLethal => false;
  
  GapObstacle() {
    size = Vector2(GameConfig.gapWidth.toDouble(), GameConfig.groundHeight.toDouble());
    anchor = Anchor.topLeft;
  }
  
  @override
  Future<void> onLoad() async {
    final gapSprite = await Sprite.load('obstacles/gap.png');
    _sprite = SpriteComponent(
      sprite: gapSprite,
      size: size,
    );
    add(_sprite);
  }
}

/// Rock Head — ground obstacle (jump over), static angry stone face
class RockHeadObstacle extends Obstacle {
  late SpriteComponent _sprite;
  @override
  ObstacleType get type => ObstacleType.rockHead;
  @override
  bool get requiresJump => true;
  @override
  bool get requiresSlide => false;

  RockHeadObstacle() {
    size = Vector2(42, 42);
    anchor = Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    final s = await Sprite.load('obstacles/rock.png');
    _sprite = SpriteComponent(sprite: s, size: size);
    add(_sprite);
  }
}

/// Fire — ground obstacle (jump over), animated flickering flames
class FireObstacle extends Obstacle {
  late SpriteAnimationComponent _anim;
  @override
  ObstacleType get type => ObstacleType.fire;
  @override
  bool get requiresJump => true;
  @override
  bool get requiresSlide => false;

  FireObstacle() {
    // Fire sprite sheet: 48x32 = 3 frames of 16x32 each
    size = Vector2(16, 32);
    anchor = Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    final image = await Flame.images.load('obstacles/fire.png');
    final anim = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 3,
        stepTime: 0.12,
        textureSize: Vector2(16, 32),
      ),
    );
    _anim = SpriteAnimationComponent(animation: anim, size: size);
    add(_anim);
  }
}

/// Saw — aerial obstacle (slide under), animated spinning blade
class SawObstacle extends Obstacle {
  late SpriteAnimationComponent _anim;
  @override
  ObstacleType get type => ObstacleType.saw;
  @override
  bool get requiresJump => false;
  @override
  bool get requiresSlide => true;

  SawObstacle() {
    // Saw sprite sheet: 304x38 = 8 frames of 38x38 each
    size = Vector2(38, 38);
    anchor = Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    final image = await Flame.images.load('obstacles/saw.png');
    final anim = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 8,
        stepTime: 0.06,
        textureSize: Vector2(38, 38),
      ),
    );
    _anim = SpriteAnimationComponent(animation: anim, size: size);
    add(_anim);
  }
}

class ObstacleFactory {
  static final math.Random _random = math.Random();

  /// Weighted obstacle pool — jump and slide types mixed for variety.
  /// Gap removed (cosmetic only, no mechanic).
  static const List<ObstacleType> _weightedPool = [
    // Jump obstacles (60%)
    ObstacleType.log,
    ObstacleType.log,
    ObstacleType.rockHead,
    ObstacleType.fire,
    ObstacleType.fire,
    ObstacleType.rockHead,
    // Slide obstacles (40%)
    ObstacleType.vine,
    ObstacleType.vine,
    ObstacleType.saw,
    ObstacleType.saw,
  ];
  
  static ObstacleType getRandomObstacleType() {
    return _weightedPool[_random.nextInt(_weightedPool.length)];
  }
  
  static Obstacle createObstacle(ObstacleType type, Vector2 position) {
    Obstacle obstacle;
    switch (type) {
      case ObstacleType.log:
        obstacle = LogObstacle();
        obstacle.position = Vector2(position.x, position.y - obstacle.size.y);
        break;

      case ObstacleType.rockHead:
        obstacle = RockHeadObstacle();
        obstacle.position = Vector2(position.x, position.y - obstacle.size.y);
        break;

      case ObstacleType.fire:
        obstacle = FireObstacle();
        obstacle.position = Vector2(position.x, position.y - obstacle.size.y);
        break;
        
      case ObstacleType.vine:
        obstacle = VineObstacle();
        // Hangs at head height — standing player collides, sliding player clears.
        final vineBottomY = position.y - GameConfig.slideHeight - 5;
        obstacle.position = Vector2(position.x, vineBottomY - obstacle.size.y);
        break;

      case ObstacleType.saw:
        obstacle = SawObstacle();
        // Same height logic as vine — slide under it
        final sawBottomY = position.y - GameConfig.slideHeight - 5;
        obstacle.position = Vector2(position.x, sawBottomY - obstacle.size.y);
        break;
        
      case ObstacleType.gap:
        obstacle = GapObstacle();
        obstacle.position = Vector2(position.x, position.y);
        break;
    }
    return obstacle;
  }
  
  // Legacy method for backwards compatibility
  static Obstacle create(ObstacleType type, double groundY) {
    return createObstacle(type, Vector2(GameConfig.worldWidth.toDouble(), groundY));
  }
}