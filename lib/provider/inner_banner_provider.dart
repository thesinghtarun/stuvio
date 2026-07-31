import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InlineBannerProvider extends ChangeNotifier {
  BannerAd? _banner;
  bool _isLoaded = false;

  BannerAd? get banner => _banner;
  bool get isLoaded => _isLoaded;

  /// Returns true if this index should display an ad.
  /// Ads appear after every 4 items:
  /// 0 1 2 3 [Ad] 4 5 6 7 [Ad]
  bool isAdIndex(int index) {
    return (index + 1) % 5 == 0;
  }

  /// Converts the list index (with ads) into the
  /// actual data index.
  int getRealIndex(int index) {
    return index - (index ~/ 5);
  }

  /// Total number of widgets in the ListView
  /// (data items + inserted ads).
  int getItemCount(int dataLength) {
    if (dataLength <= 4) return dataLength;

    final adCount = dataLength ~/ 4;
    return dataLength + adCount;
  }

  void loadBanner() {
    if (_banner != null) return;

    _banner = BannerAd(
      size: AdSize.mediumRectangle,
      adUnitId: 'ca-app-pub-1345393972469011/3049217586',
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
          _isLoaded = false;
          notifyListeners();
        },
      ),
    )..load();
  }

  void disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _isLoaded = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeBanner();
    super.dispose();
  }
}
