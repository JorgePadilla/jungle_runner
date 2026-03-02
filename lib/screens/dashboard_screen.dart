import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _runs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await StorageService.getInstance();
    final stats = await storage.getLifetimeStats();
    final runs = await storage.getRunHistory(limit: 50);
    if (mounted) {
      setState(() {
        _stats = stats;
        _runs = runs;
        _isLoading = false;
      });
    }
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
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: GameConstants.accent))
                    : _buildContent(),
              ),
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
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: GlassCard(
              padding: const EdgeInsets.all(GameConstants.spacingSm),
              borderRadius: GameConstants.radiusFull,
              child: const Icon(Icons.arrow_back,
                  color: GameConstants.onSurface, size: 24),
            ),
          ),
          const SizedBox(width: GameConstants.spacingMd),
          Text('DASHBOARD',
              style: GameConstants.headlineMedium
                  .copyWith(color: GameConstants.onSurface)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: GameConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lifetime stats cards
          _buildStatsGrid(),
          const SizedBox(height: GameConstants.spacingXl),

          // Recent runs
          Text('RECENT RUNS',
              style: GameConstants.headlineMedium
                  .copyWith(color: GameConstants.accent)),
          const SizedBox(height: GameConstants.spacingMd),

          if (_runs.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(GameConstants.spacingXl),
              child: Center(
                child: Text('No runs yet — go play!',
                    style: GameConstants.bodyLarge
                        .copyWith(color: GameConstants.onSurfaceDim)),
              ),
            )
          else
            ..._runs.asMap().entries.map((e) => _buildRunCard(e.key, e.value)),

          const SizedBox(height: GameConstants.spacingXl),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final highScore = _stats['highScore'] ?? 0;
    final totalRuns = _stats['totalRuns'] ?? 0;
    final totalDistance = _stats['totalDistance'] ?? 0;
    final totalCoins = _stats['totalCoinsEarned'] ?? 0;
    final totalJumps = _stats['totalJumps'] ?? 0;
    final totalSlides = _stats['totalSlides'] ?? 0;
    final avgScore = totalRuns > 0 ? (totalDistance / totalRuns).round() : 0;

    return Column(
      children: [
        // Hero card — high score
        GlassCard(
          padding: const EdgeInsets.all(GameConstants.spacingLg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: GameConstants.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: GameConstants.spacingLg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BEST RUN',
                      style: GameConstants.bodyMedium
                          .copyWith(color: GameConstants.onSurfaceDim)),
                  Text('${highScore}m',
                      style: GameConstants.displayMedium
                          .copyWith(color: GameConstants.coinGold)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: GameConstants.spacingMd),

        // 2-column stat cards
        Row(
          children: [
            Expanded(
                child: _statCard(
                    Icons.repeat, 'Total Runs', '$totalRuns', GameConstants.accent)),
            const SizedBox(width: GameConstants.spacingMd),
            Expanded(
                child: _statCard(Icons.straighten, 'Avg Score', '${avgScore}m',
                    GameConstants.blue)),
          ],
        ),
        const SizedBox(height: GameConstants.spacingMd),
        Row(
          children: [
            Expanded(
                child: _statCard(Icons.explore, 'Total Distance',
                    _formatDistance(totalDistance), GameConstants.purple)),
            const SizedBox(width: GameConstants.spacingMd),
            Expanded(
                child: _statCard(Icons.monetization_on, 'Coins Earned',
                    '$totalCoins', GameConstants.coinGold)),
          ],
        ),
        const SizedBox(height: GameConstants.spacingMd),
        Row(
          children: [
            Expanded(
                child: _statCard(Icons.arrow_upward, 'Jumps', '$totalJumps',
                    GameConstants.accent)),
            const SizedBox(width: GameConstants.spacingMd),
            Expanded(
                child: _statCard(Icons.height, 'Slides', '$totalSlides',
                    GameConstants.warning)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(GameConstants.spacingMd),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: GameConstants.spacingSm),
          Text(value,
              style: GameConstants.headlineMedium
                  .copyWith(color: GameConstants.onSurface),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: GameConstants.labelSmall
                  .copyWith(color: GameConstants.onSurfaceDim, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRunCard(int index, Map<String, dynamic> run) {
    final date = run['date'] as DateTime;
    final score = run['score'] as int;
    final coins = run['coins'] as int;
    final jumps = run['jumps'] as int;
    final slides = run['slides'] as int;
    final isHighScore = score == (_stats['highScore'] ?? 0) && score > 0;
    final timeAgo = _timeAgo(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: GameConstants.spacingSm),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
            horizontal: GameConstants.spacingMd,
            vertical: GameConstants.spacingSm + 2),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 32,
              child: Text(
                '#${index + 1}',
                style: GameConstants.labelLarge.copyWith(
                    color: index < 3
                        ? GameConstants.coinGold
                        : GameConstants.onSurfaceDim),
              ),
            ),

            // Score
            Expanded(
              child: Row(
                children: [
                  Text('${score}m',
                      style: GameConstants.labelLarge.copyWith(
                          color: GameConstants.onSurface,
                          fontWeight: FontWeight.bold)),
                  if (isHighScore) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: GameConstants.goldGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('BEST',
                          style: GameConstants.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),

            // Mini stats
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monetization_on,
                    size: 14, color: GameConstants.coinGold),
                const SizedBox(width: 2),
                Text('$coins',
                    style: GameConstants.labelSmall
                        .copyWith(color: GameConstants.onSurfaceDim)),
                const SizedBox(width: 8),
                Text(timeAgo,
                    style: GameConstants.labelSmall
                        .copyWith(color: GameConstants.onSurfaceDim, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.month}/${date.day}';
  }
}
