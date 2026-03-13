```
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/global_app_bar.dart'; // Added this import
import '../app_shell.dart';
import 'signup_screen.dart';
import '../buyer_dashboard/buyer_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.moneyOwed),
    );
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(AppStrings.isUrdu ? 'ای میل اور پاس ورڈ درج کریں' : 'Enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.login(email, password);

      if (!mounted) return;

      if (response.user == null) {
        setState(() => _isLoading = false);
        _showError(AppStrings.isUrdu ? 'لاگ ان ناکام رہا' : 'Login failed');
        return;
      }

      // Check device session validity across login (enforces single active mobile device)
      final isValidSession = await authService.validateCurrentDeviceSession();
      if (!isValidSession) {
        setState(() => _isLoading = false);
        _showError(AppStrings.isUrdu ? 'یہ اکاؤنٹ کسی اور ڈیوائس پر لاگ ان ہے' : 'Account active on another device');
        await authService.logout();
        return;
      }

      // Route based on role from metadata
      final role = response.user!.userMetadata?['role'] ?? 'shopkeeper';
      
      if (role == 'shopkeeper') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BuyerDashboardScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      _showError(e.message);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(AppStrings.isUrdu ? 'لاگ ان میں خرابی' : 'Login error');
    }
  }

  void _forgotPassword() {
    final forgotEmailController = TextEditingController();
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(AppStrings.isUrdu ? 'پاس ورڈ بھول گئے؟' : 'Forgot Password?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.isUrdu
                    ? 'اپنا ای میل درج کریں، ہم آپ کو پاس ورڈ تبدیل کرنے کا لنک بھیجیں گے۔'
                    : 'Enter your email, we will send you a password reset link.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: forgotEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppStrings.isUrdu ? 'ای میل' : 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isResetting ? null : () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.isUrdu ? 'منسوخ' : 'Cancel', style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isResetting
                  ? null
                  : () async {
                      if (forgotEmailController.text.trim().isEmpty) return;
                      setDialogState(() => isResetting = true);
                      
                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService.requestPasswordReset(forgotEmailController.text.trim());
                        
                        if (!mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.isUrdu 
                                ? 'ری سیٹ لنک ای میل کر دیا گیا ہے' 
                                : 'Reset link emailed successfully'),
                            backgroundColor: AppColors.moneyReceived,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isResetting = false);
                        _showError(AppStrings.isUrdu ? 'خرابی' : 'Error sending reset link');
                      }
                    },
              child: isResetting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(AppStrings.isUrdu ? 'بھیجیں' : 'Send Link'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch language changes so the entire screen rebuilds
    ref.watch(isUrduProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'لاگ ان کریں' : 'Login',
      ),
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
                    // Logo Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.storefront, size: 64, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppDimens.spacingSM),
                    Text(
                      AppStrings.isUrdu ? 'سپر بزنس میں خوش آمدید' : 'Welcome to Super Business',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.urduHeading.copyWith(fontSize: 22, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.isUrdu ? 'لاگ ان کریں اور اپنا کاروبار سنبھالیں' : 'Login to manage your shop',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.urduCaption.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: AppDimens.spacingXL),

                    // Login Form
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: AppStrings.isUrdu ? 'ای میل' : 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingMD),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.isUrdu ? 'پاس ورڈ' : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingSM),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          AppStrings.isUrdu ? 'پاس ورڈ بھول گئے؟' : 'Forgot Password?',
                          style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingMD),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : _login,
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.login),
                        label: Text(
                          AppStrings.isUrdu ? 'لاگ ان کریں' : 'Login',
                          style: AppTextStyles.urduHeading.copyWith(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimens.spacingXL),

                    // Sign up Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.isUrdu ? 'اکاؤنٹ نہیں ہے؟ ' : 'Don\'t have an account? ',
                          style: AppTextStyles.urduBody.copyWith(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SignupScreen()),
                            );
                          },
                          child: Text(
                            AppStrings.isUrdu ? 'نیا اکاؤنٹ بنائیں' : 'Sign Up Here',
                            style: AppTextStyles.urduBody.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
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
