import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketingService {
  static SupabaseClient get supabase => Supabase.instance.client;

  // Collect and save complete user profile
  static Future<void> saveShopkeeperProfile({
    required String userId,
    required Map<String, dynamic> shopData,
  }) async {
    // Get location
    final position = await _getLocation();

    try {
      await supabase.from('shopkeeper_profiles').upsert({
        'user_account_id': userId,
        'owner_name': shopData['owner_name'],
        'primary_phone': shopData['phone'],
        'email': shopData['email'],
        'shop_name': shopData['shop_name'],
        'shop_type': shopData['shop_type'],
        'market_name': shopData['market'],
        'city': shopData['city'],
        'province': shopData['province'],
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'app_install_date': DateTime.now().toIso8601String(),
        'marketing_opted': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Also save to marketing_profiles
      await supabase.from('marketing_profiles').upsert({
        'user_id': userId,
        'user_type': 'shopkeeper',
        'full_name': shopData['owner_name'],
        'phone_primary': shopData['phone'],
        'email': shopData['email'],
        'city': shopData['city'],
        'province': shopData['province'],
        'market_name': shopData['market'],
        'shop_type': shopData['shop_type'],
        'language_pref': shopData['language'] ?? 'ur',
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'device_type': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
      });
    } catch (e) {
      debugPrint('Failed to save shopkeeper marketing profile: $e');
    }
  }

  // Save customer profile when added by shopkeeper
  static Future<void> saveCustomerProfile({
    required String customerName,
    required String phone,
    required String shopCity,
  }) async {
    try {
      // Check if customer already exists
      final existing = await supabase
          .from('customer_profiles')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('customer_profiles').insert({
          'full_name': customerName,
          'phone': phone,
          'city': shopCity,
          'created_at': DateTime.now().toIso8601String(),
        });

        await supabase.from('marketing_profiles').insert({
          'user_type': 'customer',
          'full_name': customerName,
          'phone_primary': phone,
          'city': shopCity,
        });
      }
    } catch (e) {
      debugPrint('Failed to save customer marketing profile: $e');
    }
  }

  // Track app session
  static Future<void> trackSession(String userId) async {
    try {
      await supabase.from('marketing_profiles')
          .update({
            'last_active': DateTime.now().toIso8601String(),
            'total_sessions': supabase.rpc('increment', params: {'row_id': userId, 'col': 'total_sessions'}),
            'last_login': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Marketing service track session failed (table might be missing or RLS): $e');
    }
  }

  // Get location (with permission)
  static Future<Position?> _getLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // Save location when user opens app
  static Future<void> updateLocation(String userId) async {
    final pos = await _getLocation();
    if (pos == null) return;

    try {
      await supabase.from('marketing_profiles')
          .update({
            'latitude': pos.latitude,
            'longitude': pos.longitude,
          })
          .eq('user_id', userId);
    } catch (_) {}
  }
}
