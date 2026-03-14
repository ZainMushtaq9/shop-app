import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

class PrivacyNoticeDialog extends StatelessWidget {
  const PrivacyNoticeDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PrivacyNoticeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.privacy_tip_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.isUrdu ? 'Aap ki Privacy' : 'Your Privacy',
              style: AppTextStyles.urduTitle,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.isUrdu ? 'Hum yeh data save karte hain:' : 'We collect and save:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _bulletItem(AppStrings.isUrdu ? 'Aap ka naam aur phone number' : 'Your name and phone number'),
            _bulletItem(AppStrings.isUrdu ? 'Dukaan ki location (city/market)' : 'Shop location (city/market)'),
            _bulletItem(AppStrings.isUrdu ? 'App usage patterns' : 'App usage patterns'),
            const SizedBox(height: 16),
            Text(
              AppStrings.isUrdu ? 'Kyun:' : 'Why:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _bulletItem(AppStrings.isUrdu ? 'App behtar karne ke liye' : 'To improve the app'),
            _bulletItem(AppStrings.isUrdu ? 'Relevant offers dikhane ke liye' : 'To show relevant offers'),
            const SizedBox(height: 16),
            Text(
              AppStrings.isUrdu ? 'Hum kabhi:' : 'We will NEVER:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.moneyOwed),
            ),
            const SizedBox(height: 8),
            _crossItem(AppStrings.isUrdu ? 'Aap ka data kisi ko nahi bechte' : 'Sell your data to anyone'),
            _crossItem(AppStrings.isUrdu ? 'Password nahi dekhte (encrypted hai)' : 'See your password (encrypted)'),
            _crossItem(AppStrings.isUrdu ? 'Financial data share nahi karte' : 'Share your financial data'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Declined
          child: Text(AppStrings.isUrdu ? 'Baad mein' : 'Not Now', style: const TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true), // Consented
          child: Text(AppStrings.isUrdu ? '✅ Mujhe manzoor hai' : '✅ I Agree'),
        ),
      ],
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _crossItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✗ ', style: TextStyle(color: AppColors.moneyOwed, fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
