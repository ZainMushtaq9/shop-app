import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class BuyerDashboardScreen extends ConsumerStatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  ConsumerState<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends ConsumerState<BuyerDashboardScreen> {
  String _userName = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Buyer';
      _userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  void _logout() async {
    // Optionally clear prefs if they want to physically log out, wait, no, just route.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isUrdu ? 'گاہک کھاتہ' : 'Buyer Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.spacingLG),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: AppDimens.spacingMD),
                      Text(
                        _userName,
                        style: AppTextStyles.urduTitle.copyWith(fontSize: 20),
                      ),
                      Text(
                        _userPhone,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spacingLG),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.disabled),
                        const SizedBox(height: AppDimens.spacingMD),
                        Text(
                          AppStrings.isUrdu ? 'کھاتہ کی تفصیل جلد آ رہی ہے' : 'Ledger details coming soon',
                          style: AppTextStyles.urduTitle.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.isUrdu 
                            ? 'آپ کے دکاندار کا ڈیٹا یہاں شو ہوگا' 
                            : 'Your shopkeeper\'s data will appear here',
                          style: AppTextStyles.urduCaption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
