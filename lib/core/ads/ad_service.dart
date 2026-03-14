import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdService {
  // ── AD UNIT IDs ──────────────────────────────────────
  // TEST IDs (use during development)
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';

  // REAL IDs (replace after AdMob approval)
  static const _realBannerAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _realBannerIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const _realAppIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';

  static bool _useTestAds = true; // Set to false in production

  static String get _bannerId {
    if (_useTestAds) {
      return Platform.isIOS ? _testBannerIOS : _testBannerAndroid;
    }
    return Platform.isIOS ? _realBannerIOS : _realBannerAndroid;
  }

  // ── INIT ─────────────────────────────────────────────
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      // Set test device IDs in development if needed
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: ['YOUR_TEST_DEVICE_ID']),
      );
    } catch (e) {
      debugPrint('Error initializing MobileAds: $e');
    }
  }

  // ── CREATE BANNER ────────────────────────────────────
  static BannerAd createBanner({
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  }) {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner, // 320x50 - smallest, least intrusive
      request: const AdRequest(
        keywords: ['pakistan', 'business', 'shop', 'kiryana', 'retail', 'accounting'],
      ),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Ad failed to load: $error');
          ad.dispose();
          onFailed();
        },
        onAdClicked: (ad) {
          logAdEvent('clicked', 'banner');
        },
      ),
    )..load();
  }

  // ── LOG AD EVENT TO SUPABASE ─────────────────────────
  static Future<void> logAdEvent(String event, String type) async {
    try {
      await Supabase.instance.client.from('ad_events').insert({
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'ad_type': type,
        'event_type': event,
        'device_type': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to log ad event: $e');
    }
  }

  // ── SHOULD SHOW AD ───────────────────────────────────
  static bool shouldShowAd(String? plan) {
    if (plan == 'pro' || plan == 'business') return false;
    return true;
  }
}
