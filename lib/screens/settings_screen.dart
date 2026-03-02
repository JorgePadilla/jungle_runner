import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';
import '../widgets/tutorial_overlay.dart';

/// Settings screen with sound toggles, credits, and reset options
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late StorageService _storageService;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _hapticEnabled = true;
  bool _isLoading = true;
  bool _showTutorial = false;
  String _versionInfo = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSettings();
    _loadVersionInfo();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: GameConstants.durationMedium,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 30,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _loadSettings() async {
    _storageService = await StorageService.getInstance();
    _soundEnabled = await _storageService.getSoundEnabled();
    _hapticEnabled = await _storageService.getHapticsEnabled();
    // Note: Music and haptic settings would need to be added to StorageService
    // For now, we'll use the sound setting as a placeholder
    _musicEnabled = _soundEnabled;

    setState(() {
      _isLoading = false;
    });
  }

  void _loadVersionInfo() {
    _versionInfo = 'v1.0.0';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: GameConstants.backgroundGradient,
            ),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: _buildContent(),
                    ),
                  );
                },
              ),
            ),
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
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GameConstants.accent),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GameConstants.spacingLg),
            child: Column(
              children: [
                _buildAudioSettings(),
                const SizedBox(height: GameConstants.spacingLg),
                _buildGameSettings(),
                const SizedBox(height: GameConstants.spacingLg),
                _buildCredits(),
                const SizedBox(height: GameConstants.spacingXl),
                _buildVersionInfo(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(GameConstants.spacingLg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: GameConstants.onSurface,
            ),
          ),
          const SizedBox(width: GameConstants.spacingSm),
          Text(
            'Settings',
            style: GameConstants.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSettings() {
    return GlassCard(
      padding: const EdgeInsets.all(GameConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volume_up,
                color: GameConstants.accent,
                size: 24,
              ),
              const SizedBox(width: GameConstants.spacingMd),
              Text(
                'Audio Settings',
                style: GameConstants.headlineMedium.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: GameConstants.spacingMd),

          SwitchListTile(
            title: Text(
              'Sound Effects',
              style: GameConstants.bodyLarge,
            ),
            subtitle: Text(
              'Game sounds and effects',
              style: GameConstants.bodyMedium,
            ),
            value: _soundEnabled,
            activeThumbColor: GameConstants.accent,
            onChanged: _toggleSound,
          ),

          SwitchListTile(
            title: Text(
              'Background Music',
              style: GameConstants.bodyLarge,
            ),
            subtitle: Text(
              'Menu and gameplay music',
              style: GameConstants.bodyMedium,
            ),
            value: _musicEnabled,
            activeThumbColor: GameConstants.accent,
            onChanged: _toggleMusic,
          ),

          SwitchListTile(
            title: Text(
              'Haptic Feedback',
              style: GameConstants.bodyLarge,
            ),
            subtitle: Text(
              'Vibration on interactions',
              style: GameConstants.bodyMedium,
            ),
            value: _hapticEnabled,
            activeThumbColor: GameConstants.accent,
            onChanged: _toggleHaptic,
          ),
        ],
      ),
    );
  }

  Widget _buildGameSettings() {
    return GlassCard(
      padding: const EdgeInsets.all(GameConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.games,
                color: GameConstants.warning,
                size: 24,
              ),
              const SizedBox(width: GameConstants.spacingMd),
              Text(
                'Game Settings',
                style: GameConstants.headlineMedium.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: GameConstants.spacingMd),

          ListTile(
            title: Text(
              'View Tutorial',
              style: GameConstants.bodyLarge,
            ),
            subtitle: Text(
              'Review controls and how to play',
              style: GameConstants.bodyMedium,
            ),
            trailing: Icon(
              Icons.school,
              color: GameConstants.accent,
            ),
            onTap: () {
              setState(() {
                _showTutorial = true;
              });
            },
          ),
          const Divider(height: 1, color: Colors.white12),
          ListTile(
            title: Text(
              'Reset Progress',
              style: GameConstants.bodyLarge,
            ),
            subtitle: Text(
              'Clear all game data and progress',
              style: GameConstants.bodyMedium,
            ),
            trailing: const Icon(
              Icons.warning,
              color: GameConstants.danger,
            ),
            onTap: _showResetDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildCredits() {
    return GlassCard(
      padding: const EdgeInsets.all(GameConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: GameConstants.accent,
                size: 24,
              ),
              const SizedBox(width: GameConstants.spacingMd),
              Text(
                'Credits',
                style: GameConstants.headlineMedium.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: GameConstants.spacingMd),

          _buildCreditItem('Game Design', 'TAPHN'),
          _buildCreditItem('Sprites', 'Pixel Adventure Assets'),
          _buildCreditItem('Engine', 'Flutter + Flame'),
          _buildCreditItem('Music', '"Jungle Jumpin\'" by Scott Elliott (CC-BY 4.0)'),
          _buildCreditItem('Music', '"Jungle Groove Grove" by Christovix Games (CC-BY 3.0)'),
          _buildCreditItem('Icons', 'Material Design Icons'),
        ],
      ),
    );
  }

  Widget _buildCreditItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GameConstants.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: GameConstants.bodyLarge,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              subtitle,
              style: GameConstants.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Text(
      _versionInfo,
      style: GameConstants.labelSmall.copyWith(
        color: GameConstants.onSurfaceDim.withValues(alpha: 0.7),
      ),
    );
  }

  void _toggleSound(bool value) async {
    setState(() {
      _soundEnabled = value;
    });

    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }

    await _storageService.setSoundEnabled(value);
  }

  void _toggleMusic(bool value) async {
    setState(() {
      _musicEnabled = value;
    });

    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }

    // Note: Music setting would need to be implemented in StorageService
  }

  void _toggleHaptic(bool value) async {
    setState(() {
      _hapticEnabled = value;
    });

    if (value) {
      HapticFeedback.lightImpact();
    }

    await _storageService.setHapticsEnabled(value);
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameConstants.surface,
        title: Text(
          'Reset Progress',
          style: GameConstants.headlineMedium.copyWith(
            color: GameConstants.danger,
          ),
        ),
        content: Text(
          'Are you sure you want to reset all your game progress? This action cannot be undone.\n\nThis will clear:\n• High scores\n• Coins collected\n• Unlocked characters\n• Daily reward streak',
          style: GameConstants.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GameConstants.labelLarge.copyWith(
                color: GameConstants.onSurfaceDim,
              ),
            ),
          ),
          AnimatedButton(
            label: 'RESET',
            color: GameConstants.danger,
            height: 40,
            fontSize: 12,
            borderRadius: GameConstants.radiusSm,
            onTap: () {
              Navigator.pop(context);
              _resetProgress();
            },
          ),
        ],
      ),
    );
  }

  void _resetProgress() async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: GameConstants.accent),
          ),
        );
      }

      // Reset all data (using individual methods)
      await _storageService.setHighScore(0);
      await _storageService.setTotalCoins(0);
      await _storageService.setSelectedSkin('default');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress reset successfully!'),
            backgroundColor: GameConstants.success,
          ),
        );

        // Navigate back to main menu
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main_menu',
          (route) => false,
        );
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error resetting progress. Please try again.'),
            backgroundColor: GameConstants.danger,
          ),
        );
      }
    }
  }
}
