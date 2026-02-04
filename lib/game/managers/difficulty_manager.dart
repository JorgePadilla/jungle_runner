import 'dart:math';
import 'package:flame/components.dart';
import '../config/game_config.dart';

/// Manages difficulty progression as the player runs further
class DifficultyManager extends Component {
  double _currentSpeed = GameConfig.playerSpeed;
  double _currentObstacleInterval = GameConfig.obstacleSpawnInterval;
  double _distanceTraveled = 0;
  int _currentSpeedLevel = 0;
  int _currentObstacleLevel = 0;
  
  // Callbacks to notify game of changes
  Function(double)? onSpeedChanged;
  Function(double)? onObstacleIntervalChanged;
  
  DifficultyManager({
    this.onSpeedChanged,
    this.onObstacleIntervalChanged,
  });
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update distance traveled based on current speed
    _distanceTraveled += _currentSpeed * dt;
    
    // Check for speed increases
    _updateSpeed();
    
    // Check for obstacle frequency increases
    _updateObstacleFrequency();
  }
  
  void _updateSpeed() {
    // Increase speed every 100 meters
    final speedLevel = (_distanceTraveled / 100).floor();
    
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
    final obstacleLevel = (_distanceTraveled / 200).floor();
    
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
  
  /// Get current game speed
  double get currentSpeed => _currentSpeed;
  
  /// Get current obstacle spawn interval
  double get currentObstacleInterval => _currentObstacleInterval;
  
  /// Get distance traveled in meters
  double get distanceTraveled => _distanceTraveled;
  
  /// Get score based on distance
  int get score => (_distanceTraveled * GameConfig.scoreMultiplier).round();
  
  /// Get current speed level (for display)
  int get speedLevel => _currentSpeedLevel;
  
  /// Get current obstacle difficulty level (for display)
  int get obstacleLevel => _currentObstacleLevel;
  
  /// Reset difficulty for new game
  void reset() {
    _currentSpeed = GameConfig.playerSpeed;
    _currentObstacleInterval = GameConfig.obstacleSpawnInterval;
    _distanceTraveled = 0;
    _currentSpeedLevel = 0;
    _currentObstacleLevel = 0;
    
    // Notify listeners of reset values
    onSpeedChanged?.call(_currentSpeed);
    onObstacleIntervalChanged?.call(_currentObstacleInterval);
  }
  
  /// Set distance (useful for continue after ad)
  void setDistance(double distance) {
    _distanceTraveled = distance;
    
    // Recalculate levels based on new distance
    _currentSpeedLevel = (distance / 100).floor();
    _currentObstacleLevel = (distance / 200).floor();
    
    // Update speed and interval
    _updateSpeed();
    _updateObstacleFrequency();
  }
  
  /// Get difficulty description for UI
  String getDifficultyDescription() {
    if (_distanceTraveled < 100) {
      return 'Easy';
    } else if (_distanceTraveled < 300) {
      return 'Medium';
    } else if (_distanceTraveled < 600) {
      return 'Hard';
    } else if (_distanceTraveled < 1000) {
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
  
  /// Check if player has reached milestone
  bool checkMilestone(int meters) {
    final currentMilestone = (_distanceTraveled / meters).floor();
    final previousMilestone = ((_distanceTraveled - _currentSpeed / 60) / meters).floor();
    return currentMilestone > previousMilestone;
  }
  
  /// Get next milestone distance
  int getNextMilestone(int interval) {
    final currentMilestone = (_distanceTraveled / interval).floor();
    return (currentMilestone + 1) * interval;
  }
  
  /// Calculate predicted score for continue feature
  int getPredictedScore(double additionalDistance) {
    return ((distanceTraveled + additionalDistance) * GameConfig.scoreMultiplier).round();
  }
}