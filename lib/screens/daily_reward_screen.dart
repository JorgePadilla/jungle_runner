import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';
import '../game/config/game_config.dart';

/// Shows a daily reward dialog with a 7-day calendar grid.
///
/// Call [showDailyRewardDialog] to display it.
Future<bool> showDailyRewardDialog(BuildContext context) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'DailyReward',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const _DailyRewardDialog(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.7, end: 1.0).animate(curve),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
  return result ?? false;
}

class _DailyRewardDialog extends StatefulWidget {
  const _DailyRewardDialog();

  @override
  State<_DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<_DailyRewardDialog>
    with TickerProviderStateMixin {
  late StorageService _storageService;
  bool _isLoading = true;
  bool _canClaim = false;
  int _streak = 0;
  bool _justClaimed = false;

  // Countdown timer
  Timer? _countdownTimer;
  Duration _timeUntilNext = Duration.zero;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _coinFlyController;
  late Animation<double> _coinFlyAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _coinFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _coinFlyAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _coinFlyController, curve: Curves.easeOut),
    );

    _load();
  }

  Future<void> _load() async {
    _storageService = await StorageService.getInstance();
    _canClaim = await _storageService.canClaimDailyReward();
    _streak = await _storageService.getDailyRewardStreak();

    if (!_canClaim) {
      _startCountdown();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _startCountdown() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  Future<void> _updateCountdown() async {
    final lastReward = await _storageService.getLastDailyReward();
    if (lastReward == null) return;
    final nextAvailable = lastReward.add(const Duration(hours: 24));
    final remaining = nextAvailable.difference(DateTime.now());
    if (remaining.isNegative) {
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() {
          _canClaim = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _timeUntilNext = remaining;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _coinFlyController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _claim() async {
    if (!_canClaim || _justClaimed) return;
    HapticFeedback.heavyImpact();

    await _storageService.claimDailyReward();
    final newStreak = await _storageService.getDailyRewardStreak();

    setState(() {
      _justClaimed = true;
      _canClaim = false;
      _streak = newStreak;
    });

    _coinFlyController.forward();

    // Wait for animation, then close
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: GameConstants.accent));
    }

    final currentDay = _streak % GameConfig.dailyRewards.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GlassCard(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                borderRadius: GameConstants.radiusXl,
                glowBorder: true,
                glowColor: GameConstants.coinGold,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    const Text('DAILY REWARDS', style: GameConstants.displayMedium),
                    const SizedBox(height: 6),
                    Text(
                      _canClaim && !_justClaimed
                          ? 'Your reward is ready!'
                          : _justClaimed
                              ? 'Reward claimed! 🎉'
                              : 'Come back tomorrow!',
                      style: GameConstants.bodyLarge.copyWith(
                        color: _canClaim ? GameConstants.accent : GameConstants.onSurfaceDim,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 7-day grid (top row 4, bottom row 3)
                    _buildCalendarGrid(currentDay),

                    const SizedBox(height: 20),

                    // Countdown or claim button
                    if (!_canClaim && !_justClaimed)
                      _buildCountdown()
                    else if (_justClaimed)
                      _buildClaimedBanner(currentDay)
                    else
                      AnimatedButton(
                        label: 'CLAIM',
                        icon: Icons.card_giftcard,
                        gradient: GameConstants.goldGradient,
                        width: 220,
                        height: 52,
                        pulse: true,
                        onTap: _claim,
                      ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Coin fly-up animation
              if (_justClaimed)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _coinFlyAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _CoinFlyPainter(
                            progress: _coinFlyAnimation.value,
                            coinCount: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(int currentDay) {
    final rewards = GameConfig.dailyRewards;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: List.generate(rewards.length, (i) {
        final isPast = i < currentDay;
        final isCurrent = i == currentDay;
        final isFuture = i > currentDay;
        final reward = rewards[i];

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final glowOpacity = isCurrent && _canClaim && !_justClaimed
                ? _pulseAnimation.value * 0.7
                : 0.0;

            return Container(
              width: 72,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GameConstants.radiusMd),
                color: isCurrent
                    ? GameConstants.coinGold.withValues(alpha: 0.15)
                    : isPast
                        ? GameConstants.accent.withValues(alpha: 0.08)
                        : GameConstants.surface.withValues(alpha: 0.5),
                border: Border.all(
                  color: isCurrent
                      ? GameConstants.coinGold.withValues(alpha: 0.8)
                      : isPast
                          ? GameConstants.accent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: GameConstants.coinGold.withValues(alpha: glowOpacity),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Day ${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isFuture
                          ? GameConstants.onSurfaceDim.withValues(alpha: 0.5)
                          : GameConstants.onSurfaceDim,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isPast)
                    const Icon(Icons.check_circle, color: GameConstants.accent, size: 24)
                  else if (isFuture)
                    Icon(Icons.lock, color: GameConstants.onSurfaceDim.withValues(alpha: 0.3), size: 20)
                  else
                    const Icon(Icons.monetization_on, color: GameConstants.coinGold, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    '$reward',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isFuture
                          ? GameConstants.onSurfaceDim.withValues(alpha: 0.4)
                          : isCurrent
                              ? GameConstants.coinGold
                              : GameConstants.onSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildCountdown() {
    final h = _timeUntilNext.inHours;
    final m = _timeUntilNext.inMinutes % 60;
    final s = _timeUntilNext.inSeconds % 60;
    final timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Text(
          timeStr,
          style: GameConstants.displayMedium.copyWith(
            color: GameConstants.coinGold,
            fontSize: 32,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'until next reward',
          style: GameConstants.bodyMedium.copyWith(color: GameConstants.onSurfaceDim),
        ),
      ],
    );
  }

  Widget _buildClaimedBanner(int claimedDay) {
    final reward = GameConfig.dailyRewards[claimedDay > 0 ? claimedDay - 1 : 0];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: GameConstants.goldGradient,
        borderRadius: BorderRadius.circular(GameConstants.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            '+$reward coins',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints coins flying upward from center.
class _CoinFlyPainter extends CustomPainter {
  final double progress;
  final int coinCount;

  _CoinFlyPainter({required this.progress, required this.coinCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()..color = GameConstants.coinGold.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));
    final centerX = size.width / 2;
    final centerY = size.height * 0.6;

    for (int i = 0; i < coinCount; i++) {
      final angle = (i / coinCount) * 3.14159 * 2;
      final spread = 30 + (progress * 60);
      final x = centerX + spread * (i.isEven ? 1 : -1) * ((i % 4) * 0.3 + 0.3);
      final y = centerY - (progress * 180) - (i * 8);

      canvas.drawCircle(Offset(x, y), 6, paint);

      // Inner highlight
      final highlight = Paint()..color = Colors.white.withValues(alpha: (0.6 - progress * 0.6).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x - 1, y - 1), 2.5, highlight);
    }
  }

  @override
  bool shouldRepaint(covariant _CoinFlyPainter old) => old.progress != progress;
}
