import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../app_shell.dart';
import '../buyer_dashboard/buyer_dashboard_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();
  final _otpController = TextEditingController();
  final _shopNameController = TextEditingController();

  String _selectedRole = 'shopkeeper';
  int _currentStep = 0; // 0=info, 1=OTP, 2=PIN
  bool _isLoading = false;
  String _generatedOtp = '';

  String? _validatePhone(String phone) {
    if (phone.isEmpty) return AppStrings.isUrdu ? 'فون نمبر درج کریں' : 'Enter phone number';
    if (phone.length != 11) return AppStrings.isUrdu ? '11 ہندسے درکار ہیں' : 'Must be 11 digits';
    if (!phone.startsWith('03')) return AppStrings.isUrdu ? '03 سے شروع ہونا چاہیے' : 'Must start with 03';
    return null;
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    final phoneError = _validatePhone(phone);
    if (_nameController.text.trim().isEmpty) {
      _showError(AppStrings.isUrdu ? 'نام درج کریں' : 'Enter your name');
      return;
    }
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    setState(() => _isLoading = true);

    // Check if phone already registered
    final db = ref.read(databaseProvider);
    final exists = await db.isPhoneRegistered(phone);
    if (exists) {
      setState(() => _isLoading = false);
      _showError(AppStrings.isUrdu
          ? 'یہ نمبر پہلے سے رجسٹرڈ ہے'
          : 'This phone is already registered');
      return;
    }

    // Generate OTP (free simulation: last 4 digits of phone)
    _generatedOtp = phone.substring(phone.length - 4);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _currentStep = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.isUrdu
            ? 'OTP بھیج دیا گیا: $_generatedOtp (ڈیمو)'
            : 'OTP sent: $_generatedOtp (demo)'),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _verifyOtp() {
    if (_otpController.text.trim() != _generatedOtp) {
      _showError(AppStrings.isUrdu ? 'غلط OTP' : 'Invalid OTP');
      return;
    }
    setState(() => _currentStep = 2);
  }

  void _createAccount() async {
    final pin = _pinController.text.trim();
    final pinConfirm = _pinConfirmController.text.trim();

    if (pin.length != 4) {
      _showError(AppStrings.isUrdu ? '4 ہندسوں کا پن درج کریں' : 'Enter 4-digit PIN');
      return;
    }
    if (pin != pinConfirm) {
      _showError(AppStrings.isUrdu ? 'پن میچ نہیں ہو رہا' : 'PINs do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final userId = const Uuid().v4();
      await db.insertUser({
        'id': userId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'pin': pin,
        'role': _selectedRole,
        'shop_name': _shopNameController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isUrdu ? 'اکاؤنٹ بن گیا!' : 'Account Created!'),
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
      _showError(AppStrings.isUrdu ? 'اکاؤنٹ بنانے میں خرابی' : 'Error creating account');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.moneyOwed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.isUrdu ? 'نیا اکاؤنٹ' : 'Create Account'),
        backgroundColor: AppColors.primary,
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
                    // Step indicator
                    _buildStepIndicator(),
                    const SizedBox(height: AppDimens.spacingLG),

                    if (_currentStep == 0) _buildInfoStep(),
                    if (_currentStep == 1) _buildOtpStep(),
                    if (_currentStep == 2) _buildPinStep(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepCircle(0, AppStrings.isUrdu ? 'معلومات' : 'Info'),
        Expanded(child: Container(height: 2, color: _currentStep >= 1 ? AppColors.primary : AppColors.disabled)),
        _stepCircle(1, 'OTP'),
        Expanded(child: Container(height: 2, color: _currentStep >= 2 ? AppColors.primary : AppColors.disabled)),
        _stepCircle(2, 'PIN'),
      ],
    );
  }

  Widget _stepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isActive ? AppColors.primary : AppColors.disabled,
          child: Text('${step + 1}', style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontSize: 13)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppColors.primary : AppColors.textSecondary)),
      ],
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
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          decoration: InputDecoration(
            labelText: AppStrings.isUrdu ? 'موبائل نمبر (03...)' : 'Mobile Number (03...)',
            prefixIcon: const Icon(Icons.phone_outlined),
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: AppDimens.spacingMD),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: AppStrings.isUrdu ? 'ای میل (اختیاری)' : 'Email (optional)',
            prefixIcon: const Icon(Icons.email_outlined),
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
            onPressed: _isLoading ? null : _sendOtp,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(AppStrings.isUrdu ? 'OTP بھیجیں' : 'Send OTP', style: AppTextStyles.urduBody.copyWith(color: Colors.white)),
          ),
        ),

        const SizedBox(height: AppDimens.spacingMD),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppStrings.isUrdu ? 'پہلے سے اکاؤنٹ ہے؟ ' : 'Already have an account? '),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.isUrdu ? 'لاگ ان' : 'Login', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleChip(String role, IconData icon, String label) {
    final selected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildOtpStep() {
    return Column(
      children: [
        Icon(Icons.sms_outlined, size: 48, color: AppColors.info),
        const SizedBox(height: AppDimens.spacingSM),
        Text(
          AppStrings.isUrdu ? 'OTP تصدیق' : 'OTP Verification',
          style: AppTextStyles.urduHeading.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.isUrdu
              ? '${_phoneController.text} پر بھیجا گیا 4 ہندسوں کا کوڈ درج کریں'
              : 'Enter the 4-digit code sent to ${_phoneController.text}',
          style: AppTextStyles.urduCaption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.spacingLG),

        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 4,
          style: const TextStyle(fontSize: 28, letterSpacing: 12),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • •',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
            onPressed: _verifyOtp,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(AppStrings.isUrdu ? 'تصدیق کریں' : 'Verify', style: AppTextStyles.urduBody.copyWith(color: Colors.white)),
          ),
        ),
        const SizedBox(height: AppDimens.spacingSM),
        TextButton(
          onPressed: _sendOtp,
          child: Text(
            AppStrings.isUrdu ? 'دوبارہ بھیجیں' : 'Resend OTP',
            style: TextStyle(color: AppColors.info),
          ),
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    return Column(
      children: [
        Icon(Icons.lock_outline, size: 48, color: AppColors.moneyReceived),
        const SizedBox(height: AppDimens.spacingSM),
        Text(
          AppStrings.isUrdu ? 'پن سیٹ کریں' : 'Set Your PIN',
          style: AppTextStyles.urduHeading.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppDimens.spacingLG),

        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          textAlign: TextAlign.center,
          maxLength: 4,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: InputDecoration(
            labelText: AppStrings.isUrdu ? '4 ہندسوں کا پن' : '4-Digit PIN',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: AppDimens.spacingMD),

        TextField(
          controller: _pinConfirmController,
          keyboardType: TextInputType.number,
          obscureText: true,
          textAlign: TextAlign.center,
          maxLength: 4,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: InputDecoration(
            labelText: AppStrings.isUrdu ? 'پن دوبارہ درج کریں' : 'Confirm PIN',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: AppDimens.spacingXL),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.moneyReceived,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _createAccount,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(
              AppStrings.isUrdu ? 'اکاؤنٹ بنائیں' : 'Create Account',
              style: AppTextStyles.urduBody.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
