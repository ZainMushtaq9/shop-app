import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../services/auth_service.dart';
import '../app_shell.dart';
import '../buyer_dashboard/buyer_dashboard_screen.dart';
import '../../core/services/marketing_service.dart';
import 'privacy_notice_dialog.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _shopNameController = TextEditingController();

  String _selectedRole = 'shopkeeper';
  int _currentStep = 0; // 0=info, 1=email OTP verify
  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.moneyOwed),
    );
  }

  void _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirm = _passwordConfirmController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      _showError(AppStrings.isUrdu ? 'تمام خانے پر کریں' : 'Please fill all fields');
      return;
    }

    if (password != passwordConfirm) {
      _showError(AppStrings.isUrdu ? 'پاس ورڈ میچ نہیں ہو رہا' : 'Passwords do not match');
      return;
    }

    if (password.length < 6) {
      _showError(AppStrings.isUrdu ? 'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے' : 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: email,
        password: password,
        fullName: name,
        phone: phone,
        shopName: _shopNameController.text.trim(),
        role: _selectedRole,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 1; // Move to OTP verification step
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isUrdu 
            ? 'ای میل پر OTP بھیج دیا گیا ہے' 
            : 'OTP sent to your email!'),
          backgroundColor: AppColors.info,
        ),
      );

    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError(AppStrings.isUrdu ? 'OTP درج کریں' : 'Enter OTP');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyEmailOtp(_emailController.text.trim(), otp);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isUrdu ? 'اکاؤنٹ بن گیا!' : 'Account Created Successfully!'),
          backgroundColor: AppColors.moneyReceived,
        ),
      );

      // Route based on role
      if (_selectedRole == 'shopkeeper') {
        final consented = await PrivacyNoticeDialog.show(context) ?? false;

        await MarketingService.saveShopkeeperProfile(
          userId: authService.currentUser!.id,
          shopData: {
            'owner_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'shop_name': _shopNameController.text.trim(),
            'shop_type': 'general',
            'market': '',
            'city': '',
            'province': '',
          },
        );

        try {
          await MarketingService.supabase.from('marketing_profiles').update({
            'marketing_opted': consented,
          }).eq('user_id', authService.currentUser!.id);
        } catch (_) {}

        if (!mounted) return;
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
      _showError(AppStrings.isUrdu ? 'غلط OTP' : 'Invalid OTP or expired');
    }
  }

  Widget _roleChip(String value, IconData icon, String label) {
    bool selected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.urduBody.copyWith(color: selected ? Colors.white : AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoStep() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.person_add_alt_1_rounded, size: 40, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.spacingSM),
        Text(
          AppStrings.isUrdu ? 'نیا اکاؤنٹ بنائیں' : 'Create New Account',
          style: AppTextStyles.urduHeading.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppDimens.spacingLG),

        // Role selector
        Row(
          children: [
            _roleChip('shopkeeper', Icons.store, AppStrings.isUrdu ? 'دکاندار' : 'Shopkeeper'),
            const SizedBox(width: 12),
            _roleChip('buyer', Icons.shopping_bag, AppStrings.isUrdu ? 'گاہک' : 'Buyer'),
          ],
        ),
        const SizedBox(height: AppDimens.spacingMD),

        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: AppStrings.isUrdu ? 'پورا نام' : 'Full Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: AppDimens.spacingMD),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: AppStrings.isUrdu ? 'ای میل درکار ہے' : 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: AppDimens.spacingMD),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          decoration: InputDecoration(
            labelText: AppStrings.isUrdu ? 'موبائل نمبر (03...)' : 'Mobile Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            counterText: '',
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
        const SizedBox(height: AppDimens.spacingMD),
        
        TextField(
          controller: _passwordConfirmController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: AppStrings.isUrdu ? 'پاس ورڈ کی تصدیق' : 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        if (_selectedRole == 'shopkeeper') ...[
          const SizedBox(height: AppDimens.spacingMD),
          TextField(
            controller: _shopNameController,
            decoration: InputDecoration(
              labelText: AppStrings.isUrdu ? 'دکان کا نام' : 'Shop Name',
              prefixIcon: const Icon(Icons.storefront_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],

        const SizedBox(height: AppDimens.spacingXL),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _signUp,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(AppStrings.isUrdu ? 'اکاؤنٹ بنائیں' : 'Sign Up', style: AppTextStyles.urduBody.copyWith(color: Colors.white)),
          ),
        ),

        const SizedBox(height: AppDimens.spacingMD),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppStrings.isUrdu ? 'پہلے سے اکاؤنٹ ہے؟ ' : 'Already have an account? ', 
                 style: AppTextStyles.urduCaption),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.isUrdu ? 'لاگ ان کریں' : 'Login Here',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.info),
        const SizedBox(height: AppDimens.spacingSM),
        Text(
          AppStrings.isUrdu ? 'ای میل کی تصدیق' : 'Email Verification',
          style: AppTextStyles.urduHeading.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.isUrdu
              ? '${_emailController.text} پر بھیجا گیا کوڈ درج کریں'
              : 'Enter the code sent to ${_emailController.text}',
          style: AppTextStyles.urduCaption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.spacingLG),

        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 8,
          style: const TextStyle(fontSize: 28, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            hintText: '........',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: AppDimens.spacingLG),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _verifyOtp,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: Text(AppStrings.isUrdu ? 'تصدیق کریں' : 'Verify', style: AppTextStyles.urduBody.copyWith(color: Colors.white)),
          ),
        ),
        const SizedBox(height: AppDimens.spacingMD),
        TextButton(
          onPressed: _isLoading ? null : () async {
            setState(() => _isLoading = true);
            try {
              final authService = ref.read(authServiceProvider);
              await authService.resendOtp(_emailController.text.trim());
              if (!mounted) return;
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.isUrdu ? 'نیا کوڈ بھیج دیا گیا ہے' : 'New OTP sent to email'),
                  backgroundColor: AppColors.info,
                ),
              );
            } catch (e) {
              setState(() => _isLoading = false);
              _showError(e.toString());
            }
          },
          child: Text(
            AppStrings.isUrdu ? 'کوڈ نہیں ملا؟ دوبارہ بھیجیں' : 'Didn\'t receive OTP? Resend',
            style: AppTextStyles.urduBody.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [AppColors.primary.withOpacity(0.2), AppColors.darkBackground, AppColors.darkBackground]
              : [AppColors.primary.withOpacity(0.1), AppColors.lightBackground, AppColors.primary.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingLG, vertical: AppDimens.spacingMD),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
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
                    children: [
                      if (_currentStep == 0) _buildInfoStep(),
                      if (_currentStep == 1) _buildOtpStep(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
