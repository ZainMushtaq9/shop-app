import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
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
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      _showError(AppStrings.isUrdu ? 'فون نمبر اور پن درج کریں' : 'Enter phone and PIN');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final user = await db.getUserByPhone(phone);

      if (!mounted) return;

      if (user == null) {
        setState(() => _isLoading = false);
        _showError(AppStrings.isUrdu ? 'یہ نمبر رجسٹرڈ نہیں ہے' : 'This number is not registered');
        return;
      }

      if (user['pin'] != pin) {
        setState(() => _isLoading = false);
        _showError(AppStrings.isUrdu ? 'غلط پن کوڈ' : 'Invalid PIN');
        return;
      }

      // Save current session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_name', user['name'] as String);
      await prefs.setString('user_role', user['role'] as String);
      await prefs.setString('user_id', user['id'] as String);

      if (!mounted) return;

      final role = user['role'] as String;
      if (role == 'shopkeeper') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BuyerDashboardScreen()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(AppStrings.isUrdu ? 'لاگ ان میں خرابی' : 'Login error');
    }
  }

  void _forgotPin() {
    final forgotPhoneController = TextEditingController();
    final forgotOtpController = TextEditingController();
    final forgotNewPinController = TextEditingController();
    String generatedOtp = '';
    int step = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                step == 0 ? Icons.phone : step == 1 ? Icons.sms : Icons.lock_reset,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                step == 0
                    ? (AppStrings.isUrdu ? 'فون نمبر درج کریں' : 'Enter Phone')
                    : step == 1
                        ? (AppStrings.isUrdu ? 'OTP درج کریں' : 'Enter OTP')
                        : (AppStrings.isUrdu ? 'نیا پن' : 'New PIN'),
                style: AppTextStyles.urduTitle.copyWith(fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (step == 0) ...[
                Text(
                  AppStrings.isUrdu
                      ? 'اپنا رجسٹرڈ فون نمبر درج کریں'
                      : 'Enter your registered phone number',
                  style: AppTextStyles.urduCaption,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: forgotPhoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: InputDecoration(
                    labelText: AppStrings.isUrdu ? 'فون نمبر' : 'Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              if (step == 1) ...[
                Text(
                  AppStrings.isUrdu
                      ? '${forgotPhoneController.text} پر بھیجا گیا OTP درج کریں'
                      : 'Enter OTP sent to ${forgotPhoneController.text}',
                  style: AppTextStyles.urduCaption,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: forgotOtpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              if (step == 2) ...[
                Text(
                  AppStrings.isUrdu ? 'نیا 4 ہندسوں کا پن درج کریں' : 'Enter new 4-digit PIN',
                  style: AppTextStyles.urduCaption,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: forgotNewPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (step == 0) {
                  // Verify phone exists
                  final db = ref.read(databaseProvider);
                  final user = await db.getUserByPhone(forgotPhoneController.text.trim());
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.isUrdu ? 'یہ نمبر رجسٹرڈ نہیں ہے' : 'Number not registered'),
                        backgroundColor: AppColors.moneyOwed,
                      ),
                    );
                    return;
                  }
                  generatedOtp = forgotPhoneController.text.trim().substring(
                      forgotPhoneController.text.trim().length - 4);
                  setDialogState(() => step = 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.isUrdu
                          ? 'OTP بھیج دیا: $generatedOtp (ڈیمو)'
                          : 'OTP sent: $generatedOtp (demo)'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                } else if (step == 1) {
                  if (forgotOtpController.text.trim() != generatedOtp) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.isUrdu ? 'غلط OTP' : 'Invalid OTP'),
                        backgroundColor: AppColors.moneyOwed,
                      ),
                    );
                    return;
                  }
                  setDialogState(() => step = 2);
                } else if (step == 2) {
                  if (forgotNewPinController.text.trim().length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.isUrdu ? '4 ہندسے درکار' : '4 digits required'),
                        backgroundColor: AppColors.moneyOwed,
                      ),
                    );
                    return;
                  }
                  final db = ref.read(databaseProvider);
                  await db.updateUserPin(
                    forgotPhoneController.text.trim(),
                    forgotNewPinController.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.isUrdu ? 'پن تبدیل ہو گیا!' : 'PIN updated!'),
                      backgroundColor: AppColors.moneyReceived,
                    ),
                  );
                }
              },
              child: Text(
                step == 2
                    ? (AppStrings.isUrdu ? 'محفوظ کریں' : 'Save')
                    : (AppStrings.isUrdu ? 'اگلا' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.moneyOwed),
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

                    // Phone number field
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      decoration: InputDecoration(
                        labelText: AppStrings.isUrdu ? 'موبائل نمبر' : 'Mobile Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingMD),

                    // PIN field
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: InputDecoration(
                        labelText: AppStrings.isUrdu ? 'پن کوڈ' : 'PIN Code',
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
                          onPressed: _forgotPin,
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
