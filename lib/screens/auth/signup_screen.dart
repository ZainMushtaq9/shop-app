import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../app_shell.dart';
import '../buyer_dashboard/buyer_dashboard_screen.dart';

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
        Icon(Icons.person_add_alt_1_rounded, size: 48, color: AppColors.primary),
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
    // Watch language changes so the entire screen rebuilds
    final isUrdu = ref.watch(isUrduProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.isUrdu ? 'نیا اکاؤنٹ' : 'Create Account'),
        backgroundColor: AppColors.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                AppStrings.setUrdu(!isUrdu);
                ref.read(isUrduProvider.notifier).state = !isUrdu;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      isUrdu ? 'EN' : 'اردو',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spacingLG),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
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
    );
  }
}
