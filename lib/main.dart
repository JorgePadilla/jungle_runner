import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/ad_service.dart';
import 'services/storage_service.dart';
import 'services/play_games_service.dart';
import 'game/managers/audio_manager.dart';
import 'screens/main_menu_screen.dart';
import 'screens/game_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';
import 'utils/page_transitions.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await _initializeServices();
  
  // Set preferred orientations (portrait only for mobile game)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const JungleRunnerApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize ad service
    await AdService.instance.initialize();
    
    // Initialize storage service
    await StorageService.getInstance();
    
    // Initialize audio (preload SFX so menu music + sounds are ready)
    await AudioManager.instance.init();
    
    // Initialize Play Games (sign in silently)
    await PlayGamesService.instance.init();
    
    print('Services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
  }
}

/// Main application widget
class JungleRunnerApp extends StatelessWidget {
  const JungleRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jungle Runner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          surface: GameConstants.surface,
          onSurface: GameConstants.onSurface,
          primary: GameConstants.accent,
          secondary: GameConstants.accent,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        
        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: GameConstants.onSurface),
          titleTextStyle: TextStyle(
            color: GameConstants.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 8,
            backgroundColor: GameConstants.accent,
            foregroundColor: GameConstants.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GameConstants.radiusMd),
            ),
          ),
        ),
        
        // Dialog theme
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameConstants.radiusLg),
          ),
          backgroundColor: GameConstants.surface,
          titleTextStyle: const TextStyle(
            color: GameConstants.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(
            color: GameConstants.onSurfaceDim,
            fontSize: 16,
          ),
        ),
        
        // Snack bar theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: GameConstants.accent,
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameConstants.radiusMd),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      
      // Routes with custom transitions
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/main_menu':
            return FadeScaleTransition(page: MainMenuScreen());
          case '/game':
            return SlideLeftTransition(page: GameScreen());
          case '/shop':
            return SlideLeftTransition(page: ShopScreen());
          case '/settings':
            return SlideUpTransition(page: SettingsScreen());
          default:
            return MaterialPageRoute(builder: (_) => const MainMenuScreen());
        }
      },
    );
  }
}

/// Splash screen with loading animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _progressController;
  late AnimationController _glowController;
  
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _titleScaleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }
  
  void _setupAnimations() {
    // Title animations
    _titleController = AnimationController(
      duration: GameConstants.durationEntrance,
      vsync: this,
    );
    
    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _titleScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
    ));
    
    // Progress bar animation
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startAnimationSequence() async {
    // Start title animation
    await _titleController.forward();
    
    // Start glow pulse
    _glowController.repeat(reverse: true);
    
    // Start progress animation after a small delay
    await Future.delayed(const Duration(milliseconds: 300));
    await _progressController.forward();
    
    // Navigate to main menu
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _navigateToMainMenu();
    }
  }
  
  void _navigateToMainMenu() {
    Navigator.of(context).pushReplacementNamed('/main_menu');
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameConstants.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _titleController,
                      _glowController,
                    ]),
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _titleFadeAnimation,
                        child: ScaleTransition(
                          scale: _titleScaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated app icon
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(GameConstants.radiusXl),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameConstants.coinGold.withValues(alpha: _glowAnimation.value * 0.5),
                                      blurRadius: 20 + (_glowAnimation.value * 10),
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(GameConstants.radiusXl),
                                  child: Image.asset(
                                    'assets/images/ui/app_icon.png',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: GameConstants.spacingXl),
                              
                              // Game title with glow effect
                              Stack(
                                children: [
                                  // Outer glow
                                  Text(
                                    'JUNGLE RUNNER',
                                    style: GameConstants.displayLarge.copyWith(
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 6
                                        ..color = GameConstants.accent.withValues(
                                          alpha: _glowAnimation.value * 0.8,
                                        ),
                                    ),
                                  ),
                                  // Main text
                                  Text(
                                    'JUNGLE RUNNER',
                                    style: GameConstants.displayLarge.copyWith(
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(0, 2),
                                          blurRadius: 8 + (_glowAnimation.value * 4),
                                          color: GameConstants.accent.withValues(alpha: 0.6),
                                        ),
                                        const Shadow(
                                          offset: Offset(0, 4),
                                          blurRadius: 12,
                                          color: Color(0x80000000),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: GameConstants.spacingMd),
                              
                              // Subtitle
                              Text(
                                'Run, Jump, Survive!',
                                style: GameConstants.bodyLarge.copyWith(
                                  color: GameConstants.onSurfaceDim,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Progress bar section
              Padding(
                padding: const EdgeInsets.all(GameConstants.spacingXl),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
                          width: double.infinity,
                          height: 6,
                          decoration: BoxDecoration(
                            color: GameConstants.surface.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(GameConstants.radiusFull),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: _progressAnimation.value,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: GameConstants.accentGradient,
                                borderRadius: BorderRadius.circular(GameConstants.radiusFull),
                                boxShadow: [
                                  BoxShadow(
                                    color: GameConstants.accent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: GameConstants.spacingMd),
                    
                    Text(
                      'Loading...',
                      style: GameConstants.bodyMedium.copyWith(
                        color: GameConstants.onSurfaceDim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error widget for debugging
class ErrorScreen extends StatelessWidget {
  final String error;
  
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 80,
                color: Colors.red,
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/main_menu');
                },
                child: const Text('Go to Main Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}