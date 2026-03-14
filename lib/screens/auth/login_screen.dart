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
import '../../core/services/marketing_service.dart';

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

      // Record Marketing Session
      MarketingService.trackSession(response.user!.id);
      MarketingService.updateLocation(response.user!.id);
      
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
              Image.asset('assets/logo.png', width: 32, height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.lock_reset, color: AppColors.primary)),
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
    ref.watch(isUrduProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlobalAppBar(
        title: '',
        showMenu: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingLG, vertical: AppDimens.spacingMD),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Header
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.storefront_outlined, size: 56, color: AppColors.primary),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingMD),
                    Text(
                      'حساب کرو',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.urduHeading.copyWith(
                        fontSize: 40,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HisaabKaro',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingXL),

                    // Login Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface.withOpacity(0.7) : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppDimens.spacingXL),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Custom Tab Header
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppColors.primary, width: 2)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppStrings.isUrdu ? 'لاگ ان' : 'Login',
                                      style: AppTextStyles.title.copyWith(fontSize: 14, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, width: 2)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppStrings.isUrdu ? 'تصدیق' : 'Verify',
                                      style: AppTextStyles.title.copyWith(
                                        fontSize: 14, 
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.spacingXL),
                          
                          // Email Input
                          Text(
                            AppStrings.isUrdu ? 'ای میل' : 'Email',
                            style: AppTextStyles.label.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'email@example.com',
                              prefixIcon: const Icon(Icons.mail_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: AppDimens.spacingMD),

                          // Password Input
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.isUrdu ? 'پاس ورڈ' : 'Password',
                                style: AppTextStyles.label.copyWith(fontSize: 14),
                              ),
                              InkWell(
                                onTap: _forgotPassword,
                                child: Text(
                                  AppStrings.isUrdu ? 'بھول گئے؟' : 'Forgot?',
                                  style: AppTextStyles.label.copyWith(fontSize: 12, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: AppDimens.spacingXL),

                          // Login Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              shadowColor: AppColors.primary.withOpacity(0.5),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppStrings.isUrdu ? 'لاگ ان کریں' : 'Login',
                                        style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: AppDimens.spacingLG),
                          
                          // Sign up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.isUrdu ? 'اکاؤنٹ نہیں ہے؟ ' : 'Don\'t have an account? ',
                                style: AppTextStyles.body.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                                  );
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                child: Text(
                                  AppStrings.isUrdu ? 'نیا اکاؤنٹ بنائیں' : 'Sign Up',
                                  style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingLG),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Privacy Policy', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        const SizedBox(width: 16),
                        Text('Terms of Service', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        const SizedBox(width: 16),
                        Text('Support', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ],
                    )
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
