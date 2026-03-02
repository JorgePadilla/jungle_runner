import 'package:flame_audio/flame_audio.dart';

/// Singleton audio manager for handling all game sounds and music
class AudioManager {
  // Singleton instance
  static final AudioManager instance = AudioManager._();
  AudioManager._();
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  
  // Audio file paths
  static const String _jumpSound = 'sfx/jump.wav';
  static const String _coinSound = 'sfx/coin.wav';
  static const String _deathSound = 'sfx/death.wav';
  static const String _powerUpSound = 'sfx/powerup.wav';
  static const String _buttonSound = 'sfx/button.wav';
  static const String _gameMusic = 'music/jungle_theme.mp3';
  static const String _menuMusic = 'music/jungle_groove.mp3';
  
  // Cache for preloaded sounds
  final Set<String> _preloadedSounds = {};
  bool _isInitialized = false;
  bool _isMusicPlaying = false;
  String? _currentTrack;

  /// Initialize audio manager and preload sounds
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Preload sound effects
      await _preloadSound(_jumpSound);
      await _preloadSound(_coinSound);
      await _preloadSound(_deathSound);
      await _preloadSound(_powerUpSound);
      await _preloadSound(_buttonSound);
      
      _isInitialized = true;
      print('AudioManager: Successfully initialized');
    } catch (e) {
      print('AudioManager: Failed to initialize some sounds: $e');
      _isInitialized = true; // Still mark as initialized to prevent infinite retries
    }
  }
  
  /// Preload a sound file
  Future<void> _preloadSound(String path) async {
    try {
      await FlameAudio.audioCache.load(path);
      _preloadedSounds.add(path);
      print('AudioManager: Preloaded $path');
    } catch (e) {
      print('AudioManager: Warning - Failed to preload $path: $e');
    }
  }
  
  /// Play sound effect with error handling
  void _playSound(String path) {
    if (!_soundEnabled || !_isInitialized) return;
    
    try {
      FlameAudio.play(path, volume: 0.7);
    } catch (e) {
      print('AudioManager: Warning - Failed to play $path: $e');
    }
  }

  /// Play jump sound
  void playJump() {
    _playSound(_jumpSound);
  }

  /// Play coin collection sound
  void playCoinCollect() {
    _playSound(_coinSound);
  }

  /// Play death sound
  void playDeath() {
    _playSound(_deathSound);
  }

  /// Play power-up collection sound
  void playPowerUp() {
    _playSound(_powerUpSound);
  }

  /// Play button tap sound
  void playButtonTap() {
    _playSound(_buttonSound);
  }

  /// Play a specific music track (stops current if different)
  Future<void> _playTrack(String track, {double volume = 0.3}) async {
    if (!_musicEnabled) return;
    
    // If already playing this track, don't restart
    if (_isMusicPlaying && _currentTrack == track) return;
    
    // Stop current track before switching
    if (_isMusicPlaying) {
      try {
        FlameAudio.bgm.stop();
      } catch (_) {}
    }
    
    try {
      await FlameAudio.bgm.play(track, volume: volume);
      _isMusicPlaying = true;
      _currentTrack = track;
      print('AudioManager: Playing $track');
    } catch (e) {
      print('AudioManager: Warning - Failed to play $track: $e');
    }
  }

  /// Start gameplay background music
  Future<void> startBackgroundMusic() async {
    await _playTrack(_gameMusic, volume: 0.3);
  }

  /// Start menu background music (lighter groove)
  Future<void> startMenuMusic() async {
    await _playTrack(_menuMusic, volume: 0.25);
  }

  /// Stop background music
  void stopBackgroundMusic() {
    try {
      FlameAudio.bgm.stop();
      _isMusicPlaying = false;
      _currentTrack = null;
      print('AudioManager: Stopped background music');
    } catch (e) {
      print('AudioManager: Warning - Failed to stop background music: $e');
    }
  }

  /// Pause background music
  void pauseBackgroundMusic() {
    try {
      FlameAudio.bgm.pause();
      print('AudioManager: Paused background music');
    } catch (e) {
      print('AudioManager: Warning - Failed to pause background music: $e');
    }
  }

  /// Resume background music
  void resumeBackgroundMusic() {
    if (_musicEnabled && _isMusicPlaying) {
      try {
        FlameAudio.bgm.resume();
        print('AudioManager: Resumed background music');
      } catch (e) {
        print('AudioManager: Warning - Failed to resume background music: $e');
      }
    }
  }

  /// Toggle sound effects on/off
  void toggleSound(bool enabled) {
    _soundEnabled = enabled;
    print('AudioManager: Sound effects ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Toggle music on/off
  void toggleMusic(bool enabled) {
    _musicEnabled = enabled;
    
    if (enabled && !_isMusicPlaying) {
      startBackgroundMusic();
    } else if (!enabled && _isMusicPlaying) {
      stopBackgroundMusic();
    }
    
    print('AudioManager: Music ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Set sound effects volume
  void setSoundVolume(double volume) {
    // Note: FlameAudio doesn't have a global volume control for SFX
    // Individual play calls can have volume set
    print('AudioManager: Sound volume set to ${(volume * 100).round()}%');
  }
  
  /// Set music volume
  void setMusicVolume(double volume) {
    try {
      if (_isMusicPlaying && _currentTrack != null) {
        // Stop and restart with new volume
        FlameAudio.bgm.stop();
        FlameAudio.bgm.play(_currentTrack!, volume: volume);
      }
      print('AudioManager: Music volume set to ${(volume * 100).round()}%');
    } catch (e) {
      print('AudioManager: Warning - Failed to set music volume: $e');
    }
  }

  /// Dispose audio resources
  void dispose() {
    try {
      stopBackgroundMusic();
      FlameAudio.audioCache.clearAll();
      _preloadedSounds.clear();
      _isInitialized = false;
      _isMusicPlaying = false;
      print('AudioManager: Disposed all resources');
    } catch (e) {
      print('AudioManager: Warning - Error during dispose: $e');
    }
  }
  
  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get isInitialized => _isInitialized;
  bool get isMusicPlaying => _isMusicPlaying;
}