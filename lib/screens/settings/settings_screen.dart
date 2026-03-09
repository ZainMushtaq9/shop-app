import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';

/// Settings screen for App Language, Google Drive Auto Backup, 
/// Google Sheets Integration, and Print Settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingMD),
        children: [
          // ── App Settings ──
          _SectionHeader(AppStrings.isUrdu ? 'ایپ کی سیٹنگز' : 'App Settings'),
          Card(
            margin: const EdgeInsets.only(bottom: AppDimens.spacingLG),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'زبان (Language)' : 'Language (زبان)', style: AppTextStyles.urduBody),
                  trailing: Switch(
                    value: AppStrings.isUrdu,
                    onChanged: (val) {
                      AppStrings.toggleLanguage();
                      // Normally we would use riverpod to refresh the whole app language state
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.print_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'پرنٹر سیٹنگز (Bluetooth)' : 'Printer Settings (Bluetooth)', style: AppTextStyles.urduBody),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Data & Backup ──
          _SectionHeader(AppStrings.isUrdu ? 'ڈیٹا اور بیک اپ' : 'Data & Backup'),
          Card(
            margin: const EdgeInsets.only(bottom: AppDimens.spacingLG),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync_rounded, color: Colors.green),
                  title: Text(AppStrings.isUrdu ? 'گوگل شیٹس سنک (Google Sheets)' : 'Google Sheets Sync', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'منسلک نہیں' : 'Not Connected', style: const TextStyle(fontSize: 12, color: AppColors.moneyOwed)),
                  trailing: TextButton(
                    onPressed: () {},
                    child: Text(AppStrings.isUrdu ? 'منسلک کریں' : 'Connect'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_rounded, color: Colors.blue),
                  title: Text(AppStrings.isUrdu ? 'گوگل ڈرائیو بیک اپ' : 'Google Drive Auto Backup', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'ہر رات آٹو بیک اپ' : 'Nightly auto backup', style: const TextStyle(fontSize: 12)),
                  trailing: Switch(
                    value: false,
                    onChanged: (val) {},
                    activeColor: AppColors.primary,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_rounded, color: AppColors.warning),
                  title: Text(AppStrings.isUrdu ? 'پرانا ڈیٹا واپس لائیں (Restore)' : 'Restore from Backup', style: AppTextStyles.urduBody),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Profile ──
          _SectionHeader(AppStrings.isUrdu ? 'پروفائل' : 'Profile'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.store_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'دکان کی معلومات' : 'Shop Details', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'نام، پتہ اور فون نمبر' : 'Name, Address & Phone', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.moneyOwed),
                  title: Text(AppStrings.isUrdu ? 'لاگ آؤٹ' : 'Logout', style: AppTextStyles.urduBody.copyWith(color: AppColors.moneyOwed)),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.urduTitle.copyWith(
          fontSize: 14,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
