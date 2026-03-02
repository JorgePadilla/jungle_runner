import 'dart:math';
import 'package:flame/components.dart';
import '../config/game_config.dart';

/// Manages difficulty progression as the player runs further
class DifficultyManager extends Component {
  double _currentSpeed = GameConfig.playerSpeed;
  double _currentObstacleInterval = GameConfig.obstacleSpawnInterval;
  double _distanceTraveledPx = 0; // Internal distance in PIXELS
  int _currentSpeedLevel = 0;
  int _currentObstacleLevel = 0;
  
  // Callbacks to notify game of changes
  Function(double)? onSpeedChanged;
  Function(double)? onObstacleIntervalChanged;
  
  DifficultyManager({
    this.onSpeedChanged,
    this.onObstacleIntervalChanged,
  });
  
  /// Convert raw pixel distance to meters
  double get _distanceInMeters => _distanceTraveledPx / GameConfig.pixelsPerMeter;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update distance traveled in pixels based on current speed (px/s)
    _distanceTraveledPx += _currentSpeed * dt;
    
    // Check for speed increases (based on meters)
    _updateSpeed();
    
    // Check for obstacle frequency increases (based on meters)
    _updateObstacleFrequency();
  }
  
  void _updateSpeed() {
    // Increase speed every 100 meters
    final speedLevel = (_distanceInMeters / 100).floor();
    
    if (speedLevel > _currentSpeedLevel) {
      _currentSpeedLevel = speedLevel;
      
      // Calculate new speed
      final speedIncrease = _currentSpeedLevel * GameConfig.speedIncreaseRate;
      _currentSpeed = (GameConfig.playerSpeed + speedIncrease)
          .clamp(GameConfig.playerSpeed, GameConfig.maxSpeed);
      
      // Notify listeners
      onSpeedChanged?.call(_currentSpeed);
    }
  }
  
  void _updateObstacleFrequency() {
    // Increase obstacle frequency every 200 meters
    final obstacleLevel = (_distanceInMeters / 200).floor();
    
    if (obstacleLevel > _currentObstacleLevel) {
      _currentObstacleLevel = obstacleLevel;
      
      // Reduce spawn interval (more frequent obstacles)
      _currentObstacleInterval = (GameConfig.obstacleSpawnInterval * 
          pow(GameConfig.obstacleFrequencyIncrease, _currentObstacleLevel))
          .clamp(GameConfig.minObstacleInterval, GameConfig.obstacleSpawnInterval);
      
      // Notify listeners
      onObstacleIntervalChanged?.call(_currentObstacleInterval);
    }
  }
  
  /// Get current game speed (px/s)
  double get currentSpeed => _currentSpeed;
  
  /// Get current obstacle spawn interval
  double get currentObstacleInterval => _currentObstacleInterval;
  
  /// Get distance traveled in meters (converted from pixels)
  double get distanceTraveled => _distanceInMeters;
  
  /// Get score based on distance in meters
  int get score => (_distanceInMeters * GameConfig.scoreMultiplier).round();
  
  /// Get current speed level (for display)
  int get speedLevel => _currentSpeedLevel;
  
  /// Get current obstacle difficulty level (for display)
  int get obstacleLevel => _currentObstacleLevel;
  
  /// Reset difficulty for new game
  void reset() {
    _currentSpeed = GameConfig.playerSpeed;
    _currentObstacleInterval = GameConfig.obstacleSpawnInterval;
    _distanceTraveledPx = 0;
    _currentSpeedLevel = 0;
    _currentObstacleLevel = 0;
    
    // Notify listeners of reset values
    onSpeedChanged?.call(_currentSpeed);
    onObstacleIntervalChanged?.call(_currentObstacleInterval);
  }
  
  /// Set distance in meters (useful for continue after ad)
  void setDistance(double distanceInMeters) {
    _distanceTraveledPx = distanceInMeters * GameConfig.pixelsPerMeter;
    
    // Recalculate levels based on new distance (in meters)
    _currentSpeedLevel = (distanceInMeters / 100).floor();
    _currentObstacleLevel = (distanceInMeters / 200).floor();
    
    // Update speed and interval
    _updateSpeed();
    _updateObstacleFrequency();
  }
  
  /// Get difficulty description for UI (based on meters)
  String getDifficultyDescription() {
    final meters = _distanceInMeters;
    if (meters < 100) {
      return 'Easy';
    } else if (meters < 300) {
      return 'Medium';
    } else if (meters < 600) {
      return 'Hard';
    } else if (meters < 1000) {
      return 'Very Hard';
    } else {
      return 'Extreme';
    }
  }
  
  /// Get speed multiplier (for display)
  double get speedMultiplier => _currentSpeed / GameConfig.playerSpeed;
  
  /// Get obstacle frequency multiplier (for display)
  double get obstacleFrequencyMultiplier => 
      GameConfig.obstacleSpawnInterval / _currentObstacleInterval;
  
  /// Check if player has reached milestone (in meters)
  bool checkMilestone(int meters) {
    final currentMilestone = (_distanceInMeters / meters).floor();
    // Estimate previous frame's distance in meters
    final prevMeters = _distanceInMeters - (_currentSpeed / GameConfig.pixelsPerMeter) / 60;
    final previousMilestone = (prevMeters / meters).floor();
    return currentMilestone > previousMilestone;
  }
  
  /// Get next milestone distance in meters
  int getNextMilestone(int interval) {
    final currentMilestone = (_distanceInMeters / interval).floor();
    return (currentMilestone + 1) * interval;
  }
  
  /// Calculate predicted score for continue feature (additionalDistance in meters)
  int getPredictedScore(double additionalDistance) {
    return ((_distanceInMeters + additionalDistance) * GameConfig.scoreMultiplier).round();
  }
}