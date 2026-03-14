import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOnline = true;
  bool _showOnlineFlash = false;
  Timer? _flashTimer;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    
    _subscription = ConnectivityService.instance.onlineStream.listen((isOnline) {
      if (mounted) {
        if (isOnline && !_isOnline) {
          // Came back online
          setState(() {
            _isOnline = true;
            _showOnlineFlash = true;
          });
          _flashTimer?.cancel();
          _flashTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _showOnlineFlash = false);
            }
          });
        } else if (!isOnline && _isOnline) {
          // Went offline
          setState(() {
            _isOnline = false;
            _showOnlineFlash = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && !_showOnlineFlash) {
      return const SizedBox.shrink();
    }

    final bgColor = _isOnline ? AppColors.moneyReceived : AppColors.moneyOwed;
    final icon = _isOnline ? Icons.cloud_done_rounded : Icons.wifi_off_rounded;
    final text = _isOnline 
        ? (AppStrings.isUrdu ? '✅ انٹرنیٹ آ گیا — ڈیٹا منتقلی شروع' : '✅ Back online — Syncing data')
        : (AppStrings.isUrdu ? '📵 انٹرنیٹ نہیں ہے — سب محفوظ ہو رہا ہے' : '📵 No internet — Working offline');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
