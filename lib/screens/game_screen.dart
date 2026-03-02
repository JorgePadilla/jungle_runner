import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';

import '../game/jungle_runner_game.dart';
import '../utils/constants.dart';
import '../models/mission.dart';
import '../services/storage_service.dart';
import '../services/mission_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';
import '../widgets/tutorial_overlay.dart';
import '../game/managers/audio_manager.dart';
import 'game_over_overlay.dart';

/// Game screen that wraps the GameWidget and handles UI overlays
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late JungleRunnerGame _game;
  int _currentScore = 0;
  int _currentCoins = 0;
  int _displayScore = 0;
  bool _isPaused = false;
  bool _isGameOver = false;
  bool _showHighScoreBroken = false;
  bool _showTutorial = false;
  int _resumeCountdown = 0;

  // Animation controllers
  late AnimationController _scoreController;
  late AnimationController _milestoneController;
  late AnimationController _coinFloatController;
  late AnimationController _pauseController;

  // Animations
  late Animation<double> _scoreAnimation;
  late Animation<double> _milestoneAnimation;
  late Animation<double> _pauseFadeAnimation;

  // UI state
  final List<FloatingCoin> _floatingCoins = [];
  String? _currentMilestone;
  int _lastMilestone = 0;
  DateTime? _lastCoinTime;

  // Raw pointer tracking for tap vs swipe
  Offset? _pointerDown;
  DateTime? _pointerDownTime;
  bool _gestureHandled = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkTutorial();
    _initializeGame();
  }

  void _setupAnimations() {
    _scoreController = AnimationController(
      duration: GameConstants.durationMedium,
      vsync: this,
    );

    _milestoneController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _coinFloatController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pauseController = AnimationController(
      duration: GameConstants.durationMedium,
      vsync: this,
    );

    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOut),
    );

    _milestoneAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _milestoneController, curve: Curves.elasticOut),
    );

    _pauseFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pauseController, curve: Curves.easeOut),
    );
  }

  void _checkTutorial() async {
    final storageService = await StorageService.getInstance();
    final hasSeenTutorial = await storageService.hasSeenTutorial();

    if (!hasSeenTutorial && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  @override
  void dispose() {
    // Stop game engine and audio when leaving the screen
    _game.pauseEngine();
    AudioManager.instance.stopBackgroundMusic();

    _scoreController.dispose();
    _milestoneController.dispose();
    _coinFloatController.dispose();
    _pauseController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    _game = JungleRunnerGame();

    // Set up game callbacks -- use addPostFrameCallback to avoid
    // calling setState during the build/layout phase
    _game.onScoreChanged = (score, coins) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final oldScore = _currentScore;
            final oldCoins = _currentCoins;

            setState(() {
              _currentScore = score;
              _currentCoins = coins;
            });

            // Animate score counter if score increased
            if (score > oldScore) {
              _animateScoreCounter(oldScore, score);
            }

            // Show floating coins if coins increased
            if (coins > oldCoins) {
              _showFloatingCoin();
            }

            // Check for distance milestones
            _checkMilestones(score);
          }
        });
      }
    };

    _game.onGameOverStats = (distance, coins, shields, magnets, slides, jumps) {
      _updateMissionProgress(distance, coins, shields, magnets, slides, jumps);
    };

    _game.onGameOver = () {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isGameOver = true;
            });
          }
        });
      }
    };

    _game.onPause = () {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isPaused = true;
            });
          }
        });
      }
    };

    _game.onHighScoreBroken = () {
      if (mounted) {
        setState(() {
          _showHighScoreBroken = true;
        });

        // Hide after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showHighScoreBroken = false;
            });
          }
        });
      }
    };
  }

  /// Update all mission progress at end of run.
  Future<void> _updateMissionProgress(
    int distance, int coins, int shields, int magnets, int slides, int jumps,
  ) async {
    final ms = await MissionService.getInstance();
    await ms.updateProgress(MissionType.runDistance, distance);
    await ms.updateProgress(MissionType.collectCoins, coins);
    await ms.updateProgress(MissionType.reachScore, distance);
    await ms.updateProgress(MissionType.useShield, shields);
    await ms.updateProgress(MissionType.useMagnet, magnets);
    await ms.updateProgress(MissionType.slideTimes, slides);
    await ms.updateProgress(MissionType.jumpTimes, jumps);
    await ms.updateProgress(MissionType.playGames, 1); // +1 game played
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          _pointerDown = event.position;
          _pointerDownTime = DateTime.now();
          _gestureHandled = false;
        },
        onPointerMove: (event) {
          // Detect swipe MID-GESTURE for instant slide response
          if (_gestureHandled || _pointerDown == null) return;
          final dy = event.position.dy - _pointerDown!.dy;
          if (dy > 15) {
            // Finger moved 15px+ downward -> slide NOW
            _game.handleSlide();
            _gestureHandled = true;
          }
        },
        onPointerUp: (event) {
          if (_gestureHandled || _pointerDown == null) {
            _pointerDown = null;
            _pointerDownTime = null;
            _gestureHandled = false;
            return;
          }
          // Not a swipe -> it's a tap -> jump
          _game.handleTap();
          _pointerDown = null;
          _pointerDownTime = null;
          _gestureHandled = false;
        },
        child: Stack(
          children: [
            // Game widget
            GameWidget.controlled(
              gameFactory: () => _game,
              backgroundBuilder: (context) => Container(color: Colors.black),
            ),

            // HUD overlay
            if (!_isGameOver && !_showTutorial) _buildHUD(),

            // High Score Broken Toast
            if (_showHighScoreBroken && !_isGameOver) _buildHighScoreToast(),

            // Floating coins
            ..._floatingCoins.map((coin) => _buildFloatingCoin(coin)),

            // Milestone overlay
            if (_currentMilestone != null) _buildMilestoneOverlay(),

            // Pause overlay
            if (_isPaused && !_isGameOver) _buildPauseOverlay(),

            // Game over overlay
            if (_isGameOver)
              GameOverOverlay(
                score: _currentScore,
                coinsEarned: _game.currentRunCoins,
                onRestart: _restartGame,
                onMainMenu: _backToMainMenu,
                onContinue: _continueWithAd,
                onDoubleCoins: _doubleCoinsWithAd,
              ),

            // Tutorial overlay
            if (_showTutorial)
              TutorialOverlay(
                onComplete: () {
                  setState(() {
                    _showTutorial = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighScoreToast() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: GameConstants.gold.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'NEW BEST!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    return IgnorePointer(
      // Let all touches pass through to the game Listener underneath
      // except for the pause button which has its own IgnorePointer(false)
      ignoring: true,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GameConstants.spacingMd),
          child: Column(
          children: [
            // Top row - Score and Pause
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Animated Score
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GameConstants.spacingMd,
                    vertical: GameConstants.spacingSm,
                  ),
                  borderRadius: GameConstants.radiusFull,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flag,
                        color: GameConstants.accent,
                        size: 18,
                      ),
                      const SizedBox(width: GameConstants.spacingSm),
                      AnimatedSwitcher(
                        duration: GameConstants.durationFast,
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(opacity: animation, child: child),
                          );
                        },
                        child: Text(
                          '${_displayScore}m',
                          key: ValueKey(_displayScore),
                          style: GameConstants.labelLarge.copyWith(
                            color: GameConstants.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pause Button -- re-enable touch on this widget only
                IgnorePointer(
                  ignoring: false,
                  child: GlassCard(
                    padding: const EdgeInsets.all(GameConstants.spacingSm),
                    borderRadius: GameConstants.radiusFull,
                    child: GestureDetector(
                      onTap: _pauseGame,
                      child: const Icon(
                        Icons.pause,
                        color: GameConstants.onSurface,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: GameConstants.spacingSm),

            // Second row - Coins and Power-ups
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Coins
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GameConstants.spacingMd,
                    vertical: GameConstants.spacingSm,
                  ),
                  borderRadius: GameConstants.radiusFull,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.circle,
                        color: GameConstants.coinGold,
                        size: 18,
                      ),
                      const SizedBox(width: GameConstants.spacingSm),
                      Text(
                        _currentCoins.toString(),
                        style: GameConstants.labelLarge.copyWith(
                          color: GameConstants.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Power-up indicators
                Row(
                  children: [
                    // Shield with timer
                    if (_game.hasShield) _buildPowerUpTimer(
                      Icons.shield,
                      _game.shieldTimeRemaining,
                      GameConstants.blue,
                      8.0, // Max duration for shield
                    ),

                    if (_game.hasShield && _game.hasMagnet)
                      const SizedBox(width: GameConstants.spacingSm),

                    // Magnet with timer
                    if (_game.hasMagnet) _buildPowerUpTimer(
                      Icons.attach_money,
                      _game.magnetTimeRemaining,
                      GameConstants.purple,
                      10.0, // Max duration for magnet
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPowerUpTimer(IconData icon, double timeRemaining, Color color, double maxTime) {
    final progress = (timeRemaining / maxTime).clamp(0.0, 1.0);

    return GlassCard(
      padding: const EdgeInsets.all(GameConstants.spacingSm),
      borderRadius: GameConstants.radiusFull,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress indicator
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: color.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            // Icon
            Icon(
              icon,
              color: GameConstants.onSurface,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return AnimatedBuilder(
      animation: _pauseFadeAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.85 * _pauseFadeAnimation.value),
          child: Opacity(
            opacity: _pauseFadeAnimation.value,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pause Title
                    Text(
                      'PAUSED',
                      style: GameConstants.displayLarge.copyWith(
                        fontSize: 48,
                        color: GameConstants.accent,
                      ),
                    ),

                    const SizedBox(height: GameConstants.spacingXl),

                    // Stats Card
                    GlassCard(
                      margin: const EdgeInsets.symmetric(horizontal: GameConstants.spacingXl),
                      padding: const EdgeInsets.all(GameConstants.spacingXl),
                      child: Column(
                        children: [
                          Text(
                            'RUN STATS',
                            style: GameConstants.headlineMedium.copyWith(
                              color: GameConstants.accent,
                            ),
                          ),

                          const SizedBox(height: GameConstants.spacingLg),

                          // Distance
                          _buildStatRow('Distance', '${_currentScore}m'),
                          const SizedBox(height: GameConstants.spacingMd),

                          // Coins this run
                          _buildStatRow('Coins', _game.currentRunCoins.toString()),
                          const SizedBox(height: GameConstants.spacingMd),

                          // Time (approximate)
                          _buildStatRow('Time', _formatTime(_game.distanceTraveled)),
                        ],
                      ),
                    ),

                    const SizedBox(height: GameConstants.spacingXl),

                    // Resume countdown or buttons
                    if (_resumeCountdown > 0)
                      _buildResumeCountdown()
                    else
                      _buildPauseButtons(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GameConstants.bodyLarge.copyWith(
            color: GameConstants.onSurfaceDim,
          ),
        ),
        Text(
          value,
          style: GameConstants.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: GameConstants.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildResumeCountdown() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: GameConstants.accentGradient,
            boxShadow: [
              BoxShadow(
                color: GameConstants.accent.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _resumeCountdown == 0 ? 'GO!' : _resumeCountdown.toString(),
              style: GameConstants.displayLarge.copyWith(
                fontSize: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: GameConstants.spacingLg),

        Text(
          'Get ready...',
          style: GameConstants.bodyLarge.copyWith(
            color: GameConstants.onSurfaceDim,
          ),
        ),
      ],
    );
  }

  Widget _buildPauseButtons() {
    return Column(
      children: [
        // Resume button
        AnimatedButton(
          label: 'RESUME',
          icon: Icons.play_arrow,
          gradient: GameConstants.accentGradient,
          onTap: _startResumeCountdown,
          width: 240,
          pulse: true,
        ),

        const SizedBox(height: GameConstants.spacingLg),

        // Main menu button
        AnimatedButton(
          label: 'MAIN MENU',
          icon: Icons.home,
          gradient: GameConstants.dangerGradient,
          onTap: _backToMainMenu,
          width: 240,
        ),
      ],
    );
  }

  // Helper methods for new UI features
  void _animateScoreCounter(int oldScore, int newScore) {
    _scoreController.reset();

    _scoreController.addListener(() {
      final animatedValue = oldScore + ((_scoreAnimation.value) * (newScore - oldScore));
      setState(() {
        _displayScore = animatedValue.round();
      });
    });

    _scoreController.forward();
  }

  void _showFloatingCoin() {
    final now = DateTime.now();
    if (_lastCoinTime != null && now.difference(_lastCoinTime!).inMilliseconds < 200) {
      return; // Don't spam floating coins
    }
    _lastCoinTime = now;

    final floatingCoin = FloatingCoin(
      id: DateTime.now().millisecondsSinceEpoch,
      startTime: now,
    );

    setState(() {
      _floatingCoins.add(floatingCoin);
    });

    // Remove after animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _floatingCoins.removeWhere((coin) => coin.id == floatingCoin.id);
        });
      }
    });
  }

  void _checkMilestones(int score) {
    final milestones = [100, 250, 500, 750, 1000, 1500, 2000, 3000, 5000];

    for (final milestone in milestones) {
      if (score >= milestone && _lastMilestone < milestone) {
        _lastMilestone = milestone;
        _showMilestone('${milestone}m!');
        HapticFeedback.mediumImpact();
        break;
      }
    }
  }

  void _showMilestone(String milestone) {
    setState(() {
      _currentMilestone = milestone;
    });

    _milestoneController.reset();
    _milestoneController.forward();

    // Hide milestone after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _currentMilestone = null;
        });
      }
    });
  }

  Widget _buildFloatingCoin(FloatingCoin coin) {
    final elapsed = DateTime.now().difference(coin.startTime).inMilliseconds / 1000.0;
    final progress = (elapsed / 1.0).clamp(0.0, 1.0);

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.3 - (progress * 50),
      right: 50,
      child: Opacity(
        opacity: 1.0 - progress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: GameConstants.coinGold,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: GameConstants.coinGold.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Text(
            '+1',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneOverlay() {
    return AnimatedBuilder(
      animation: _milestoneAnimation,
      builder: (context, child) {
        final v = _milestoneAnimation.value.clamp(0.0, 1.0);
        final scale = 0.5 + (v * 0.5);
        final opacity = v > 0.7
            ? (1.0 - ((v - 0.7) / 0.3)).clamp(0.0, 1.0)
            : v;

        return Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GameConstants.spacingXl,
                  vertical: GameConstants.spacingLg,
                ),
                decoration: BoxDecoration(
                  gradient: GameConstants.goldGradient,
                  borderRadius: BorderRadius.circular(GameConstants.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: GameConstants.coinGold.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  _currentMilestone!,
                  style: GameConstants.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(double distance) {
    // Rough time estimation based on distance (assuming ~50m/s average speed)
    final seconds = (distance / 50).round();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startResumeCountdown() {
    setState(() {
      _resumeCountdown = 3;
    });

    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resumeCountdown > 0) {
        setState(() {
          _resumeCountdown = 2;
        });
        HapticFeedback.mediumImpact();

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _resumeCountdown > 0) {
            setState(() {
              _resumeCountdown = 1;
            });
            HapticFeedback.mediumImpact();

            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && _resumeCountdown > 0) {
                setState(() {
                  _resumeCountdown = 0;
                });
                HapticFeedback.heavyImpact();

                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _resumeGame();
                  }
                });
              }
            });
          }
        });
      }
    });
  }

  void _pauseGame() {
    _game.pauseGame();
    _pauseController.forward();
  }

  void _resumeGame() {
    setState(() {
      _isPaused = false;
      _resumeCountdown = 0;
    });
    _pauseController.reverse();
    _game.resumeGame();
  }

  void _restartGame() {
    setState(() {
      _isGameOver = false;
      _isPaused = false;
      _currentScore = 0;
      _currentCoins = 0;
    });
    _game.resetGame();
  }

  void _backToMainMenu() {
    Navigator.of(context).pop();
  }

  void _continueWithAd() {
    // Continue from 50% of current distance
    final continueDistance = _game.distanceTraveled * 0.5;

    setState(() {
      _isGameOver = false;
      _isPaused = false;
    });

    _game.continueGame(continueDistance);
  }

  void _doubleCoinsWithAd() {
    // This would double the coins - implementation depends on ad service
    // For now, just restart the game
    _restartGame();
  }
}

/// Data class for floating coin animations
class FloatingCoin {
  final int id;
  final DateTime startTime;

  FloatingCoin({
    required this.id,
    required this.startTime,
  });
}
