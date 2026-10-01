import 'package:flutter/material.dart';

/// Temporary version without ads, used to check that the app opens.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  Future<void> init() async {}

  void showInterstitial() {}
}

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: 50);
}
