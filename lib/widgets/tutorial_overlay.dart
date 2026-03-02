import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import 'glass_card.dart';
import 'animated_button.dart';

/// Tutorial overlay shown on first game launch to teach basic controls
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  
  const TutorialOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _gestureController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _gestureAnimation;
  
  int _currentPage = 0;
  final int _totalPages = 3;
  
  final List<TutorialPage> _pages = [
    TutorialPage(
      title: 'TAP TO JUMP',
      description: 'Tap the screen to make your character jump over obstacles',
      icon: Icons.touch_app,
      gesture: 'tap',
    ),
    TutorialPage(
      title: 'SWIPE DOWN TO SLIDE',
      description: 'Swipe down to slide under low obstacles and barriers',
      icon: Icons.swipe_down_alt,
      gesture: 'swipe',
    ),
    TutorialPage(
      title: 'COLLECT COINS',
      description: 'Gather coins to unlock new skins and power-ups!',
      icon: Icons.circle,
      gesture: 'collect',
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _fadeController = AnimationController(
      duration: GameConstants.durationMedium,
      vsync: this,
    );
    
    _gestureController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _gestureAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gestureController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    _gestureController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _gestureController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.85 * _fadeAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Padding(
                    padding: const EdgeInsets.all(GameConstants.spacingLg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _skipTutorial,
                          child: Text(
                            'SKIP',
                            style: GameConstants.labelLarge.copyWith(
                              color: GameConstants.onSurfaceDim,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tutorial content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                        HapticFeedback.lightImpact();
                      },
                      itemCount: _totalPages,
                      itemBuilder: (context, index) {
                        return _buildTutorialPage(_pages[index]);
                      },
                    ),
                  ),
                  
                  // Page indicators and navigation
                  _buildBottomSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTutorialPage(TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.all(GameConstants.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated gesture demonstration
          _buildGestureDemo(page),
          
          const SizedBox(height: GameConstants.spacingXxl),
          
          // Tutorial card
          GlassCard(
            borderRadius: GameConstants.radiusXl,
            padding: const EdgeInsets.all(GameConstants.spacingXl),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: GameConstants.accentGradient,
                    borderRadius: BorderRadius.circular(GameConstants.radiusFull),
                  ),
                  child: Icon(
                    page.icon,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: GameConstants.spacingLg),
                
                // Title
                Text(
                  page.title,
                  style: GameConstants.displayMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: GameConstants.spacingMd),
                
                // Description
                Text(
                  page.description,
                  style: GameConstants.bodyLarge.copyWith(
                    color: GameConstants.onSurfaceDim,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGestureDemo(TutorialPage page) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: GameConstants.accent.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: AnimatedBuilder(
        animation: _gestureAnimation,
        builder: (context, child) {
          return Center(
            child: _buildGestureIcon(page.gesture),
          );
        },
      ),
    );
  }
  
  Widget _buildGestureIcon(String gesture) {
    final animationValue = _gestureAnimation.value;
    
    switch (gesture) {
      case 'tap':
        return Transform.scale(
          scale: 1.0 + (animationValue * 0.3),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: GameConstants.accent.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app,
              color: Colors.white,
              size: 30,
            ),
          ),
        );
        
      case 'swipe':
        return Transform.translate(
          offset: Offset(0, animationValue * 20 - 10),
          child: Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: GameConstants.accent.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(GameConstants.radiusMd),
            ),
            child: const Icon(
              Icons.swipe_down_alt,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
        
      case 'collect':
        return Transform.rotate(
          angle: animationValue * 3.14159 * 2,
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              gradient: GameConstants.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.circle,
              color: Colors.white,
              size: 25,
            ),
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(GameConstants.spacingXl),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _totalPages,
              (index) => _buildPageIndicator(index),
            ),
          ),
          
          const SizedBox(height: GameConstants.spacingXl),
          
          // Navigation button
          _currentPage == _totalPages - 1
              ? AnimatedButton(
                  label: 'GOT IT!',
                  icon: Icons.check,
                  gradient: GameConstants.accentGradient,
                  onTap: _completeTutorial,
                  width: 200,
                  pulse: true,
                )
              : AnimatedButton(
                  label: 'NEXT',
                  icon: Icons.arrow_forward,
                  gradient: GameConstants.accentGradient,
                  onTap: _nextPage,
                  width: 200,
                ),
        ],
      ),
    );
  }
  
  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? GameConstants.accent 
            : GameConstants.accent.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
  
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: GameConstants.durationMedium,
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _skipTutorial() {
    _completeTutorial();
  }
  
  void _completeTutorial() async {
    // Mark tutorial as seen
    final storageService = await StorageService.getInstance();
    await storageService.setTutorialSeen(true);
    
    // Animate out
    await _fadeController.reverse();
    
    widget.onComplete();
  }
}

/// Data class for tutorial pages
class TutorialPage {
  final String title;
  final String description;
  final IconData icon;
  final String gesture;
  
  const TutorialPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gesture,
  });
}