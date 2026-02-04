import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../game/config/game_config.dart';

/// Shop screen for purchasing character skins
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with TickerProviderStateMixin {
  late StorageService _storageService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _totalCoins = 0;
  List<String> _unlockedSkins = [];
  String _selectedSkin = 'default';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  Future<void> _initializeData() async {
    _storageService = await StorageService.getInstance();
    
    _totalCoins = await _storageService.getTotalCoins();
    _unlockedSkins = await _storageService.getUnlockedSkins();
    _selectedSkin = await _storageService.getSelectedSkin();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Sky blue
              Color(0xFF228B22), // Forest green
              Color(0xFF006400), // Dark green
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Main content
              Expanded(
                child: _isLoading 
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _buildShopContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(GameConstants.padding),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          ),
          
          // Title
          const Expanded(
            child: Text(
              'MONKEY SHOP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Coins display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: GameConstants.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  _totalCoins.toString(),
                  style: GameConstants.hudStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShopContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(GameConstants.padding),
        child: Column(
          children: [
            // Shop description
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'Customize your monkey! Unlock new skins with coins collected during your jungle adventures.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
            
            // Skins grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemCount: GameConfig.skinNames.length,
                itemBuilder: (context, index) {
                  final skinId = GameConfig.skinNames.keys.elementAt(index);
                  return _buildSkinCard(skinId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSkinCard(String skinId) {
    final skinName = GameConfig.skinNames[skinId]!;
    final skinPrice = GameConfig.skinPrices[skinId]!;
    final isUnlocked = _unlockedSkins.contains(skinId);
    final isSelected = _selectedSkin == skinId;
    final canAfford = _totalCoins >= skinPrice;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected 
            ? GameConstants.gold.withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? GameConstants.gold : Colors.transparent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _onSkinTapped(skinId, isUnlocked, canAfford, skinPrice),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Skin preview
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getSkinColor(skinId),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: _buildSkinPreview(skinId),
                ),
                
                const SizedBox(height: 12),
                
                // Skin name
                Text(
                  skinName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Status/Price/Select button
                _buildSkinButton(skinId, isUnlocked, isSelected, canAfford, skinPrice),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getSkinColor(String skinId) {
    switch (skinId) {
      case 'golden':
        return GameConstants.gold;
      case 'dark':
        return const Color(0xFF2F2F2F);
      case 'rainbow':
        return Colors.purple[300]!; // Simplified for preview
      case 'ninja':
        return const Color(0xFF1a1a1a);
      default:
        return GameConstants.brown;
    }
  }
  
  Widget _buildSkinPreview(String skinId) {
    // Simple preview of the monkey character
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple face representation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 12,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSkinButton(
    String skinId, 
    bool isUnlocked, 
    bool isSelected, 
    bool canAfford, 
    int price,
  ) {
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'EQUIPPED',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }
    
    if (!isUnlocked) {
      if (price == 0) {
        // Free skin (default)
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: GameConstants.primaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'FREE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      } else {
        // Paid skin
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: canAfford ? GameConstants.gold : Colors.grey,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                price.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Unlocked but not selected
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: GameConstants.primaryGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'SELECT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
  }
  
  Future<void> _onSkinTapped(
    String skinId, 
    bool isUnlocked, 
    bool canAfford, 
    int price,
  ) async {
    if (skinId == _selectedSkin) return; // Already selected
    
    if (!isUnlocked) {
      if (price == 0) {
        // Free skin, just unlock and select
        await _storageService.unlockSkin(skinId);
        await _storageService.setSelectedSkin(skinId);
        await _refreshData();
      } else if (canAfford) {
        // Show purchase confirmation
        _showPurchaseDialog(skinId, price);
      } else {
        // Can't afford
        _showInsufficientCoinsDialog(price);
      }
    } else {
      // Just select the skin
      await _storageService.setSelectedSkin(skinId);
      await _refreshData();
    }
  }
  
  void _showPurchaseDialog(String skinId, int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${GameConfig.skinNames[skinId]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Do you want to purchase this skin for $price coins?'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, color: GameConstants.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$price',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: GameConstants.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _purchaseSkin(skinId, price);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GameConstants.gold,
            ),
            child: const Text('Purchase', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showInsufficientCoinsDialog(int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Coins'),
        content: Text(
          'You need $price coins to purchase this skin. Keep playing to earn more coins!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _purchaseSkin(String skinId, int price) async {
    final success = await _storageService.spendCoins(price);
    if (success) {
      await _storageService.unlockSkin(skinId);
      await _storageService.setSelectedSkin(skinId);
      await _refreshData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${GameConfig.skinNames[skinId]} purchased! 🎉'),
            backgroundColor: GameConstants.primaryGreen,
          ),
        );
      }
    }
  }
  
  Future<void> _refreshData() async {
    _totalCoins = await _storageService.getTotalCoins();
    _unlockedSkins = await _storageService.getUnlockedSkins();
    _selectedSkin = await _storageService.getSelectedSkin();
    
    if (mounted) {
      setState(() {});
    }
  }
}