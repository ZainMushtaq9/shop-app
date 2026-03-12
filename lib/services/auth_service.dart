import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Get current user session
  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;

  /// Sign up with Email and Password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? shopName,
    String role = 'shopkeeper',
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'shop_name': shopName,
        'role': role,
      },
    );
    // Note: Supabase will automatically send an email verification OTP if enabled in the dashboard.
  }

  /// Verify Email OTP (sent during signup or requested later)
  Future<AuthResponse> verifyEmailOtp(String email, String token) async {
    return await _supabase.auth.verifyOTP(
      type: OtpType.signup, // or OtpType.email based on use case
      email: email,
      token: token,
    );
  }

  /// Login with Email and Password
  Future<AuthResponse> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // Manage device sessions if mobile
    if (!kIsWeb && response.user != null) {
      await _registerDeviceSession(response.user!.id);
    }
    
    return response;
  }

  /// Request Password Reset OTP
  Future<void> requestPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Update password (after verifying reset OTP or while logged in)
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Logout
  Future<void> logout() async {
    if (!kIsWeb && currentUser != null) {
      // Invalidate current device session in DB before signing out securely
      final deviceId = await _getDeviceId();
      try {
        await _supabase.from('device_sessions').delete().match({
          'user_id': currentUser!.id,
          'device_id': deviceId,
        });
      } catch (e) {
        // Ignore delete errors on logout to ensure user still gets logged out of the app
      }
    }
    await _supabase.auth.signOut();
  }

  // --- Device Management ---

  Future<String> _getDeviceId() async {
    if (kIsWeb) return 'web-browser';
    
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return info.id;
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'unknown-ios-device';
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      return info.deviceId;
    }
    return 'unknown-device';
  }

  Future<String> _getDeviceName() async {
    if (kIsWeb) return 'Web Browser';
    
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return '${info.manufacturer} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.name;
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      return info.computerName;
    }
    return 'Unknown Device';
  }

  Future<void> _registerDeviceSession(String userId) async {
    final deviceId = await _getDeviceId();
    final deviceName = await _getDeviceName();

    // The UNIQUE(user_id, device_id) on the database ensures we only have 1 active session per device for a user.
    // If we want ONLY ONE mobile device per account total, we could instead delete all existing sessions for this user first.
    // Let's implement strict "One Account = One Mobile Device" based on the exact user request:
    
    try {
      // Delete all existing sessions for this user to enforce single-device rule
      await _supabase.from('device_sessions').delete().eq('user_id', userId);
      
      // Insert new session
      await _supabase.from('device_sessions').insert({
        'user_id': userId,
        'device_id': deviceId,
        'device_name': deviceName,
        'is_active': true,
      });
    } catch (e) {
      print('Failed to register device session: $e');
    }
  }

  /// Check if current device is the active session
  /// Returns true if valid, false if user was logged out from another device
  Future<bool> validateCurrentDeviceSession() async {
    if (kIsWeb || currentUser == null) return true; // Web doesn't enforce device limit in this model
    
    try {
      final deviceId = await _getDeviceId();
      final response = await _supabase
          .from('device_sessions')
          .select('is_active')
          .eq('user_id', currentUser!.id)
          .eq('device_id', deviceId)
          .maybeSingle();
          
      if (response == null) return false;
      return response['is_active'] == true;
    } catch (e) {
      return true; // Fail open if DB is unreachable to avoid accidental logouts
    }
  }
  /// Get all active device sessions for the current user
  Future<List<Map<String, dynamic>>> getDeviceSessions() async {
    if (currentUser == null) return [];
    try {
      final data = await _supabase
          .from('device_sessions')
          .select()
          .eq('user_id', currentUser!.id);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }
}
