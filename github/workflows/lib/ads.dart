import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Keep true while developing (Google's official test ads).
/// Set to false and fill in your real ad unit IDs before publishing.
const bool kUseTestAds = true;

bool get adsSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class AdIds {
  static String get banner {
    if (Platform.isAndroid) {
      return kUseTestAds
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'YOUR_ANDROID_BANNER_ID';
    }
    return kUseTestAds
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'YOUR_IOS_BANNER_ID';
  }

  static String get interstitial {
    if (Platform.isAndroid) {
      return kUseTestAds
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'YOUR_ANDROID_INTERSTITIAL_ID';
    }
    return kUseTestAds
        ? 'ca-app-pub-3940256099942544/4411468910'
        : 'YOUR_IOS_INTERSTITIAL_ID';
  }
}

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _interstitial;

  Future<void> init() async {
    if (!adsSupported) return;
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Call only at natural breaks (e.g. after the user has seen a result).
  void showInterstitial() {
    final ad = _interstitial;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
    _interstitial = null;
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!adsSupported) return;
    _banner = BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!adsSupported || !_loaded || _banner == null) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
