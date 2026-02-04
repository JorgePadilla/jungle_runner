import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../game/jungle_runner_game.dart';
import '../utils/constants.dart';
import 'game_over_overlay.dart';

/// Game screen that wraps the GameWidget and handles UI overlays
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late JungleRunnerGame _game;
  int _currentScore = 0;
  int _currentCoins = 0;
  bool _isPaused = false;
  bool _isGameOver = false;
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }
  
  void _initializeGame() {
    _game = JungleRunnerGame();
    
    // Set up game callbacks
    _game.onScoreChanged = (score, coins) {
      if (mounted) {
        setState(() {
          _currentScore = score;
          _currentCoins = coins;
        });
      }
    };
    
    _game.onGameOver = () {
      if (mounted) {
        setState(() {
          _isGameOver = true;
        });
      }
    };
    
    _game.onPause = () {
      if (mounted) {
        setState(() {
          _isPaused = true;
        });
      }
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game widget
          GameWidget.controlled(
            gameFactory: () => _game,
          ),
          
          // HUD overlay
          if (!_isGameOver) _buildHUD(),
          
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
        ],
      ),
    );
  }
  
  Widget _buildHUD() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(GameConstants.hudMargin),
        child: Column(
          children: [
            // Top HUD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentScore}m',
                        style: GameConstants.hudStyle,
                      ),
                    ],
                  ),
                ),
                
                // Pause button
                GestureDetector(
                  onTap: _pauseGame,
                  child: Container(
                    width: GameConstants.pauseButtonSize,
                    height: GameConstants.pauseButtonSize,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            
            // Second row with coins and power-ups
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Coins
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: GameConstants.gold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _currentCoins.toString(),
                        style: GameConstants.hudStyle,
                      ),
                    ],
                  ),
                ),
                
                // Power-up indicators
                Row(
                  children: [
                    // Shield indicator
                    if (_game.hasShield)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${_game.shieldTimeRemaining.ceil()}s',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Magnet indicator
                    if (_game.hasMagnet)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_money, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${_game.magnetTimeRemaining.ceil()}s',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            const Spacer(),
            
            // Swipe gesture detector area (bottom half of screen)
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Detect swipe down
                  if (details.delta.dy > 10) {
                    _game.handleSwipe('down');
                  }
                },
                child: Container(
                  width: double.infinity,
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Resume button
            SizedBox(
              width: 200,
              height: GameConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _resumeGame,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('RESUME', style: GameConstants.buttonStyle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameConstants.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GameConstants.buttonRadius),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Main menu button
            SizedBox(
              width: 200,
              height: GameConstants.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _backToMainMenu,
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text('MAIN MENU', style: GameConstants.buttonStyle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameConstants.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GameConstants.buttonRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _pauseGame() {
    _game.pauseGame();
  }
  
  void _resumeGame() {
    setState(() {
      _isPaused = false;
    });
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