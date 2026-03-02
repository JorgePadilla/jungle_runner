import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/play_games_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';
import '../game/config/game_config.dart';

/// Game over overlay with restart options and ad integration
class GameOverOverlay extends StatefulWidget {
  final int score;
  final int coinsEarned;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final VoidCallback onContinue;
  final VoidCallback onDoubleCoins;
  
  const GameOverOverlay({
    super.key,
    required this.score,
    required this.coinsEarned,
    required this.onRestart,
    required this.onMainMenu,
    required this.onContinue,
    required this.onDoubleCoins,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with TickerProviderStateMixin {
  late StorageService _storageService;
  late AnimationController _slideController;
  late AnimationController _scoreCountController;
  late AnimationController _confettiController;
  late AnimationController _starController;
  
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<int> _scoreCountAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _starScaleAnimation;
  
  int _highScore = 0;
  int _totalCoins = 0;
  int _displayScore = 0;
  bool _isNewRecord = false;
  bool _shouldShowInterstitial = false;
  final bool _canContinue = true;
  bool _isLoading = true;
  int _starRating = 0;
  List<ConfettiParticle> _confettiParticles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scoreCountController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _starController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.3, 1.0),
    ));
    
    _scoreCountAnimation = IntTween(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(
      parent: _scoreCountController,
      curve: Curves.easeOut,
    ));
    
    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));
    
    _starScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.elasticOut,
    ));
    
    // Start entrance animation
    _slideController.forward();
    
    // Animate score count after slide completes
    _slideController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scoreCountController.forward();
      }
    });
    
    // Listen to score animation for display updates
    _scoreCountAnimation.addListener(() {
      setState(() {
        _displayScore = _scoreCountAnimation.value;
      });
    });
  }
  
  Future<void> _initializeData() async {
    _storageService = await StorageService.getInstance();
    
    _highScore = await _storageService.getHighScore();
    _totalCoins = await _storageService.getTotalCoins();
    
    _isNewRecord = widget.score > _highScore;
    
    // Submit to Play Games leaderboard
    await PlayGamesService.instance.submitScore(widget.score);
    
    // Calculate star rating based on distance
    _starRating = _calculateStarRating(widget.score);
    
    // Check if we should show interstitial ad
    final deathCount = await _storageService.getDeathCount();
    _shouldShowInterstitial = deathCount % GameConfig.interstitialAdInterval == 0;
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    
    // Trigger confetti if new record
    if (_isNewRecord) {
      _generateConfettiParticles();
      _confettiController.forward();
    }
    
    // Animate stars after score animation
    _scoreCountController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _starController.forward();
      }
    });
    
    // Show interstitial ad if needed
    if (_shouldShowInterstitial && AdService.instance.isInterstitialReady) {
      _showInterstitialAd();
    }
  }
  
  void _showInterstitialAd() {
    AdService.instance.showInterstitialAd();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _scoreCountController.dispose();
    _confettiController.dispose();
    _starController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: const Center(
          child: CircularProgressIndicator(color: GameConstants.accent),
        ),
      );
    }
    
    return Stack(
      children: [
        // Main overlay
        AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                gradient: GameConstants.backgroundGradient,
              ),
              child: Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
                child: Center(
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(GameConstants.spacingLg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Game Over title
                            Text(
                              'GAME OVER',
                              style: GameConstants.displayLarge.copyWith(
                                fontSize: 42,
                                color: _isNewRecord ? GameConstants.coinGold : GameConstants.onSurface,
                              ),
                            ),
                            
                            if (_isNewRecord)
                              Padding(
                                padding: const EdgeInsets.only(top: GameConstants.spacingSm),
                                child: Text(
                                  '🎉 NEW RECORD! 🎉',
                                  style: GameConstants.headlineMedium.copyWith(
                                    color: GameConstants.coinGold,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: GameConstants.spacingXl),
                            
                            // Score card
                            _buildScoreCard(),
                            
                            const SizedBox(height: GameConstants.spacingXl),
                            
                            // Star rating
                            _buildStarRating(),
                            
                            const SizedBox(height: GameConstants.spacingXl),
                            
                            // Action buttons
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Confetti overlay
        if (_isNewRecord) _buildConfettiOverlay(),
      ],
    );
  }
  
  Widget _buildScoreCard() {
    return GlassCard(
      padding: const EdgeInsets.all(GameConstants.spacingXl),
      borderRadius: GameConstants.radiusXl,
      glowBorder: _isNewRecord,
      glowColor: GameConstants.coinGold,
      child: Column(
        children: [
          // Distance with animated counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance:',
                style: GameConstants.bodyLarge.copyWith(
                  color: GameConstants.onSurfaceDim,
                ),
              ),
              AnimatedBuilder(
                animation: _scoreCountAnimation,
                builder: (context, child) {
                  return Text(
                    '${_displayScore}m',
                    style: GameConstants.headlineMedium.copyWith(
                      color: GameConstants.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: GameConstants.spacingMd),
          
          // Best score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Best:',
                style: GameConstants.bodyLarge.copyWith(
                  color: GameConstants.onSurfaceDim,
                ),
              ),
              Text(
                '${_isNewRecord ? widget.score : _highScore}m',
                style: GameConstants.headlineMedium.copyWith(
                  color: _isNewRecord ? GameConstants.coinGold : GameConstants.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const Divider(
            color: GameConstants.shimmer,
            height: GameConstants.spacingXl,
          ),
          
          // Coins earned
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.circle, 
                    color: GameConstants.coinGold, 
                    size: 20,
                  ),
                  const SizedBox(width: GameConstants.spacingSm),
                  Text(
                    'Earned:',
                    style: GameConstants.bodyLarge.copyWith(
                      color: GameConstants.onSurfaceDim,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GameConstants.spacingMd,
                  vertical: GameConstants.spacingXs,
                ),
                decoration: BoxDecoration(
                  gradient: GameConstants.goldGradient,
                  borderRadius: BorderRadius.circular(GameConstants.radiusMd),
                ),
                child: Text(
                  '+${widget.coinsEarned}',
                  style: GameConstants.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: GameConstants.spacingMd),
          
          // Total coins
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.circle, 
                    color: GameConstants.coinGold, 
                    size: 20,
                  ),
                  const SizedBox(width: GameConstants.spacingSm),
                  Text(
                    'Total:',
                    style: GameConstants.bodyLarge.copyWith(
                      color: GameConstants.onSurfaceDim,
                    ),
                  ),
                ],
              ),
              Text(
                '${_totalCoins + widget.coinsEarned}',
                style: GameConstants.headlineMedium.copyWith(
                  color: GameConstants.coinGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: GameConstants.spacingLg),
          
          // Share button
          AnimatedButton(
            label: 'SHARE SCORE',
            icon: Icons.share,
            color: GameConstants.accent,
            onTap: _shareScore,
            width: double.infinity,
            height: 44,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Continue with ad (if available and rewarded ad ready)
        if (_canContinue && AdService.instance.isRewardedReady)
          Padding(
            padding: const EdgeInsets.only(bottom: GameConstants.spacingMd),
            child: AnimatedButton(
              label: 'CONTINUE',
              subtitle: 'Watch ad to continue from 50%',
              icon: Icons.play_arrow,
              gradient: GameConstants.accentGradient,
              onTap: _continueWithAd,
              width: 280,
              pulse: true,
            ),
          ),
        
        // Double coins with ad (if rewarded ad ready)
        if (widget.coinsEarned > 0 && AdService.instance.isRewardedReady)
          Padding(
            padding: const EdgeInsets.only(bottom: GameConstants.spacingMd),
            child: _buildAdButton(
              '2X COINS',
              'Watch ad for double coins',
              Icons.videocam,
              _doubleCoinsWithAd,
            ),
          ),
        
        // Play again
        Padding(
          padding: const EdgeInsets.only(bottom: GameConstants.spacingMd),
          child: AnimatedButton(
            label: 'PLAY AGAIN',
            icon: Icons.refresh,
            color: GameConstants.blue,
            onTap: widget.onRestart,
            width: 280,
          ),
        ),
        
        // Main menu
        AnimatedButton(
          label: 'MAIN MENU',
          icon: Icons.home,
          gradient: GameConstants.dangerGradient,
          onTap: widget.onMainMenu,
          width: 280,
        ),
      ],
    );
  }
  
  Widget _buildAdButton(String label, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GameConstants.radiusMd),
        gradient: LinearGradient(
          colors: [
            GameConstants.warning,
            GameConstants.warningDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: GameConstants.warning.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedButton(
        label: label,
        subtitle: subtitle,
        icon: icon,
        gradient: LinearGradient(
          colors: [
            GameConstants.warning,
            GameConstants.warningDark,
          ],
        ),
        onTap: onTap,
        width: 280,
      ),
    );
  }
  
  // Helper methods for new features
  int _calculateStarRating(int score) {
    if (score >= 1000) return 3;
    if (score >= 500) return 2;
    if (score >= 100) return 1;
    return 0;
  }
  
  void _generateConfettiParticles() {
    final random = Random();
    _confettiParticles = List.generate(50, (index) {
      return ConfettiParticle(
        x: random.nextDouble() * MediaQuery.of(context).size.width,
        y: -20 - (random.nextDouble() * 100),
        color: [
          GameConstants.coinGold,
          GameConstants.accent,
          GameConstants.success,
          GameConstants.dangerLight,
          GameConstants.warning,
        ][random.nextInt(5)],
        size: 4 + random.nextDouble() * 8,
        velocity: 2 + random.nextDouble() * 4,
        rotation: random.nextDouble() * 2 * pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
      );
    });
  }
  
  Widget _buildStarRating() {
    return AnimatedBuilder(
      animation: _starScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _starScaleAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isFilled = index < _starRating;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  size: 40,
                  color: isFilled ? GameConstants.coinGold : GameConstants.onSurfaceDim,
                ),
              );
            }),
          ),
        );
      },
    );
  }
  
  Widget _buildConfettiOverlay() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            particles: _confettiParticles,
            animationValue: _confettiAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  void _shareScore() async {
    final shareText = 'Just ran ${widget.score}m in Jungle Runner! '
        '${_starRating > 0 ? '⭐' * _starRating + ' ' : ''}'
        'Can you beat my score? 🏃‍♂️🌿';
    
    await Clipboard.setData(ClipboardData(text: shareText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Score copied to clipboard! 📋'),
            ],
          ),
          backgroundColor: GameConstants.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameConstants.radiusMd),
          ),
        ),
      );
    }
    
    HapticFeedback.lightImpact();
  }

  void _continueWithAd() {
    AdService.instance.showRewardedAd(
      onRewarded: (reward) {
        // User watched the ad, allow continue
        widget.onContinue();
      },
      onAdClosed: () {
        // Ad was closed, do nothing special
      },
    );
  }
  
  void _doubleCoinsWithAd() {
    AdService.instance.showRewardedAd(
      onRewarded: (reward) async {
        // Double the coins
        await _storageService.addCoins(widget.coinsEarned);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bonus +${widget.coinsEarned} coins! 🎉'),
              backgroundColor: GameConstants.gold,
            ),
          );
        }
        
        widget.onDoubleCoins();
      },
      onAdClosed: () {
        // Ad was closed, do nothing special
      },
    );
  }
}

/// Data class for confetti particles
class ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double velocity;
  double rotation;
  final double rotationSpeed;
  
  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// Custom painter for confetti effect
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animationValue;
  
  ConfettiPainter({
    required this.particles,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (final particle in particles) {
      // Update particle position based on animation
      final currentY = particle.y + (animationValue * size.height * 1.5);
      final currentRotation = particle.rotation + (animationValue * particle.rotationSpeed * 10);
      
      // Skip particles that are off screen
      if (currentY > size.height + 50) continue;
      
      // Set paint properties
      paint.color = particle.color.withValues(alpha: 1.0 - (animationValue * 0.3));
      
      // Save canvas state
      canvas.save();
      
      // Translate and rotate
      canvas.translate(particle.x, currentY);
      canvas.rotate(currentRotation);
      
      // Draw particle as a small rectangle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          Radius.circular(particle.size * 0.1),
        ),
        paint,
      );
      
      // Restore canvas state
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}