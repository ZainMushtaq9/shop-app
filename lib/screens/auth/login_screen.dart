import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import '../buyer_dashboard/buyer_dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _pinController = TextEditingController();
  final String _correctPin = "1234"; // Default for demo
  bool _isLoading = false;

  void _login() async {
    if (_pinController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    // Simulate network/db delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin');
    final role = prefs.getString('user_role') ?? 'shopkeeper';

    if (!mounted) return;
    
    // If no pin is set in prefs, fallback to 1234
    final bool isCorrect = (savedPin != null) ? (_pinController.text == savedPin) : (_pinController.text == _correctPin);
    
    if (isCorrect) {
      if (role == 'shopkeeper') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BuyerDashboardScreen()),
        );
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isUrdu ? 'غلط پن کوڈ' : 'Invalid PIN'),
          backgroundColor: AppColors.moneyOwed,
        ),
      );
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.isUrdu ? 'پاس ورڈ بھول گئے؟' : 'Forgot Password?'),
        content: Text(
          AppStrings.isUrdu 
              ? 'اپنے رجسٹرڈ موبائل نمبر (0300-1234567) پر کوڈ بھیجنے کے لیے نیچے کلک کریں۔\n\n(ڈیمو کیلئے ڈیفالٹ پن 1234 استعمال کریں)' 
              : 'Click below to send a recovery code to your registered mobile number.\n\n(Use default PIN 1234 for demo)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.isUrdu ? 'پن کوڈ 1234 ہے' : 'Your PIN is 1234')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(AppStrings.isUrdu ? 'کوڈ بھیجو' : 'Send Code'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spacingLG),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.spacingXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_rounded, size: 64, color: AppColors.primary),
                    const SizedBox(height: AppDimens.spacingMD),
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.urduHeading.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppDimens.spacingSM),
                    Text(
                      AppStrings.isUrdu ? 'دکان میں لاگ ان کریں' : 'Login to Shop',
                      style: AppTextStyles.urduCaption,
                    ),
                    const SizedBox(height: AppDimens.spacingXL),
                    
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: InputDecoration(
                        hintText: '****',
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingLG),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                AppStrings.isUrdu ? 'لاگ ان' : 'Login',
                                style: AppTextStyles.urduTitle.copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: AppDimens.spacingMD),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _forgotPassword,
                          child: Text(
                            AppStrings.isUrdu ? 'پن بھول گئے؟' : 'Forgot PIN?',
                            style: AppTextStyles.urduBody.copyWith(color: AppColors.moneyOwed),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SignupScreen()),
                            );
                          },
                          child: Text(
                            AppStrings.isUrdu ? 'اکاؤنٹ بنائیں' : 'Create Account',
                            style: AppTextStyles.urduBody.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
