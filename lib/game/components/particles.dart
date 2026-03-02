import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Base class for all particles
abstract class BaseParticle extends PositionComponent {
  double lifetime = 0;
  double maxLifetime;
  Vector2 velocity;
  Vector2 startPosition;
  bool shouldRemove = false;

  BaseParticle({
    required this.maxLifetime,
    required this.velocity,
    required this.startPosition,
  }) : lifetime = 0 {
    position = startPosition.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    if (lifetime >= maxLifetime) {
      shouldRemove = true;
      removeFromParent();
      return;
    }
    
    updateParticle(dt);
  }

  void updateParticle(double dt);
  void renderParticle(Canvas canvas);

  @override
  void render(Canvas canvas) {
    renderParticle(canvas);
  }

  double get normalizedLife => (lifetime / maxLifetime).clamp(0.0, 1.0);
}

/// Dust particles that appear behind the player when running
class RunDustParticle extends BaseParticle {
  static const Color baseColor = Color(0xFFD2B48C); // Tan/brown color
  final double particleSize;
  final Color particleColor;
  
  RunDustParticle({
    required Vector2 position,
  }) : 
    particleSize = 2 + math.Random().nextDouble() * 3, // 2-5 pixel size
    particleColor = Color.lerp(baseColor, const Color(0xFFA0522D), math.Random().nextDouble() * 0.3)!,
    super(
      maxLifetime: 0.3 + math.Random().nextDouble() * 0.2, // 0.3-0.5s
      velocity: Vector2(
        -30 - math.Random().nextDouble() * 20, // Left direction
        -10 - math.Random().nextDouble() * 15, // Slightly up
      ),
      startPosition: position,
    );

  @override
  void updateParticle(double dt) {
    // Apply velocity and gravity
    final pos = startPosition + velocity * lifetime;
    pos.y += 50 * lifetime * lifetime; // Gravity effect
    
    // Update position if we have a position component
    if (position != pos) {
      position.setFrom(pos);
    }
  }

  @override
  void renderParticle(Canvas canvas) {
    final alpha = (1.0 - normalizedLife).clamp(0.0, 1.0);
    final currentSize = particleSize * (1.0 - normalizedLife * 0.5); // Shrink as it fades
    
    final paint = Paint()
      ..color = particleColor.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    // Draw at (0,0) — Flame already translates canvas to component position
    canvas.drawCircle(
      Offset.zero,
      currentSize,
      paint,
    );
  }
}

/// Sparkle burst when collecting a coin
class CoinCollectParticle extends BaseParticle {
  static const List<Color> colors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFFA500), // Orange
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFFFacd), // Light gold
  ];
  
  final Color particleColor;
  final double particleSize;
  final double rotationSpeed;
  double currentRotation = 0;
  
  CoinCollectParticle({
    required Vector2 position,
    required Vector2 direction,
  }) : 
    particleColor = colors[math.Random().nextInt(colors.length)],
    particleSize = 3 + math.Random().nextDouble() * 2,
    rotationSpeed = 2 + math.Random().nextDouble() * 4,
    super(
      maxLifetime: 0.4,
      velocity: direction * (80 + math.Random().nextDouble() * 40),
      startPosition: position,
    );

  @override
  void updateParticle(double dt) {
    final pos = startPosition + velocity * lifetime;
    position.setFrom(pos);
    currentRotation += rotationSpeed * dt;
  }

  @override
  void renderParticle(Canvas canvas) {
    final alpha = (1.0 - normalizedLife).clamp(0.0, 1.0);
    final scale = normalizedLife < 0.3 ? 1.0 + normalizedLife : 1.3 - normalizedLife;
    final currentSize = particleSize * scale;
    
    final paint = Paint()
      ..color = particleColor.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(currentRotation);
    
    // Draw star shape
    _drawStar(canvas, paint, currentSize);
    
    canvas.restore();
  }
  
  void _drawStar(Canvas canvas, Paint paint, double radius) {
    const int points = 5;
    final path = Path();
    
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points;
      final currentRadius = (i % 2 == 0) ? radius : radius * 0.5;
      final x = currentRadius * math.cos(angle);
      final y = currentRadius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
}

/// Explosion effect on player death
class DeathParticle extends BaseParticle {
  static const List<Color> colors = [
    Color(0xFFFF0000), // Red
    Color(0xFFFF4500), // Orange red
    Color(0xFFFF6500), // Orange
    Color(0xFFFF8C00), // Dark orange
  ];
  
  final Color particleColor;
  final double particleSize;
  
  DeathParticle({
    required Vector2 position,
    required Vector2 direction,
  }) : 
    particleColor = colors[math.Random().nextInt(colors.length)],
    particleSize = 4 + math.Random().nextDouble() * 4,
    super(
      maxLifetime: 0.6,
      velocity: direction * (100 + math.Random().nextDouble() * 80),
      startPosition: position,
    );

  @override
  void updateParticle(double dt) {
    // Apply velocity and gravity
    final pos = startPosition + velocity * lifetime;
    pos.y += 150 * lifetime * lifetime; // Gravity
    position.setFrom(pos);
  }

  @override
  void renderParticle(Canvas canvas) {
    final alpha = (1.0 - normalizedLife).clamp(0.0, 1.0);
    final currentSize = particleSize * (1.0 - normalizedLife * 0.3);
    
    final paint = Paint()
      ..color = particleColor.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset.zero,
      currentSize,
      paint,
    );
  }
}

/// Power-up activation burst
class PowerUpParticle extends BaseParticle {
  final Color particleColor;
  final double particleSize;
  
  PowerUpParticle({
    required Vector2 position,
    required Vector2 direction,
    required bool isShield, // true for shield (blue), false for magnet (purple)
  }) : 
    particleColor = isShield ? const Color(0xFF0080FF) : const Color(0xFF8000FF),
    particleSize = 3 + math.Random().nextDouble() * 2,
    super(
      maxLifetime: 0.5,
      velocity: direction * 120,
      startPosition: position,
    );

  @override
  void updateParticle(double dt) {
    final pos = startPosition + velocity * lifetime;
    position.setFrom(pos);
  }

  @override
  void renderParticle(Canvas canvas) {
    final alpha = (1.0 - normalizedLife).clamp(0.0, 1.0);
    final currentSize = particleSize * (1.0 + normalizedLife);
    
    final paint = Paint()
      ..color = particleColor.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset.zero,
      currentSize,
      paint,
    );
  }
}

/// Particle spawner utility functions
class ParticleSpawner {
  /// Spawn run dust particles behind the player
  static List<RunDustParticle> spawnRunDust(Vector2 playerPosition) {
    final particles = <RunDustParticle>[];
    const particleCount = 3;
    
    for (int i = 0; i < particleCount + math.Random().nextInt(3); i++) {
      final offset = Vector2(
        -10 - math.Random().nextDouble() * 10, // Behind player
        math.Random().nextDouble() * 10 - 5,   // Random Y offset
      );
      particles.add(RunDustParticle(
        position: playerPosition + offset,
      ));
    }
    
    return particles;
  }
  
  /// Spawn coin collection particles
  static List<CoinCollectParticle> spawnCoinCollect(Vector2 coinPosition) {
    final particles = <CoinCollectParticle>[];
    const particleCount = 8;
    
    for (int i = 0; i < particleCount + math.Random().nextInt(5); i++) {
      final angle = (i / particleCount) * 2 * math.pi + math.Random().nextDouble() * 0.5;
      final direction = Vector2(math.cos(angle), math.sin(angle));
      
      particles.add(CoinCollectParticle(
        position: coinPosition.clone(),
        direction: direction,
      ));
    }
    
    return particles;
  }
  
  /// Spawn death explosion particles
  static List<DeathParticle> spawnDeathExplosion(Vector2 playerPosition) {
    final particles = <DeathParticle>[];
    const particleCount = 15;
    
    for (int i = 0; i < particleCount + math.Random().nextInt(6); i++) {
      final angle = math.Random().nextDouble() * 2 * math.pi;
      final direction = Vector2(math.cos(angle), math.sin(angle));
      
      particles.add(DeathParticle(
        position: playerPosition.clone(),
        direction: direction,
      ));
    }
    
    return particles;
  }
  
  /// Spawn power-up activation particles
  static List<PowerUpParticle> spawnPowerUpBurst(Vector2 powerUpPosition, bool isShield) {
    final particles = <PowerUpParticle>[];
    const particleCount = 10;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final direction = Vector2(math.cos(angle), math.sin(angle));
      
      particles.add(PowerUpParticle(
        position: powerUpPosition.clone(),
        direction: direction,
        isShield: isShield,
      ));
    }
    
    return particles;
  }
}