import 'dart:async';
import 'package:games_services/games_services.dart';
import '../utils/constants.dart';

class PlayGamesService {
  static final PlayGamesService _instance = PlayGamesService._internal();
  static PlayGamesService get instance => _instance;
  
  PlayGamesService._internal();

  PlayerData? _player;
  StreamSubscription? _playerSubscription;
  bool _isInitialized = false;

  /// Initialize the service and attempt silent sign-in
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('[PlayGames] Initializing Play Games Services...');
      
      // Listen to player state changes
      _playerSubscription = GameAuth.player.listen(
        (PlayerData? player) {
          _player = player;
          print('[PlayGames] Player state changed: ${player?.displayName ?? 'NOT SIGNED IN'}');
        },
        onError: (error) {
          print('[PlayGames] Player stream error: $error');
        },
      );

      // Attempt silent sign-in
      print('[PlayGames] Attempting sign-in...');
      final result = await GameAuth.signIn();
      print('[PlayGames] Sign-in result: $result');
      _isInitialized = true;
      print('[PlayGames] Initialized successfully. isSignedIn=$isSignedIn, player=${_player?.displayName}');
    } catch (e, stack) {
      print('[PlayGames] Initialization FAILED: $e');
      print('[PlayGames] Stack: $stack');
      // Don't throw - game should work without Play Games
      _isInitialized = true; // Mark as initialized even if sign-in failed
    }
  }

  /// Submit a score to the leaderboard
  Future<void> submitScore(int score) async {
    try {
      if (!_isInitialized) {
        print('[PlayGames] Not initialized, skipping score submission');
        return;
      }

      if (!isSignedIn) {
        print('[PlayGames] Not signed in, skipping score submission');
        return;
      }

      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: GameConstants.androidLeaderboardId,
          value: score,
        ),
      );
      print('[PlayGames] Score submitted: $score');
    } catch (e) {
      print('[PlayGames] Failed to submit score: $e');
    }
  }

  /// Show the native leaderboard UI
  /// Returns a status string for UI feedback
  Future<String?> showLeaderboard() async {
    try {
      print('[PlayGames] showLeaderboard() called. isInitialized=$_isInitialized, isSignedIn=$isSignedIn');
      
      if (!_isInitialized) {
        print('[PlayGames] Not initialized, calling init...');
        await init();
      }

      // If not signed in, try signing in first
      if (!isSignedIn) {
        print('[PlayGames] Not signed in, attempting sign-in...');
        try {
          final result = await GameAuth.signIn();
          print('[PlayGames] Sign-in result: $result');
          // Wait briefly for the stream to update
          await Future.delayed(const Duration(milliseconds: 500));
          print('[PlayGames] After sign-in wait, isSignedIn=$isSignedIn, player=${_player?.displayName}');
        } catch (e) {
          print('[PlayGames] Sign-in attempt FAILED: $e');
          return 'Sign in to Google Play Games to view leaderboards';
        }
      }

      if (!isSignedIn) {
        print('[PlayGames] Still not signed in after attempt');
        return 'Could not sign in to Google Play Games';
      }

      print('[PlayGames] Opening leaderboard with ID: ${GameConstants.androidLeaderboardId}');
      await Leaderboards.showLeaderboards(
        androidLeaderboardID: GameConstants.androidLeaderboardId,
      );
      print('[PlayGames] Leaderboard opened successfully');
      return null; // success
    } catch (e) {
      print('[PlayGames] Failed to show leaderboard: $e');
      return 'Could not open leaderboard: $e';
    }
  }

  /// Check if player is currently signed in
  bool get isSignedIn => _player != null;

  /// Get the player's display name if signed in
  String? get playerName => _player?.displayName;

  /// Dispose of resources
  void dispose() {
    _playerSubscription?.cancel();
    _playerSubscription = null;
    _player = null;
    _isInitialized = false;
  }
}