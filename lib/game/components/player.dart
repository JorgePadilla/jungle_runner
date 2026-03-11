import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/game_config.dart';

enum PlayerState { running, jumping, doubleJumping, sliding }

class Player extends PositionComponent {
  final double groundY;

  PlayerState _state = PlayerState.running;
  double _velocityY = 0;
  bool _isOnGround = true;
  bool _hasDoubleJumped = false;
  bool _isShieldActive = false;
  bool _isMagnetActive = false;
  bool _isVisible = true;
  double _shieldTimer = 0;
  double _magnetTimer = 0;
  String _skinId = 'default';
  double _slideTimer = 0;

  /// Brief invincibility after state transitions to prevent one-frame deaths
  double _invincibilityTimer = 0;
  static const double _transitionInvincibility = 0.1; // 100ms (~6 frames)

  // Sprite components (nullable until onLoad completes)
  SpriteAnimationComponent? _runAnimation;
  SpriteComponent? _jumpSprite;
  SpriteComponent? _slideSprite;
  SpriteAnimationComponent? _idleAnimation;
  bool _spritesLoaded = false;

  // Current visible sprite
  Component? _currentSprite;

  // Hitbox shrink factor -- makes collisions more forgiving
  static const double _hitboxShrink = 0.25; // 25% smaller on each side

  Player({required this.groundY}) {
    size = Vector2(GameConfig.playerWidth, GameConfig.playerHeight);
    anchor = Anchor.topLeft;
    position = Vector2(100, groundY - GameConfig.playerHeight);
  }

  @override
  Future<void> onLoad() async {
    await _loadSprites();
    _setCurrentSprite();
  }

  Future<void> _loadSprites() async {
    // Load run animation (12 frames)
    final runImage = await Flame.images.load('player/run_$_skinId.png');
    final runAnimation = SpriteAnimation.fromFrameData(
      runImage,
      SpriteAnimationData.sequenced(
        amount: 12,
        stepTime: 0.05,
        textureSize: Vector2(32, 32),
      ),
    );
    _runAnimation = SpriteAnimationComponent(
      animation: runAnimation,
      size: size,
    );

    // Load idle animation (11 frames)
    final idleImage = await Flame.images.load('player/idle_$_skinId.png');
    final idleAnimation = SpriteAnimation.fromFrameData(
      idleImage,
      SpriteAnimationData.sequenced(
        amount: 11,
        stepTime: 0.05,
        textureSize: Vector2(32, 32),
      ),
    );
    _idleAnimation = SpriteAnimationComponent(
      animation: idleAnimation,
      size: size,
    );

    // Load single sprites
    final jumpSprite = await Sprite.load('player/jump_$_skinId.png');
    _jumpSprite = SpriteComponent(
      sprite: jumpSprite,
      size: size,
    );

    final slideSprite = await Sprite.load('player/slide_$_skinId.png');
    _slideSprite = SpriteComponent(
      sprite: slideSprite,
      size: size,
    );

    // Add all sprites as children but keep them invisible initially
    add(_runAnimation!);
    add(_jumpSprite!);
    add(_slideSprite!);
    add(_idleAnimation!);

    _jumpSprite!.opacity = 0;
    _slideSprite!.opacity = 0;
    _idleAnimation!.opacity = 0;

    _spritesLoaded = true;
  }

  void _setCurrentSprite() {
    if (!_spritesLoaded) return;

    // Hide all sprites
    _runAnimation?.opacity = 0;
    _jumpSprite?.opacity = 0;
    _slideSprite?.opacity = 0;
    _idleAnimation?.opacity = 0;

    if (!_isVisible) {
      _currentSprite = null;
      return;
    }

    // Show appropriate sprite based on state
    switch (_state) {
      case PlayerState.running:
        _runAnimation?.opacity = 1;
        _currentSprite = _runAnimation;
        break;
      case PlayerState.jumping:
      case PlayerState.doubleJumping:
        _jumpSprite?.opacity = 1;
        _currentSprite = _jumpSprite;
        break;
      case PlayerState.sliding:
        _slideSprite?.opacity = 1;
        _currentSprite = _slideSprite;
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updatePhysics(dt);
    _updatePowerUps(dt);
    if (_invincibilityTimer > 0) _invincibilityTimer -= dt;
  }

  void _updatePhysics(double dt) {
    // Apply gravity
    if (!_isOnGround) {
      _velocityY += GameConfig.gravity * dt;
    }

    // Update position
    position.y += _velocityY * dt;

    // Check ground collision
    final groundPosition = groundY - size.y;
    if (position.y >= groundPosition) {
      position.y = groundPosition;
      _velocityY = 0;
      _isOnGround = true;
      _hasDoubleJumped = false;

      if (_state == PlayerState.jumping || _state == PlayerState.doubleJumping) {
        setState(PlayerState.running);
      }
    } else {
      _isOnGround = false;
    }

    // Update sliding
    if (_state == PlayerState.sliding) {
      _slideTimer -= dt;
      size.y = GameConfig.slideHeight;
      position.y = groundY - size.y;
      if (_slideTimer <= 0) {
        setState(PlayerState.running);
      }
    } else {
      size.y = GameConfig.playerHeight;
    }
  }

  void _updatePowerUps(double dt) {
    if (_isShieldActive) {
      _shieldTimer -= dt;
      if (_shieldTimer <= 0) {
        _isShieldActive = false;
      }
    }

    if (_isMagnetActive) {
      _magnetTimer -= dt;
      if (_magnetTimer <= 0) {
        _isMagnetActive = false;
      }
    }
  }

  void jump() {
    if (_isOnGround) {
      _velocityY = -GameConfig.jumpVelocity;  // Negative = upward
      setState(PlayerState.jumping);
      _isOnGround = false;
    } else if (!_hasDoubleJumped && _state == PlayerState.jumping) {
      _velocityY = -GameConfig.doubleJumpVelocity;  // Negative = upward
      setState(PlayerState.doubleJumping);
      _hasDoubleJumped = true;
    }
  }

  void slide() {
    if (_isOnGround && _state == PlayerState.running) {
      _slideTimer = GameConfig.slideDuration;
      setState(PlayerState.sliding);
    }
  }

  void setVisible(bool visible) {
    _isVisible = visible;
    _setCurrentSprite();
  }

  void setState(PlayerState newState) {
    // Grant brief invincibility on state transitions to prevent
    // one-frame collision glitches (e.g. slide -> run size mismatch)
    if (_state != newState) {
      _invincibilityTimer = _transitionInvincibility;
    }
    _state = newState;
    _setCurrentSprite();
  }

  void activateShield(double duration) {
    _isShieldActive = true;
    _shieldTimer = duration;
  }

  void activateMagnet(double duration) {
    _isMagnetActive = true;
    _magnetTimer = duration;
  }

  bool get isShieldActive => _isShieldActive;
  bool get isMagnetActive => _isMagnetActive;

  /// True during brief invincibility after state transitions
  bool get isInvincible => _invincibilityTimer > 0;

  // Additional getters expected by the game
  bool get hasShield => _isShieldActive;
  bool get hasMagnet => _isMagnetActive;
  double get magnetRange => GameConfig.magnetRange;
  PlayerState get state => _state;

  /// Collision bounds -- shrunk by _hitboxShrink for forgiving gameplay.
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

  Future<void> setSkin(String skinId) async {
    _skinId = skinId;

    // If sprites haven't loaded yet, just store the ID -- onLoad will use it
    if (!_spritesLoaded) return;

    // Remove old sprites
    _runAnimation?.removeFromParent();
    _jumpSprite?.removeFromParent();
    _slideSprite?.removeFromParent();
    _idleAnimation?.removeFromParent();
    _spritesLoaded = false;

    // Reload sprites with new skin
    await _loadSprites();
    _setCurrentSprite();
  }

  @override
  void render(Canvas canvas) {
    if (!_isVisible) return;

    super.render(canvas);

    // Draw shield effect if active
    if (_isShieldActive) {
      _drawShield(canvas);
    }

    // Draw magnet effect if active
    if (_isMagnetActive) {
      _drawMagnet(canvas);
    }
  }

  void _drawShield(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = size / 2;
    final radius = math.max(size.x, size.y) / 2 + 5;

    canvas.drawCircle(center.toOffset(), radius, paint);
  }

  void _drawMagnet(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = size / 2;

    // Draw magnetic field lines
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final startRadius = size.x / 2 + 10;
      final endRadius = size.x / 2 + 20;

      final start = center + Vector2(
        math.cos(angle) * startRadius,
        math.sin(angle) * startRadius,
      );
      final end = center + Vector2(
        math.cos(angle) * endRadius,
        math.sin(angle) * endRadius,
      );

      canvas.drawLine(start.toOffset(), end.toOffset(), paint);
    }
  }
}
