import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/game_config.dart';
import '../../utils/constants.dart';

enum PlayerState { running, jumping, sliding, doubleJumping }

/// Player character component (monkey)
class Player extends RectangleComponent {
  PlayerState _state = PlayerState.running;
  double _velocityY = 0;
  double _groundY = 0;
  bool _canDoubleJump = false;
  double _slideTimer = 0;
  String _skinId = 'default';
  bool _hasShield = false;
  bool _hasMagnet = false;
  
  // Animation properties for visual feedback
  double _bounceOffset = 0;
  double _bounceTimer = 0;
  
  Player({required double groundY}) {
    _groundY = groundY;
    size = Vector2(GameConfig.playerWidth, GameConfig.playerHeight);
    position = Vector2(100, groundY - GameConfig.playerHeight);
    anchor = Anchor.bottomLeft;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update physics
    _updatePhysics(dt);
    
    // Update slide timer
    if (_state == PlayerState.sliding) {
      _slideTimer -= dt;
      if (_slideTimer <= 0) {
        setState(PlayerState.running);
      }
    }
    
    // Update visual bounce animation
    _bounceTimer += dt * 8; // Animation speed
    _bounceOffset = (sin(_bounceTimer) * 2).abs(); // Subtle bounce when running
  }
  
  @override
  void render(Canvas canvas) {
    // Draw player based on skin
    _drawPlayer(canvas);
    
    // Draw power-up effects
    if (_hasShield) {
      _drawShield(canvas);
    }
    if (_hasMagnet) {
      _drawMagnet(canvas);
    }
  }
  
  void _updatePhysics(double dt) {
    if (_state == PlayerState.jumping || _state == PlayerState.doubleJumping) {
      // Apply gravity
      _velocityY += GameConfig.gravity * dt;
      position.y += _velocityY * dt;
      
      // Check if landed
      if (position.y >= _groundY - size.y) {
        position.y = _groundY - size.y;
        _velocityY = 0;
        setState(PlayerState.running);
        _canDoubleJump = false;
      }
    } else if (_state == PlayerState.running) {
      // Ensure player stays on ground with subtle bounce
      position.y = _groundY - size.y + _bounceOffset;
    }
  }
  
  void _drawPlayer(Canvas canvas) {
    Paint playerPaint;
    
    // Choose color based on skin
    switch (_skinId) {
      case 'golden':
        playerPaint = Paint()..color = GameConstants.gold;
        break;
      case 'dark':
        playerPaint = Paint()..color = const Color(0xFF2F2F2F);
        break;
      case 'rainbow':
        // Create rainbow gradient
        playerPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.indigo,
              Colors.purple,
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
        break;
      case 'ninja':
        playerPaint = Paint()..color = const Color(0xFF1a1a1a);
        break;
      default:
        playerPaint = Paint()..color = GameConstants.brown;
        break;
    }
    
    // Main body
    final bodyRect = Rect.fromLTWH(
      0, 
      _state == PlayerState.sliding ? size.y - GameConfig.slideHeight : 0,
      size.x,
      _state == PlayerState.sliding ? GameConfig.slideHeight : size.y,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)),
      playerPaint,
    );
    
    // Simple face (eyes and mouth)
    final eyePaint = Paint()..color = GameConstants.black;
    final eyeSize = 4.0;
    
    // Eyes
    canvas.drawCircle(
      Offset(size.x * 0.3, bodyRect.top + 15),
      eyeSize,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.7, bodyRect.top + 15),
      eyeSize,
      eyePaint,
    );
    
    // Mouth (simple arc)
    final mouthPaint = Paint()
      ..color = GameConstants.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final mouthPath = Path();
    mouthPath.addArc(
      Rect.fromCenter(
        center: Offset(size.x * 0.5, bodyRect.top + 25),
        width: 15,
        height: 10,
      ),
      0,
      3.14159, // pi (half circle)
    );
    canvas.drawPath(mouthPath, mouthPaint);
    
    // TODO: Replace with actual monkey sprite
  }
  
  void _drawShield(Canvas canvas) {
    final shieldPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x * 0.8,
      shieldPaint,
    );
  }
  
  void _drawMagnet(Canvas canvas) {
    final magnetPaint = Paint()
      ..color = Colors.purple.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    // Draw magnetic field lines
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x * (0.6 + i * 0.3),
        Paint()
          ..color = Colors.purple.withOpacity(0.2 - i * 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
  
  /// Make the player jump
  bool jump() {
    if (_state == PlayerState.running) {
      setState(PlayerState.jumping);
      _velocityY = -GameConfig.jumpVelocity;
      _canDoubleJump = true;
      return true;
    } else if (_state == PlayerState.jumping && _canDoubleJump) {
      setState(PlayerState.doubleJumping);
      _velocityY = -GameConfig.doubleJumpVelocity;
      _canDoubleJump = false;
      return true;
    }
    return false;
  }
  
  /// Make the player slide
  void slide() {
    if (_state == PlayerState.running) {
      setState(PlayerState.sliding);
      _slideTimer = GameConfig.slideDuration;
    }
  }
  
  /// Set player state
  void setState(PlayerState newState) {
    _state = newState;
  }
  
  /// Get current state
  PlayerState get state => _state;
  
  /// Check if player is on ground
  bool get isOnGround => 
      _state == PlayerState.running || _state == PlayerState.sliding;
  
  /// Get player bounds for collision detection
  Rect get bounds {
    return Rect.fromLTWH(
      position.x,
      _state == PlayerState.sliding 
          ? position.y + (size.y - GameConfig.slideHeight)
          : position.y,
      size.x,
      _state == PlayerState.sliding ? GameConfig.slideHeight : size.y,
    );
  }
  
  /// Set player skin
  void setSkin(String skinId) {
    _skinId = skinId;
  }
  
  /// Activate shield power-up
  void activateShield(double duration) {
    _hasShield = true;
    
    // Remove shield after duration
    Future.delayed(Duration(milliseconds: (duration * 1000).round()), () {
      _hasShield = false;
    });
  }
  
  /// Activate magnet power-up
  void activateMagnet(double duration) {
    _hasMagnet = true;
    
    // Remove magnet after duration
    Future.delayed(Duration(milliseconds: (duration * 1000).round()), () {
      _hasMagnet = false;
    });
  }
  
  /// Check if player has shield
  bool get hasShield => _hasShield;
  
  /// Check if player has magnet
  bool get hasMagnet => _hasMagnet;
  
  /// Get magnet range
  double get magnetRange => GameConfig.magnetRange;
}