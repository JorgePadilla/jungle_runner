import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../game/config/game_config.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_button.dart';

/// Fully redesigned character shop with carousel, purchase bottom sheet,
/// animated coin counter, and celebration effects.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  late StorageService _storageService;
  late TabController _tabController;

  // ── Animations ──────────────────────────────────────────────────
  late AnimationController _entranceController;
  late AnimationController _coinBounceController;
  late AnimationController _celebrationController;
  late Animation<double> _entranceFade;
  late Animation<Offset> _headerSlide;
  late Animation<Offset> _bodySlide;
  late Animation<double> _coinBounce;

  // ── State ───────────────────────────────────────────────────────
  int _totalCoins = 0;
  int _displayedCoins = 0;
  List<String> _unlockedSkins = [];
  String _selectedSkin = 'default';
  int _shieldLevel = 1;
  int _magnetLevel = 1;
  bool _isDoubleCoinsPurchased = false;
  bool _isLoading = true;
  String? _celebratingSkinId;

  // Sorted skin ids – featured (most expensive) first.
  late List<String> _sortedSkinIds;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _prepareSkinOrder();
    _setupAnimations();
    _initializeData();
  }

  // ── Skin sort (featured first, then by price desc) ────────────
  void _prepareSkinOrder() {
    final entries = GameConfig.skinPrices.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _sortedSkinIds = entries.map((e) => e.key).toList();
  }

  // ── Animations setup ──────────────────────────────────────────
  void _setupAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));
    _bodySlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _coinBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _coinBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _coinBounceController,
      curve: Curves.easeInOut,
    ));

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  // ── Data loading ──────────────────────────────────────────────
  Future<void> _initializeData() async {
    _storageService = await StorageService.getInstance();
    _totalCoins = await _storageService.getTotalCoins();
    _displayedCoins = _totalCoins;
    _unlockedSkins = await _storageService.getUnlockedSkins();
    _selectedSkin = await _storageService.getSelectedSkin();
    _shieldLevel = await _storageService.getShieldLevel();
    _magnetLevel = await _storageService.getMagnetLevel();
    _isDoubleCoinsPurchased = await _storageService.isDoubleCoinsPurchased();

    if (mounted) {
      setState(() => _isLoading = false);
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entranceController.dispose();
    _coinBounceController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GameConstants.backgroundGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: GameConstants.accent))
              : FadeTransition(
                  opacity: _entranceFade,
                  child: Column(
                    children: [
                      SlideTransition(position: _headerSlide, child: _buildHeader()),
                      const SizedBox(height: GameConstants.spacingSm),
                      Expanded(
                        child: SlideTransition(
                          position: _bodySlide,
                          child: _buildBody(),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          GameConstants.spacingSm, GameConstants.spacingMd,
          GameConstants.spacingMd, 0),
      child: Row(
        children: [
          // Back
          _backButton(),
          const SizedBox(width: GameConstants.spacingSm),
          // Title
          Expanded(
            child: Text(
              'CHARACTER SHOP',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GameConstants.displayMedium.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(width: GameConstants.spacingSm),
          // Coin badge
          _coinBadge(),
        ],
      ),
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      },
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        borderRadius: GameConstants.radiusMd,
        child: const Icon(Icons.arrow_back_rounded,
            color: GameConstants.onSurface, size: 24),
      ),
    );
  }

  Widget _coinBadge() {
    return MultiAnimatedBuilder(
      animation: _coinBounce,
      builder: (context, child) => Transform.scale(
        scale: _coinBounce.value,
        child: child,
      ),
      child: GlassCard(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        borderRadius: GameConstants.radiusFull,
        glowBorder: true,
        glowColor: GameConstants.coinGold,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on_rounded,
                color: GameConstants.coinGold, size: 22),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: GameConstants.durationFast,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                _displayedCoins.toString(),
                key: ValueKey<int>(_displayedCoins),
                style: GameConstants.labelLarge
                    .copyWith(color: GameConstants.coinGold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      children: [
        // Tab bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GameConstants.spacingMd),
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(GameConstants.radiusMd),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(GameConstants.radiusMd),
                gradient: GameConstants.accentGradient,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: GameConstants.onSurfaceDim,
              labelStyle: GameConstants.labelLarge,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'SKINS'),
                Tab(text: 'UPGRADES'),
              ],
            ),
          ),
        ),
        const SizedBox(height: GameConstants.spacingSm),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSkinsTab(),
              _buildUpgradesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkinsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: GameConstants.spacingXl,
              vertical: GameConstants.spacingSm),
          child: Text(
            'Choose your hero for the jungle adventure!',
            textAlign: TextAlign.center,
            style: GameConstants.bodyMedium.copyWith(fontSize: 15),
          ),
        ),
        const SizedBox(height: GameConstants.spacingSm),
        Expanded(child: _buildCarousel()),
      ],
    );
  }

  Widget _buildUpgradesTab() {
    return ListView(
      padding: const EdgeInsets.all(GameConstants.spacingMd),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildUpgradeItem(
          title: 'Shield Duration',
          description: 'Stay protected longer',
          icon: Icons.shield_rounded,
          color: Colors.blue,
          level: _shieldLevel,
          onUpgrade: () => _upgradePowerUp('shield'),
          maxLevel: GameConfig.maxUpgradeLevel,
          price: GameConfig.shieldUpgradePrices[_shieldLevel + 1],
          nextBenefit: '+${((GameConfig.shieldDurations[_shieldLevel + 1] ?? 0) - (GameConfig.shieldDurations[_shieldLevel] ?? 0)).toInt()}s duration',
        ),
        const SizedBox(height: GameConstants.spacingMd),
        _buildUpgradeItem(
          title: 'Magnet Duration',
          description: 'Attract coins for longer',
          icon: Icons.monetization_on_rounded,
          color: Colors.amber,
          level: _magnetLevel,
          onUpgrade: () => _upgradePowerUp('magnet'),
          maxLevel: GameConfig.maxUpgradeLevel,
          price: GameConfig.magnetUpgradePrices[_magnetLevel + 1],
          nextBenefit: '+${((GameConfig.magnetDurations[_magnetLevel + 1] ?? 0) - (GameConfig.magnetDurations[_magnetLevel] ?? 0)).toInt()}s duration',
        ),
        const SizedBox(height: GameConstants.spacingMd),
        _buildBoosterItem(
          title: 'Double Coins',
          description: 'Permanent 2x coins multiplier',
          icon: Icons.stars_rounded,
          color: GameConstants.coinGold,
          isPurchased: _isDoubleCoinsPurchased,
          price: GameConfig.doubleCoinsPrice,
          onPurchase: _purchaseDoubleCoins,
        ),
      ],
    );
  }

  Widget _buildUpgradeItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int level,
    required VoidCallback onUpgrade,
    required int maxLevel,
    int? price,
    String? nextBenefit,
  }) {
    final isMax = level >= maxLevel;
    final canAfford = price != null && _totalCoins >= price;

    return GlassCard(
      padding: const EdgeInsets.all(GameConstants.spacingMd),
      borderRadius: GameConstants.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: GameConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GameConstants.headlineMedium.copyWith(fontSize: 16)),
                    Text(description, style: GameConstants.bodyMedium),
                  ],
                ),
              ),
              if (!isMax)
                _buildPriceTag(price!, canAfford)
              else
                _buildMaxTag(),
            ],
          ),
          const SizedBox(height: GameConstants.spacingMd),
          Row(
            children: [
              ...List.generate(maxLevel, (index) {
                final isActive = index < level;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive ? color : Colors.white10,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)] : null,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: GameConstants.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $level / $maxLevel', style: GameConstants.labelSmall),
              if (!isMax && nextBenefit != null)
                Text('Next: $nextBenefit', style: GameConstants.labelSmall.copyWith(color: color)),
            ],
          ),
          if (!isMax) ...[
            const SizedBox(height: GameConstants.spacingMd),
            AnimatedButton(
              label: 'UPGRADE',
              height: 40,
              gradient: canAfford ? GameConstants.accentGradient : null,
              color: canAfford ? null : Colors.white10,
              onTap: onUpgrade,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoosterItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isPurchased,
    required int price,
    required VoidCallback onPurchase,
  }) {
    final canAfford = _totalCoins >= price;

    return GlassCard(
      padding: const EdgeInsets.all(GameConstants.spacingMd),
      borderRadius: GameConstants.radiusLg,
      glowBorder: !isPurchased,
      glowColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: GameConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GameConstants.headlineMedium.copyWith(fontSize: 16)),
                Text(description, style: GameConstants.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: GameConstants.spacingSm),
          if (isPurchased)
            _buildMaxTag(label: 'ACTIVE')
          else
            Column(
              children: [
                _buildPriceTag(price, canAfford),
                const SizedBox(height: 8),
                AnimatedButton(
                  label: 'BUY',
                  width: 70,
                  height: 32,
                  fontSize: 11,
                  gradient: canAfford ? GameConstants.goldGradient : null,
                  color: canAfford ? null : Colors.white10,
                  onTap: onPurchase,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPriceTag(int price, bool canAfford) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(GameConstants.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, color: canAfford ? GameConstants.coinGold : Colors.grey, size: 14),
          const SizedBox(width: 4),
          Text(
            price.toString(),
            style: TextStyle(
              color: canAfford ? GameConstants.coinGold : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaxTag({String label = 'MAX'}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: GameConstants.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GameConstants.radiusSm),
        border: Border.all(color: GameConstants.success.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: GameConstants.success,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ── Carousel ──────────────────────────────────────────────────
  Widget _buildCarousel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.62;
        final viewFraction = cardWidth / constraints.maxWidth;
        return PageView.builder(
          controller: PageController(viewportFraction: viewFraction),
          itemCount: _sortedSkinIds.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final skinId = _sortedSkinIds[index];
            final isFeatured = index == 0; // Most expensive
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: GameConstants.spacingSm,
                  vertical: GameConstants.spacingMd),
              child: _SkinCard(
                skinId: skinId,
                isFeatured: isFeatured,
                isUnlocked: _unlockedSkins.contains(skinId),
                isSelected: _selectedSkin == skinId,
                canAfford: _totalCoins >= (GameConfig.skinPrices[skinId] ?? 0),
                celebrating: _celebratingSkinId == skinId,
                celebrationAnimation: _celebrationController,
                onTap: () => _onSkinTapped(skinId),
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PURCHASE LOGIC
  // ════════════════════════════════════════════════════════════════

  Future<void> _onSkinTapped(String skinId) async {
    if (skinId == _selectedSkin) return;

    final isUnlocked = _unlockedSkins.contains(skinId);
    final price = GameConfig.skinPrices[skinId] ?? 0;
    final canAfford = _totalCoins >= price;

    if (isUnlocked) {
      await _selectSkin(skinId);
    } else if (price == 0) {
      await _storageService.unlockSkin(skinId);
      await _selectSkin(skinId);
    } else if (canAfford) {
      _showPurchaseSheet(skinId, price);
    } else {
      _showInsufficientSheet(price);
    }
  }

  Future<void> _selectSkin(String skinId) async {
    HapticFeedback.mediumImpact();
    await _storageService.setSelectedSkin(skinId);
    await _refreshData();
  }

  Future<void> _purchaseSkin(String skinId, int price) async {
    final success = await _storageService.spendCoins(price);
    if (!success) return;

    await _storageService.unlockSkin(skinId);
    await _storageService.setSelectedSkin(skinId);

    // Animate coin decrease
    _animateCoinDecrease(price);

    // Celebration
    setState(() => _celebratingSkinId = skinId);
    _celebrationController.forward(from: 0);
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _celebratingSkinId = null);

    await _refreshData();
  }

  void _animateCoinDecrease(int amount) {
    final start = _displayedCoins;
    final end = start - amount;
    const steps = 12;
    final stepDuration =
        Duration(milliseconds: (400 / steps).round());
    int current = 0;

    void tick() {
      current++;
      if (!mounted) return;
      final progress = current / steps;
      setState(() {
        _displayedCoins = (start - (amount * progress)).round();
      });
      _coinBounceController.forward(from: 0);
      if (current < steps) {
        Future.delayed(stepDuration, tick);
      } else {
        setState(() => _displayedCoins = end);
      }
    }

    tick();
  }

  Future<void> _refreshData() async {
    _totalCoins = await _storageService.getTotalCoins();
    _displayedCoins = _totalCoins;
    _unlockedSkins = await _storageService.getUnlockedSkins();
    _selectedSkin = await _storageService.getSelectedSkin();
    _shieldLevel = await _storageService.getShieldLevel();
    _magnetLevel = await _storageService.getMagnetLevel();
    _isDoubleCoinsPurchased = await _storageService.isDoubleCoinsPurchased();
    if (mounted) setState(() {});
  }

  // ════════════════════════════════════════════════════════════════
  //  UPGRADE LOGIC
  // ════════════════════════════════════════════════════════════════

  Future<void> _upgradePowerUp(String type) async {
    final isShield = type == 'shield';
    final currentLevel = isShield ? _shieldLevel : _magnetLevel;

    if (currentLevel >= GameConfig.maxUpgradeLevel) return;

    final nextLevel = currentLevel + 1;
    final price = isShield
        ? GameConfig.shieldUpgradePrices[nextLevel]
        : GameConfig.magnetUpgradePrices[nextLevel];

    if (price == null) return;

    if (_totalCoins >= price) {
      _showUpgradeConfirmSheet(
        title: isShield ? 'Upgrade Shield?' : 'Upgrade Magnet?',
        price: price,
        onConfirm: () async {
          Navigator.of(context).pop();
          final success = await _storageService.spendCoins(price);
          if (success) {
            if (isShield) {
              await _storageService.setShieldLevel(nextLevel);
            } else {
              await _storageService.setMagnetLevel(nextLevel);
            }
            _animateCoinDecrease(price);
            HapticFeedback.heavyImpact();
            await _refreshData();
          }
        },
      );
    } else {
      _showInsufficientSheet(price);
    }
  }

  Future<void> _purchaseDoubleCoins() async {
    if (_isDoubleCoinsPurchased) return;

    final price = GameConfig.doubleCoinsPrice;

    if (_totalCoins >= price) {
      _showUpgradeConfirmSheet(
        title: 'Buy Double Coins?',
        price: price,
        onConfirm: () async {
          Navigator.of(context).pop();
          final success = await _storageService.spendCoins(price);
          if (success) {
            await _storageService.setDoubleCoinsPurchased(true);
            _animateCoinDecrease(price);
            HapticFeedback.heavyImpact();
            await _refreshData();
          }
        },
      );
    } else {
      _showInsufficientSheet(price);
    }
  }

  void _showUpgradeConfirmSheet({
    required String title,
    required int price,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PurchaseSheet(
        skinName: '', // Not used for upgrades but required by widget
        skinId: '',
        price: price,
        coins: _totalCoins,
        onConfirm: onConfirm,
        customTitle: title,
      ),
    );
  }

  // ── Purchase bottom sheet ─────────────────────────────────────
  void _showPurchaseSheet(String skinId, int price) {
    final name = GameConfig.skinNames[skinId] ?? skinId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PurchaseSheet(
        skinName: name,
        skinId: skinId,
        price: price,
        coins: _totalCoins,
        onConfirm: () {
          Navigator.of(ctx).pop();
          _purchaseSkin(skinId, price);
        },
      ),
    );
  }

  // ── Insufficient coins sheet ──────────────────────────────────
  void _showInsufficientSheet(int price) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InsufficientSheet(
        price: price,
        coins: _totalCoins,
        onPlayMore: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop(); // back to game
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  _SkinCard  –  individual character showcase card
// ══════════════════════════════════════════════════════════════════

class _SkinCard extends StatefulWidget {
  final String skinId;
  final bool isFeatured;
  final bool isUnlocked;
  final bool isSelected;
  final bool canAfford;
  final bool celebrating;
  final AnimationController celebrationAnimation;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skinId,
    required this.isFeatured,
    required this.isUnlocked,
    required this.isSelected,
    required this.canAfford,
    required this.celebrating,
    required this.celebrationAnimation,
    required this.onTap,
  });

  @override
  State<_SkinCard> createState() => _SkinCardState();
}

class _SkinCardState extends State<_SkinCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = GameConfig.skinNames[widget.skinId] ?? widget.skinId;
    final price = GameConfig.skinPrices[widget.skinId] ?? 0;
    final isLocked = !widget.isUnlocked && price > 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card
          GlassCard(
            borderRadius: GameConstants.radiusXl,
            glowBorder: widget.isSelected,
            glowColor: GameConstants.coinGold,
            borderColor: widget.isSelected
                ? GameConstants.coinGold
                : isLocked
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.15),
            borderWidth: widget.isSelected ? 2.0 : 1.0,
            padding: const EdgeInsets.all(GameConstants.spacingMd),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: GameConstants.spacingSm),
                // Character preview
                Expanded(child: _preview(isLocked)),
                const SizedBox(height: GameConstants.spacingMd),
                // Name
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GameConstants.headlineMedium.copyWith(
                    fontSize: 18,
                    color: isLocked
                        ? GameConstants.onSurfaceDim
                        : GameConstants.onSurface,
                  ),
                ),
                const SizedBox(height: GameConstants.spacingSm),
                // Status / action
                _statusArea(price, isLocked),
                const SizedBox(height: GameConstants.spacingXs),
              ],
            ),
          ),

          // Featured badge
          if (widget.isFeatured)
            Positioned(
              top: -10,
              right: 12,
              child: _featuredBadge(),
            ),

          // Lock overlay
          if (isLocked) _lockOverlay(),

          // Celebration sparkles
          if (widget.celebrating)
            Positioned.fill(child: _CelebrationOverlay(
                animation: widget.celebrationAnimation)),
        ],
      ),
    );
  }

  // ── Preview ─────────────────────────────────────────────────
  Widget _preview(bool isLocked) {
    final color = _skinColor(widget.skinId);
    return MultiAnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: AnimatedOpacity(
        duration: GameConstants.durationMedium,
        opacity: isLocked ? 0.45 : 1.0,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.6), width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/player/jump_${widget.skinId}.png',
              width: 60,
              height: 60,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => Text(
                _skinEmoji(widget.skinId),
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Status row ────────────────────────────────────────────────
  Widget _statusArea(int price, bool isLocked) {
    if (widget.isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: GameConstants.goldGradient,
          borderRadius: BorderRadius.circular(GameConstants.radiusFull),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text('EQUIPPED',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1)),
          ],
        ),
      );
    }

    if (widget.isUnlocked) {
      return AnimatedButton(
        label: 'SELECT',
        height: 38,
        fontSize: 12,
        borderRadius: GameConstants.radiusFull,
        gradient: GameConstants.accentGradient,
        onTap: widget.onTap,
        haptic: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      );
    }

    // Locked – show price badge
    if (price == 0) {
      return AnimatedButton(
        label: 'FREE',
        height: 38,
        fontSize: 12,
        borderRadius: GameConstants.radiusFull,
        color: GameConstants.success,
        onTap: widget.onTap,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: widget.canAfford
            ? GameConstants.coinGold.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(GameConstants.radiusFull),
        border: Border.all(
          color: widget.canAfford
              ? GameConstants.coinGold.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded,
              color: widget.canAfford
                  ? GameConstants.coinGold
                  : GameConstants.onSurfaceDim,
              size: 16),
          const SizedBox(width: 6),
          Text(
            price.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: widget.canAfford
                  ? GameConstants.coinGold
                  : GameConstants.onSurfaceDim,
            ),
          ),
        ],
      ),
    );
  }

  // ── Featured badge ────────────────────────────────────────────
  Widget _featuredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: GameConstants.goldGradient,
        borderRadius: BorderRadius.circular(GameConstants.radiusSm),
        boxShadow: [
          BoxShadow(
            color: GameConstants.coinGold.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 14),
          SizedBox(width: 3),
          Text(
            'FEATURED',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Lock overlay ──────────────────────────────────────────────
  Widget _lockOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GameConstants.radiusXl),
        child: Container(
          color: Colors.black.withValues(alpha: 0.25),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  color: Colors.white70, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Color _skinColor(String id) {
    switch (id) {
      case 'golden':
        return const Color(0xFFFFD700);
      case 'dark':
        return const Color(0xFF6C5CE7);
      case 'rainbow':
        return const Color(0xFFFF6B81);
      case 'ninja':
        return const Color(0xFF2ED573);
      default:
        return const Color(0xFF00D4AA);
    }
  }

  String _skinEmoji(String id) {
    switch (id) {
      case 'golden':
        return '🏃';
      case 'dark':
        return '🎭';
      case 'rainbow':
        return '💃';
      case 'ninja':
        return '🐸';
      default:
        return '🐸';
    }
  }
}

// ══════════════════════════════════════════════════════════════════
//  Celebration overlay  (sparkle particles)
// ══════════════════════════════════════════════════════════════════

class _CelebrationOverlay extends StatelessWidget {
  final AnimationController animation;
  const _CelebrationOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    return MultiAnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;
        return IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GameConstants.radiusXl),
            child: CustomPaint(
              painter: _SparklePainter(progress),
            ),
          ),
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;
  _SparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final count = 18;
    for (int i = 0; i < count; i++) {
      final startX = rng.nextDouble() * size.width;
      final startY = size.height * 0.5 + rng.nextDouble() * size.height * 0.3;
      final dx = (rng.nextDouble() - 0.5) * size.width * 0.6;
      final dy = -rng.nextDouble() * size.height * 0.8;
      final x = startX + dx * progress;
      final y = startY + dy * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final radius = 2.0 + rng.nextDouble() * 3.0;

      final colors = [
        const Color(0xFFFFD700),
        const Color(0xFFFF6B81),
        const Color(0xFF00D4AA),
        const Color(0xFF6C5CE7),
        Colors.white,
      ];
      final color =
          colors[i % colors.length].withValues(alpha: opacity * 0.8);
      canvas.drawCircle(Offset(x, y), radius * (1 - progress * 0.3),
          Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}

// ══════════════════════════════════════════════════════════════════
//  _PurchaseSheet  –  bottom sheet for confirming purchase
// ══════════════════════════════════════════════════════════════════

class _PurchaseSheet extends StatelessWidget {
  final String skinName;
  final String skinId;
  final int price;
  final int coins;
  final VoidCallback onConfirm;
  final String? customTitle;

  const _PurchaseSheet({
    required this.skinName,
    required this.skinId,
    required this.price,
    required this.coins,
    required this.onConfirm,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GameConstants.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(GameConstants.radiusXl)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: GameConstants.spacingLg),
          Text(customTitle ?? 'Unlock $skinName?',
              style: GameConstants.headlineMedium),
          const SizedBox(height: GameConstants.spacingMd),
          // Price row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: GameConstants.coinGold, size: 28),
              const SizedBox(width: 8),
              Text(
                price.toString(),
                style: GameConstants.displayMedium
                    .copyWith(color: GameConstants.coinGold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Balance after: ${coins - price} coins',
            style: GameConstants.bodyMedium,
          ),
          const SizedBox(height: GameConstants.spacingLg),
          // Buttons
          Row(
            children: [
              Expanded(
                child: AnimatedButton(
                  label: 'CANCEL',
                  color: GameConstants.surfaceLight,
                  textColor: GameConstants.onSurfaceDim,
                  height: 48,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: GameConstants.spacingMd),
              Expanded(
                child: AnimatedButton(
                  label: 'PURCHASE',
                  icon: Icons.monetization_on_rounded,
                  gradient: GameConstants.goldGradient,
                  textColor: Colors.white,
                  height: 48,
                  pulse: true,
                  onTap: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  _InsufficientSheet  –  not enough coins
// ══════════════════════════════════════════════════════════════════

class _InsufficientSheet extends StatelessWidget {
  final int price;
  final int coins;
  final VoidCallback onPlayMore;

  const _InsufficientSheet({
    required this.price,
    required this.coins,
    required this.onPlayMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GameConstants.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(GameConstants.radiusXl)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: GameConstants.spacingLg),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GameConstants.danger.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sentiment_dissatisfied_rounded,
                color: GameConstants.danger, size: 40),
          ),
          const SizedBox(height: GameConstants.spacingMd),
          Text('Not Enough Coins',
              style: GameConstants.headlineMedium
                  .copyWith(color: GameConstants.danger)),
          const SizedBox(height: 8),
          Text(
            'You need ${price - coins} more coins.',
            style: GameConstants.bodyMedium,
          ),
          const SizedBox(height: GameConstants.spacingLg),
          AnimatedButton(
            label: 'PLAY MORE',
            subtitle: 'Earn coins in the jungle!',
            icon: Icons.play_arrow_rounded,
            gradient: GameConstants.accentGradient,
            pulse: true,
            height: 48,
            width: double.infinity,
            onTap: onPlayMore,
          ),
          const SizedBox(height: GameConstants.spacingSm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Maybe later',
                style: GameConstants.bodyMedium
                    .copyWith(color: GameConstants.onSurfaceDim)),
          ),
        ],
      ),
    );
  }
}
