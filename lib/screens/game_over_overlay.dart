import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
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
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  int _highScore = 0;
  int _totalCoins = 0;
  bool _isNewRecord = false;
  bool _shouldShowInterstitial = false;
  bool _canContinue = true;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0),
    ));
    
    _animationController.forward();
  }
  
  Future<void> _initializeData() async {
    _storageService = await StorageService.getInstance();
    
    _highScore = await _storageService.getHighScore();
    _totalCoins = await _storageService.getTotalCoins();
    
    _isNewRecord = widget.score > _highScore;
    
    // Check if we should show interstitial ad
    final deathCount = await _storageService.getDeathCount();
    _shouldShowInterstitial = deathCount % GameConfig.interstitialAdInterval == 0;
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    
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
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black.withOpacity(0.8),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.9),
          child: Transform.translate(
            offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
            child: Center(
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Game Over title
                      Text(
                        'GAME OVER',
                        style: GameConstants.titleStyle.copyWith(
                          fontSize: 40,
                          color: _isNewRecord ? GameConstants.gold : Colors.white,
                        ),
                      ),
                      
                      if (_isNewRecord)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '🎉 NEW RECORD! 🎉',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: GameConstants.gold,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 40),
                      
                      // Score display
                      _buildScoreCard(),
                      
                      const SizedBox(height: 40),
                      
                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildScoreCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Current score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Distance:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              Text(
                '${widget.score} m',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // High score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Best:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_isNewRecord ? widget.score : _highScore} m',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isNewRecord ? GameConstants.gold : Colors.white,
                ),
              ),
            ],
          ),
          
          const Divider(color: Colors.white24, height: 30),
          
          // Coins earned
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.circle, color: GameConstants.gold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Earned:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '+${widget.coinsEarned}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GameConstants.gold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Total coins
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.circle, color: GameConstants.gold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '${_totalCoins + widget.coinsEarned}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GameConstants.gold,
                ),
              ),
            ],
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
            padding: const EdgeInsets.only(bottom: 15),
            child: _buildActionButton(
              'CONTINUE',
              Icons.play_arrow,
              GameConstants.primaryGreen,
              () => _continueWithAd(),
              subtitle: 'Watch ad to continue from 50%',
            ),
          ),
        
        // Double coins with ad (if rewarded ad ready)
        if (widget.coinsEarned > 0 && AdService.instance.isRewardedReady)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _buildActionButton(
              '2X COINS',
              Icons.video_call,
              GameConstants.gold,
              () => _doubleCoinsWithAd(),
              subtitle: 'Watch ad for double coins',
            ),
          ),
        
        // Play again
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: _buildActionButton(
            'PLAY AGAIN',
            Icons.refresh,
            GameConstants.blue,
            widget.onRestart,
          ),
        ),
        
        // Main menu
        _buildActionButton(
          'MAIN MENU',
          Icons.home,
          GameConstants.red,
          widget.onMainMenu,
        ),
      ],
    );
  }
  
  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    String? subtitle,
  }) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          SizedBox(
            height: GameConstants.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.white),
              label: Text(text, style: GameConstants.buttonStyle),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GameConstants.buttonRadius),
                ),
              ),
            ),
          ),
          
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
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