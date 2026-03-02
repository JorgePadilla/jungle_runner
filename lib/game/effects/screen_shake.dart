import 'package:flame/components.dart';
import 'dart:math' as math;

/// Screen shake effect component that can be mixed into a game
class ScreenShakeEffect extends Component {
  double _shakeTimer = 0;
  double _shakeDuration = 0;
  double _shakeIntensity = 0;
  final Vector2 _shakeOffset = Vector2.zero();
  
  bool get isShaking => _shakeTimer > 0;
  Vector2 get shakeOffset => _shakeOffset;

  /// Trigger screen shake with given intensity and duration
  /// intensity: maximum pixel offset (e.g., 5-10 pixels)
  /// duration: how long the shake lasts in seconds
  void triggerShake(double intensity, double duration) {
    _shakeIntensity = intensity;
    _shakeDuration = duration;
    _shakeTimer = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      
      if (_shakeTimer <= 0) {
        // Shake finished, reset offset
        _shakeOffset.setZero();
      } else {
        // Calculate shake intensity based on remaining time (linear decay)
        final normalizedTime = _shakeTimer / _shakeDuration;
        final currentIntensity = _shakeIntensity * normalizedTime;
        
        // Generate random offset
        _shakeOffset.setValues(
          (math.Random().nextDouble() - 0.5) * 2 * currentIntensity,
          (math.Random().nextDouble() - 0.5) * 2 * currentIntensity,
        );
      }
    }
  }
  
  /// Apply shake offset to the game camera
  void applyToCamera(CameraComponent camera) {
    if (isShaking) {
      camera.moveBy(_shakeOffset);
    }
  }
  
  /// Reset shake effect
  void reset() {
    _shakeTimer = 0;
    _shakeDuration = 0;
    _shakeIntensity = 0;
    _shakeOffset.setZero();
  }
}