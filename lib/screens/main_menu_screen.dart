import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';

/// Main menu screen with play button, shop, and daily rewards
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late StorageService _storageService;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _titleAnimation;
  late Animation<Offset> _buttonAnimation;
  late Animation<double> _pulseAnimation;
  
  BannerAd? _bannerAd;
  int _totalCoins = 0;
  int _highScore = 0;
  bool _canClaimDailyReward = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
    _loadBannerAd();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _buttonAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _animationController.forward();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  Future<void> _initializeServices() async {
    _storageService = await StorageService.getInstance();
    await _loadGameData();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadGameData() async {
    _totalCoins = await _storageService.getTotalCoins();
    _highScore = await _storageService.getHighScore();
    _canClaimDailyReward = await _storageService.canClaimDailyReward();
  }
  
  void _loadBannerAd() {
    _bannerAd = AdService.instance.createBannerAd();
    _bannerAd!.load();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    GameConstants.screenWidth = MediaQuery.of(context).size.width;
    GameConstants.screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Sky blue
              Color(0xFF228B22), // Forest green
              Color(0xFF006400), // Dark green
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with coins and high score
              _buildHeader(),
              
              // Main content
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildMainContent(),
              ),
              
              // Banner ad
              _buildBannerAd(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(GameConstants.padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Coins display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: GameConstants.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  _totalCoins.toString(),
                  style: GameConstants.hudStyle,
                ),
              ],
            ),
          ),
          
          // High score display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Best: $_highScore',
                  style: GameConstants.hudStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        AnimatedBuilder(
          animation: _titleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _titleAnimation.value,
              child: Column(
                children: [
                  Text(
                    'JUNGLE',
                    style: GameConstants.titleStyle.copyWith(fontSize: 48),
                  ),
                  Text(
                    'RUNNER',
                    style: GameConstants.titleStyle.copyWith(fontSize: 48),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🐒 Tap to Jump • Swipe Down to Slide 🍌',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: 60),
        
        // Buttons
        SlideTransition(
          position: _buttonAnimation,
          child: Column(
            children: [
              // Play button
              ScaleTransition(
                scale: _pulseAnimation,
                child: _buildMenuButton(
                  'PLAY',
                  Icons.play_arrow,
                  GameConstants.primaryGreen,
                  () => _navigateToGame(),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Shop button
              _buildMenuButton(
                'SHOP',
                Icons.shopping_cart,
                GameConstants.purple,
                () => _navigateToShop(),
              ),
              
              const SizedBox(height: 20),
              
              // Daily reward button
              if (_canClaimDailyReward)
                _buildMenuButton(
                  'DAILY REWARD',
                  Icons.card_giftcard,
                  GameConstants.gold,
                  () => _claimDailyReward(),
                ),

              const SizedBox(height: 20),

              // Settings button
              _buildMenuButton(
                'SETTINGS',
                Icons.settings,
                Colors.blueGrey,
                () => _navigateToSettings(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMenuButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 250,
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
    );
  }
  
  Widget _buildBannerAd() {
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
  
  void _navigateToGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    ).then((_) {
      // Refresh data when returning from game
      _loadGameData().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }
  
  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    ).then((_) {
      // Refresh settings when returning from settings
      _loadGameData().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  void _navigateToShop() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ShopScreen(),
      ),
    ).then((_) {
      // Refresh coins when returning from shop
      _loadGameData().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }
  
  Future<void> _claimDailyReward() async {
    if (!_canClaimDailyReward) return;
    
    try {
      await _storageService.claimDailyReward();
      await _loadGameData();
      
      if (mounted) {
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily reward claimed! 🎉'),
            backgroundColor: GameConstants.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error claiming reward. Try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}