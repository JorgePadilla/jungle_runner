import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';

/// Show the missions dialog.
/// Returns `true` if coins were claimed (so caller can refresh UI).
Future<bool> showMissionsDialog(BuildContext context) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Missions',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const _MissionsDialog(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(curve),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
  return result ?? false;
}

class _MissionsDialog extends StatefulWidget {
  const _MissionsDialog();

  @override
  State<_MissionsDialog> createState() => _MissionsDialogState();
}

class _MissionsDialogState extends State<_MissionsDialog>
    with TickerProviderStateMixin {
  late MissionService _missionService;
  List<Mission> _missions = [];
  bool _isLoading = true;
  bool _didClaim = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _load();
  }

  Future<void> _load() async {
    _missionService = await MissionService.getInstance();
    _missions = await _missionService.getActiveMissions();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _claimMission(Mission mission) async {
    HapticFeedback.heavyImpact();
    final reward = await _missionService.claimMission(mission.id);
    if (reward > 0) {
      _didClaim = true;
      _missions = await _missionService.getActiveMissions();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('+$reward coins!',
                    style: GameConstants.bodyLarge.copyWith(color: Colors.white)),
              ],
            ),
            backgroundColor: GameConstants.accent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _didClaim) {
          // Already popping — result handled by showGeneralDialog future
        }
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: Colors.transparent,
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              borderRadius: GameConstants.radiusXl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flag, color: GameConstants.accent, size: 24),
                      const SizedBox(width: 8),
                      const Text('MISSIONS', style: GameConstants.displayMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete missions to earn coins',
                    style: GameConstants.bodyMedium.copyWith(color: GameConstants.onSurfaceDim),
                  ),
                  const SizedBox(height: 20),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: GameConstants.accent),
                    )
                  else
                    ..._missions.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMissionCard(m),
                        )),

                  const SizedBox(height: 4),

                  // Close button
                  AnimatedButton(
                    label: 'CLOSE',
                    icon: Icons.close,
                    color: GameConstants.surfaceLight,
                    width: 160,
                    height: 42,
                    fontSize: 13,
                    onTap: () => Navigator.of(context).pop(_didClaim),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard(Mission mission) {
    final claimable = mission.completed && !mission.claimed;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GameConstants.radiusMd),
            boxShadow: claimable
                ? [
                    BoxShadow(
                      color: GameConstants.accent.withValues(alpha: _glowAnimation.value * 0.4),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: GameConstants.radiusMd,
        glowBorder: claimable,
        glowColor: GameConstants.accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — icon + title + reward
            Row(
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _iconColorForType(mission.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      _iconForType(mission.type),
                      color: _iconColorForType(mission.type),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: GameConstants.labelLarge.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mission.description,
                        style: GameConstants.bodyMedium.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Reward badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: GameConstants.goldGradient,
                    borderRadius: BorderRadius.circular(GameConstants.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.white, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${mission.coinReward}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: mission.progressPercent,
                      minHeight: 8,
                      backgroundColor: GameConstants.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        mission.completed ? GameConstants.accent : GameConstants.accent.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${mission.progress.clamp(0, mission.target)}/${mission.target}',
                  style: GameConstants.labelSmall.copyWith(
                    color: mission.completed ? GameConstants.accent : GameConstants.onSurfaceDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Claim button for completed missions
            if (claimable)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: AnimatedButton(
                    label: 'CLAIM',
                    icon: Icons.card_giftcard,
                    gradient: GameConstants.accentGradient,
                    width: 140,
                    height: 38,
                    fontSize: 13,
                    pulse: true,
                    onTap: () => _claimMission(mission),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(MissionType type) {
    switch (type) {
      case MissionType.runDistance:
        return Icons.directions_run;
      case MissionType.collectCoins:
        return Icons.monetization_on;
      case MissionType.useShield:
        return Icons.shield;
      case MissionType.useMagnet:
        return Icons.attach_money;
      case MissionType.reachScore:
        return Icons.flag;
      case MissionType.playGames:
        return Icons.videogame_asset;
      case MissionType.slideTimes:
        return Icons.swap_vert;
      case MissionType.jumpTimes:
        return Icons.arrow_upward;
    }
  }

  Color _iconColorForType(MissionType type) {
    switch (type) {
      case MissionType.runDistance:
      case MissionType.reachScore:
        return GameConstants.accent;
      case MissionType.collectCoins:
        return GameConstants.coinGold;
      case MissionType.useShield:
        return GameConstants.blue;
      case MissionType.useMagnet:
        return GameConstants.purple;
      case MissionType.playGames:
        return GameConstants.success;
      case MissionType.slideTimes:
        return GameConstants.dangerLight;
      case MissionType.jumpTimes:
        return GameConstants.accentLight;
    }
  }
}
