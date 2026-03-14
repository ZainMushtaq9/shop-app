import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'customer_auth_service.dart';
import 'portal_dashboard_screen.dart';

class PortalLoginScreen extends ConsumerStatefulWidget {
  const PortalLoginScreen({super.key});

  @override
  ConsumerState<PortalLoginScreen> createState() => _PortalLoginScreenState();
}

class _PortalLoginScreenState extends ConsumerState<PortalLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.isUrdu ? 'درست فون نمبر درج کریں' : 'Enter valid phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(customerAuthServiceProvider);
      await authService.sendOtp(phone);
      
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isUrdu ? 'او ٹی پی بھیج دیا گیا ہے' : 'OTP sent successfully'),
          backgroundColor: AppColors.moneyReceived,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isUrdu ? 'مسئلہ: $e' : 'Error: $e'),
          backgroundColor: AppColors.moneyOwed,
        ),
      );
    }
  }

  void _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    
    if (otp.length < 4) return;

    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(customerAuthServiceProvider);
      final success = await authService.verifyOtp(phone, otp);
      
      if (!mounted) return;
      
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PortalDashboardScreen()),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.isUrdu ? 'غلط او ٹی پی' : 'Invalid OTP'),
            backgroundColor: AppColors.moneyOwed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.moneyOwed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final urdu = AppStrings.isUrdu;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or Icon
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person_outline_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
                
                // Welcome Text
                Text(
                  urdu ? 'خوش آمدید' : 'Welcome to Customer Portal',
                  style: AppTextStyles.urduTitle.copyWith(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  urdu 
                    ? 'اپنا حساب دیکھنے کے لیے موبائل نمبر درج کریں' 
                    : 'Enter your mobile number to view your accounts',
                  style: AppTextStyles.urduBody.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Phone Input
                TextField(
                  controller: _phoneController,
                  enabled: !_otpSent && !_isLoading,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18, letterSpacing: 2),
                  decoration: InputDecoration(
                    labelText: urdu ? 'موبائل نمبر 03...' : 'Mobile Number',
                    prefixIcon: const Icon(Icons.phone_android_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  // OTP Input
                  TextField(
                    controller: _otpController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: urdu ? 'او ٹی پی کوڈ درج کریں' : 'Enter OTP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                        ? null 
                        : (_otpSent ? _verifyOtp : _sendOtp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _otpSent 
                              ? (urdu ? 'تصدیق کریں' : 'Verify OTP') 
                              : (urdu ? 'او ٹی پی بھیجیں' : 'Send OTP'),
                            style: AppTextStyles.urduTitle.copyWith(color: Colors.white),
                          ),
                  ),
                ),
                
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () => setState(() => _otpSent = false),
                    child: Text(urdu ? 'نمبر تبدیل کریں' : 'Change number'),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
