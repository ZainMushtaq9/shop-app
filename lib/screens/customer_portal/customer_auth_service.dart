import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerAuthServiceProvider = Provider((ref) => CustomerAuthService());

class CustomerAuthService {
  final _db = Supabase.instance.client;
  
  Map<String, dynamic>? _currentCustomerAccount;
  Map<String, dynamic>? get currentCustomerAccount => _currentCustomerAccount;

  bool get isAuthenticated => _db.auth.currentUser != null;
  String? get currentPhone => _db.auth.currentUser?.phone;

  Future<bool> init() async {
    if (_db.auth.currentUser != null) {
      await _loadCustomerProfile();
      return true;
    }
    return false;
  }

  Future<void> sendOtp(String phone) async {
    final formattedPhone = phone.startsWith('+') ? phone : '+$phone';
    
    // Uses Supabase's native OTP via SMS
    // Note: Twilio or another SMS provider must be configured in Supabase Dashboard
    await _db.auth.signInWithOtp(phone: formattedPhone);
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    final formattedPhone = phone.startsWith('+') ? phone : '+$phone';
    
    try {
      final res = await _db.auth.verifyOTP(
        type: OtpType.sms,
        phone: formattedPhone,
        token: otp,
      );
      
      if (res.user != null) {
        await _ensureCustomerAccountExists(res.user!.id, formattedPhone);
        await _loadCustomerProfile();
        return true;
      }
      return false;
    } catch (e) {
      print('OTP Verification error: $e');
      rethrow;
    }
  }

  Future<void> _ensureCustomerAccountExists(String authUid, String phone) async {
    try {
      // Create if not exists in our custom table
      final account = await _db.from('customer_accounts').select().eq('id', authUid).maybeSingle();
      if (account == null) {
        await _db.from('customer_accounts').insert({
          'id': authUid,
          'phone': phone,
          'login_count': 1,
          'last_login': DateTime.now().toIso8601String(),
        });
      } else {
        await _db.from('customer_accounts')
          .update({
            'login_count': (account['login_count'] as int? ?? 0) + 1, 
            'last_login': DateTime.now().toIso8601String()
          })
          .eq('id', authUid);
      }
    } catch (e) {
      print('Error ensuring customer account: $e');
    }
  }

  Future<void> _loadCustomerProfile() async {
    if (_db.auth.currentUser == null) return;
    
    try {
      final res = await _db
          .from('customer_accounts')
          .select()
          .eq('id', _db.auth.currentUser!.id)
          .maybeSingle();
          
      _currentCustomerAccount = res;
    } catch (e) {
      print('Error loading customer profile: $e');
    }
  }

  Future<void> logout() async {
    await _db.auth.signOut();
    _currentCustomerAccount = null;
  }
}
