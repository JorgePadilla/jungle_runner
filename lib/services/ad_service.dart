import 'dart:io';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';

/// Service to handle AdMob integration
class AdService {
  static AdService? _instance;
  AdService._internal();
  
  static AdService get instance {
    _instance ??= AdService._internal();
    return _instance!;
  }
  
  bool _isInitialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;
  
  /// Initialize the Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await MobileAds.instance.initialize();
    _isInitialized = true;
    
    // Pre-load ads
    _loadInterstitialAd();
    _loadRewardedAd();
  }
  
  /// Get platform-specific banner ad unit ID
  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return AdConstants.testBannerId;
    } else if (Platform.isIOS) {
      return AdConstants.testBannerId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  /// Get platform-specific interstitial ad unit ID
  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return AdConstants.testInterstitialId;
    } else if (Platform.isIOS) {
      return AdConstants.testInterstitialId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  /// Get platform-specific rewarded ad unit ID
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return AdConstants.testRewardedId;
    } else if (Platform.isIOS) {
      return AdConstants.testRewardedId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  /// Create and load banner ad
  BannerAd createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('Banner ad opened');
        },
        onAdClosed: (ad) {
          print('Banner ad closed');
        },
      ),
    );
    
    return _bannerAd!;
  }
  
  /// Load interstitial ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          print('Interstitial ad loaded successfully');
          
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialLoaded = false;
          _interstitialAd = null;
          
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }
  
  /// Show interstitial ad
  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (!_isInterstitialLoaded || _interstitialAd == null) {
      print('Interstitial ad not ready');
      onAdClosed?.call();
      return;
    }
    
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('Interstitial ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('Interstitial ad dismissed');
        ad.dispose();
        _isInterstitialLoaded = false;
        _interstitialAd = null;
        
        // Load next ad
        _loadInterstitialAd();
        
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Interstitial ad failed to show: $error');
        ad.dispose();
        _isInterstitialLoaded = false;
        _interstitialAd = null;
        
        // Load next ad
        _loadInterstitialAd();
        
        onAdClosed?.call();
      },
    );
    
    _interstitialAd!.show();
  }
  
  /// Load rewarded ad
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          print('Rewarded ad loaded successfully');
          
          _rewardedAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _isRewardedLoaded = false;
          _rewardedAd = null;
          
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }
  
  /// Show rewarded ad
  Future<void> showRewardedAd({
    required Function(RewardItem reward) onRewarded,
    VoidCallback? onAdClosed,
  }) async {
    if (!_isRewardedLoaded || _rewardedAd == null) {
      print('Rewarded ad not ready');
      onAdClosed?.call();
      return;
    }
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('Rewarded ad dismissed');
        ad.dispose();
        _isRewardedLoaded = false;
        _rewardedAd = null;
        
        // Load next ad
        _loadRewardedAd();
        
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Rewarded ad failed to show: $error');
        ad.dispose();
        _isRewardedLoaded = false;
        _rewardedAd = null;
        
        // Load next ad
        _loadRewardedAd();
        
        onAdClosed?.call();
      },
    );
    
    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      onRewarded(reward);
    });
  }
  
  /// Check if interstitial ad is ready
  bool get isInterstitialReady => _isInterstitialLoaded && _interstitialAd != null;
  
  /// Check if rewarded ad is ready
  bool get isRewardedReady => _isRewardedLoaded && _rewardedAd != null;
  
  /// Dispose all ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    
    _isInterstitialLoaded = false;
    _isRewardedLoaded = false;
  }
}