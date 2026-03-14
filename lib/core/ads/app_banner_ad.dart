import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/app_providers.dart';
import 'ad_service.dart';

class AppBannerAd extends ConsumerStatefulWidget {
  final String screenName;
  const AppBannerAd({super.key, required this.screenName});

  @override
  ConsumerState<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends ConsumerState<AppBannerAd> {
  BannerAd? _banner;
  bool _isLoaded = false;
  bool _isDismissed = false; // User closed it

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return; // Web uses AdSense directly or handled separately
    
    // Future expansion: check user plan using Riverpod subscriptionProvider
    // final sub = ref.read(subscriptionProvider);
    // if (!AdService.shouldShowAd(sub.plan)) return;
    
    _banner = AdService.createBanner(
      onLoaded: () {
        if (mounted) setState(() => _isLoaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _isLoaded = false);
      },
    );
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide if: dismissed, not loaded, or on web
    if (_isDismissed || !_isLoaded || kIsWeb) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 58, // 50px ad + 8px padding
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── THE AD BANNER ───────────────────────────
          Positioned.fill(
            child: Container(
              color: const Color(0xFFFAFAFA),
              child: Center(
                child: AdWidget(ad: _banner!),
              ),
            ),
          ),

          // ── BIG CLOSE BUTTON (top right) ────────────
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                setState(() => _isDismissed = true);
                AdService.logAdEvent('closed', 'banner_${widget.screenName}');
              },
              child: Container(
                width: 44, // Minimum 44x44 touch target
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // ── "AD" LABEL (top left — transparency) ────
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'Ad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
