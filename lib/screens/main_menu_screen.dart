import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/mission_service.dart';
import '../services/play_games_service.dart';
import '../game/managers/audio_manager.dart';
import '../game/config/game_config.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';
import '../widgets/character_preview.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';
import 'daily_reward_screen.dart';
import 'missions_overlay.dart';
import 'dashboard_screen.dart';

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
  late AnimationController _characterController;
  late Animation<double> _titleAnimation;
  late Animation<Offset> _buttonAnimation;
  late Animation<double> _characterBounceAnimation;

  BannerAd? _bannerAd;
  int _totalCoins = 0;
  int _highScore = 0;
  bool _canClaimDailyReward = false;
  bool _hasMissionClaimable = false;
  bool _isLoading = true;
  bool _soundEnabled = true;
  String _selectedCharacter = 'default';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
    _loadBannerAd();
    // Force stop any lingering audio, then start menu music
    AudioManager.instance.stopBackgroundMusic();
    AudioManager.instance.startMenuMusic();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: GameConstants.durationEntrance,
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

    // Character bouncing animation
    _characterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _characterBounceAnimation = Tween<double>(
      begin: 0.0,
      end: -15.0,
    ).animate(CurvedAnimation(
      parent: _characterController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _characterController.repeat(reverse: true);
  }

  Future<void> _initializeServices() async {
    _storageService = await StorageService.getInstance();
    await _loadGameData();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // Auto-show daily reward dialog if available
      if (_canClaimDailyReward) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _openDailyRewardDialog();
        });
      }
    }
  }

  Future<void> _loadGameData() async {
    _totalCoins = await _storageService.getTotalCoins();
    _highScore = await _storageService.getHighScore();
    _canClaimDailyReward = await _storageService.canClaimDailyReward();
    _soundEnabled = await _storageService.getSoundEnabled();
    _selectedCharacter = await _storageService.getSelectedSkin();
    final missionService = await MissionService.getInstance();
    _hasMissionClaimable = await missionService.hasClaimableMission();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.instance.createBannerAd();
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _characterController.dispose();
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
          gradient: GameConstants.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with coins, high score, sound toggle, and settings
              _buildHeader(),

              // Main content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: GameConstants.accent))
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
    return Padding(
      padding: const EdgeInsets.all(GameConstants.spacingLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Coins and high score
          Row(
            children: [
              // Coins display
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: GameConstants.spacingMd,
                  vertical: GameConstants.spacingSm,
                ),
                borderRadius: GameConstants.radiusFull,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: GameConstants.coinGold,
                      size: 20,
                    ),
                    const SizedBox(width: GameConstants.spacingSm),
                    Text(
                      _totalCoins.toString(),
                      style: GameConstants.labelLarge.copyWith(
                        color: GameConstants.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: GameConstants.spacingSm),

              // High score display
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
                      Icons.emoji_events,
                      color: GameConstants.warning,
                      size: 20,
                    ),
                    const SizedBox(width: GameConstants.spacingSm),
                    Text(
                      _highScore.toString(),
                      style: GameConstants.labelLarge.copyWith(
                        color: GameConstants.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Right side: Sound toggle and settings
          Row(
            children: [
              // Sound toggle
              GestureDetector(
                onTap: _toggleSound,
                child: GlassCard(
                  padding: const EdgeInsets.all(GameConstants.spacingSm),
                  borderRadius: GameConstants.radiusFull,
                  child: Icon(
                    _soundEnabled ? Icons.volume_up : Icons.volume_off,
                    color: _soundEnabled ? GameConstants.accent : GameConstants.onSurfaceDim,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: GameConstants.spacingSm),

              // Settings gear
              GestureDetector(
                onTap: _navigateToSettings,
                child: GlassCard(
                  padding: const EdgeInsets.all(GameConstants.spacingSm),
                  borderRadius: GameConstants.radiusFull,
                  child: const Icon(
                    Icons.settings,
                    color: GameConstants.onSurface,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: GameConstants.spacingMd),

          // Game title
          AnimatedBuilder(
            animation: _titleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _titleAnimation.value,
                child: Column(
                  children: [
                    Text(
                      'JUNGLE RUNNER',
                      style: GameConstants.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: GameConstants.spacingSm),
                    Text(
                      'Run, Jump, Survive!',
                      style: GameConstants.bodyLarge.copyWith(
                        color: GameConstants.onSurfaceDim,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: GameConstants.spacingXl),

          // Character preview area
          _buildCharacterPreview(),

          const SizedBox(height: GameConstants.spacingXl),

          // Menu buttons
          SlideTransition(
            position: _buttonAnimation,
            child: Column(
              children: [
                // Play button
                AnimatedButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow,
                  gradient: GameConstants.accentGradient,
                  height: 56,
                  width: 250,
                  fontSize: 16,
                  onTap: _navigateToGame,
                ),

                const SizedBox(height: GameConstants.spacingLg),

                // Shop button
                AnimatedButton(
                  label: 'SHOP',
                  icon: Icons.store,
                  gradient: GameConstants.goldGradient,
                  height: 48,
                  width: 200,
                  fontSize: 14,
                  onTap: _navigateToShop,
                ),

                const SizedBox(height: GameConstants.spacingMd),

                // Missions button (with badge)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedButton(
                      label: 'MISSIONS',
                      icon: Icons.flag,
                      color: GameConstants.surfaceLight,
                      height: 48,
                      width: 200,
                      fontSize: 14,
                      onTap: _openMissionsDialog,
                    ),
                    if (_hasMissionClaimable)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: GameConstants.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: GameConstants.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: GameConstants.spacingMd),

                // Dashboard button
                AnimatedButton(
                  label: 'DASHBOARD',
                  icon: Icons.leaderboard,
                  color: GameConstants.surfaceLight,
                  height: 48,
                  width: 200,
                  fontSize: 14,
                  onTap: _navigateToDashboard,
                ),

                const SizedBox(height: GameConstants.spacingMd),

                // Leaderboard button
                AnimatedButton(
                  label: 'LEADERBOARD',
                  icon: Icons.emoji_events,
                  gradient: GameConstants.goldGradient,
                  height: 48,
                  width: 200,
                  fontSize: 14,
                  onTap: () async {
                    final error = await PlayGamesService.instance.showLeaderboard();
                    if (error != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: GameConstants.dangerLight,
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: GameConstants.spacingMd),

                // Daily reward button -- always visible
                AnimatedButton(
                  label: 'DAILY REWARD',
                  subtitle: _canClaimDailyReward ? 'Tap to claim!' : null,
                  icon: Icons.card_giftcard,
                  gradient: GameConstants.goldGradient,
                  height: 48,
                  width: 200,
                  fontSize: 13,
                  pulse: _canClaimDailyReward,
                  onTap: _openDailyRewardDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: GameConstants.spacingXl),
        ],
      ),
    );
  }

  Widget _buildCharacterPreview() {
    final skinName = GameConfig.skinNames[_selectedCharacter] ?? 'Ninja Frog';

    return GlassCard(
      padding: const EdgeInsets.all(GameConstants.spacingLg),
      margin: const EdgeInsets.symmetric(horizontal: GameConstants.spacingXl),
      child: Column(
        children: [
          Text(
            skinName,
            style: GameConstants.headlineMedium.copyWith(
              color: GameConstants.onSurface,
            ),
          ),
          const SizedBox(height: GameConstants.spacingMd),

          // Bouncing character sprite
          AnimatedBuilder(
            animation: _characterBounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _characterBounceAnimation.value),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: GameConstants.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: GameConstants.accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: CharacterPreview(
                      skinId: _selectedCharacter,
                      size: 64,
                      animationType: 'run',
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: GameConstants.spacingMd),

          GestureDetector(
            onTap: _navigateToShop,
            child: Text(
              'Tap to change character',
              style: GameConstants.bodyMedium.copyWith(
                color: GameConstants.accent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
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
      SlideLeftTransition(page: const GameScreen()),
    ).then((_) {
      // Resume menu music when returning from game
      AudioManager.instance.startMenuMusic();
      // Refresh data when returning from game
      _loadGameData().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  void _navigateToShop() {
    Navigator.of(context).push(
      SlideLeftTransition(page: const ShopScreen()),
    ).then((_) {
      // Refresh coins when returning from shop
      _loadGameData().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      SlideUpTransition(page: const SettingsScreen()),
    ).then((_) {
      // Refresh data when returning from settings
      _loadGameData().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  void _navigateToDashboard() {
    Navigator.of(context).push(
      SlideLeftTransition(page: const DashboardScreen()),
    );
  }

  void _toggleSound() async {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });

    await _storageService.setSoundEnabled(_soundEnabled);

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _soundEnabled ? 'Sound enabled' : 'Sound disabled',
            style: GameConstants.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: GameConstants.accent,
          duration: GameConstants.durationMedium,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(GameConstants.spacingLg),
        ),
      );
    }
  }

  Future<void> _openDailyRewardDialog() async {
    final claimed = await showDailyRewardDialog(context);
    if (claimed) {
      await _loadGameData();
      if (mounted) setState(() {});
    }
  }

  Future<void> _openMissionsDialog() async {
    final claimed = await showMissionsDialog(context);
    if (claimed) {
      await _loadGameData();
      if (mounted) setState(() {});
    }
  }
}
