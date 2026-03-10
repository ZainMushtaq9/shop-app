import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
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
  final _pinController = TextEditingController();
  String _selectedRole = 'shopkeeper'; // 'shopkeeper' or 'buyer'
  bool _isLoading = false;

  void _signup() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isUrdu ? 'تمام خانے پر کریں' : 'Please fill all fields'),
          backgroundColor: AppColors.moneyOwed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save user data locally
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_phone', _phoneController.text);
    await prefs.setString('user_pin', _pinController.text);
    await prefs.setString('user_role', _selectedRole);
    
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.isUrdu ? 'اکاؤنٹ بنائیں' : 'Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
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
                    Icon(Icons.person_add_alt_1_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: AppDimens.spacingMD),
                    Text(
                      AppStrings.isUrdu ? 'نیا اکاؤنٹ بنائیں' : 'Create New Account',
                      style: AppTextStyles.urduHeading.copyWith(color: AppColors.primary, fontSize: 22),
                    ),
                    const SizedBox(height: AppDimens.spacingXL),
                    
                    // Role Selection
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedRole = 'shopkeeper'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'shopkeeper' ? AppColors.primary : Colors.transparent,
                                border: Border.all(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.store, color: _selectedRole == 'shopkeeper' ? Colors.white : AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.isUrdu ? 'دکاندار' : 'Shopkeeper',
                                    style: AppTextStyles.urduBody.copyWith(
                                      color: _selectedRole == 'shopkeeper' ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedRole = 'buyer'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'buyer' ? AppColors.primary : Colors.transparent,
                                border: Border.all(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag, color: _selectedRole == 'buyer' ? Colors.white : AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.isUrdu ? 'گاہک' : 'Buyer',
                                    style: AppTextStyles.urduBody.copyWith(
                                      color: _selectedRole == 'buyer' ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingLG),
                    
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
                      decoration: InputDecoration(
                        labelText: AppStrings.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingMD),
                    
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: AppStrings.isUrdu ? '4 ہندسوں کا پن (PIN)' : '4-Digit PIN',
                        prefixIcon: const Icon(Icons.lock_outline),
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: AppDimens.spacingXL),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _signup,
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                AppStrings.isUrdu ? 'اکاؤنٹ بنائیں' : 'Create Account',
                                style: AppTextStyles.urduTitle.copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: AppDimens.spacingMD),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.isUrdu ? 'پہلے سے اکاؤنٹ ہے؟ ' : 'Already have an account? '),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            AppStrings.isUrdu ? 'لاگ ان' : 'Login',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
