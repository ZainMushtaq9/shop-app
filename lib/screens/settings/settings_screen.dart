import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

/// Settings screen — App branding, store type, language, printer, backup.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appName = 'Super Business Shop';
  String _storeType = 'general';
  bool _isUrdu = AppStrings.isUrdu;

  final List<Map<String, String>> _storeTypes = [
    {'key': 'general', 'ur': 'جنرل اسٹور', 'en': 'General Store'},
    {'key': 'grocery', 'ur': 'کریانہ اسٹور', 'en': 'Grocery Store'},
    {'key': 'medical', 'ur': 'میڈیکل اسٹور', 'en': 'Medical Store'},
    {'key': 'departmental', 'ur': 'ڈیپارٹمنٹل اسٹور', 'en': 'Departmental Store'},
    {'key': 'vegetable', 'ur': 'سبزی فروش', 'en': 'Vegetable Shop'},
    {'key': 'fruit', 'ur': 'پھل فروش', 'en': 'Fruit Shop'},
    {'key': 'electronics', 'ur': 'الیکٹرانکس', 'en': 'Electronics'},
    {'key': 'clothing', 'ur': 'کپڑے کی دکان', 'en': 'Clothing Store'},
    {'key': 'bakery', 'ur': 'بیکری', 'en': 'Bakery'},
    {'key': 'restaurant', 'ur': 'ریستوران', 'en': 'Restaurant'},
    {'key': 'hardware', 'ur': 'ہارڈویئر', 'en': 'Hardware Store'},
    {'key': 'stationery', 'ur': 'اسٹیشنری', 'en': 'Stationery Store'},
    {'key': 'other', 'ur': 'دیگر', 'en': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appName = prefs.getString('app_name') ?? 'Super Business Shop';
      _storeType = prefs.getString('store_type') ?? 'general';
    });
  }

  Future<void> _saveAppName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_name', name);
    setState(() => _appName = name);
  }

  Future<void> _saveStoreType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_type', type);
    setState(() => _storeType = type);
  }

  void _editAppName() {
    final controller = TextEditingController(text: _appName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppStrings.isUrdu ? 'ایپ / برانڈ کا نام' : 'App / Brand Name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppStrings.isUrdu ? 'اپنی دکان کا نام لکھیں' : 'Enter your shop/brand name',
            prefixIcon: const Icon(Icons.edit),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _saveAppName(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _selectStoreType() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppStrings.isUrdu ? 'دکان کی قسم' : 'Store Type'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _storeTypes.length,
            itemBuilder: (_, i) {
              final type = _storeTypes[i];
              final isSelected = _storeType == type['key'];
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppColors.moneyReceived : AppColors.disabled,
                ),
                title: Text(
                  AppStrings.isUrdu ? type['ur']! : type['en']!,
                  style: AppTextStyles.urduBody.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  _saveStoreType(type['key']!);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.isUrdu ? 'لاگ آؤٹ؟' : 'Logout?'),
        content: Text(AppStrings.isUrdu ? 'کیا آپ لاگ آؤٹ کرنا چاہتے ہیں؟' : 'Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.moneyOwed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.isUrdu ? 'لاگ آؤٹ' : 'Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String get _storeTypeLabel {
    final type = _storeTypes.firstWhere((t) => t['key'] == _storeType, orElse: () => _storeTypes[0]);
    return AppStrings.isUrdu ? type['ur']! : type['en']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingMD),
        children: [
          // ── Branding ──
          _SectionHeader(AppStrings.isUrdu ? 'برانڈنگ' : 'Branding'),
          Card(
            margin: const EdgeInsets.only(bottom: AppDimens.spacingLG),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'ایپ / برانڈ کا نام' : 'App / Brand Name', style: AppTextStyles.urduBody),
                  subtitle: Text(_appName, style: AppTextStyles.caption.copyWith(color: AppColors.info)),
                  trailing: const Icon(Icons.edit_rounded, size: 20),
                  onTap: _editAppName,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'دکان کی قسم' : 'Store Type', style: AppTextStyles.urduBody),
                  subtitle: Text(_storeTypeLabel, style: AppTextStyles.caption.copyWith(color: AppColors.info)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _selectStoreType,
                ),
              ],
            ),
          ),

          // ── App Settings ──
          _SectionHeader(AppStrings.isUrdu ? 'ایپ کی سیٹنگز' : 'App Settings'),
          Card(
            margin: const EdgeInsets.only(bottom: AppDimens.spacingLG),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'زبان (Language)' : 'Language (زبان)', style: AppTextStyles.urduBody),
                  subtitle: Text(_isUrdu ? 'اردو' : 'English', style: AppTextStyles.caption),
                  trailing: Switch(
                    value: _isUrdu,
                    onChanged: (val) {
                      AppStrings.setUrdu(val);
                      setState(() => _isUrdu = val);
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.print_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'پرنٹر سیٹنگز' : 'Printer Settings', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'بلوٹوتھ / USB پرنٹر' : 'Bluetooth / USB Printer', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.isUrdu ? 'پرنٹر سیٹ اپ جلد آ رہا ہے' : 'Printer setup coming soon')),
                    );
                  },
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
                  title: Text(AppStrings.isUrdu ? 'گوگل شیٹس سنک' : 'Google Sheets Sync', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'منسلک نہیں' : 'Not Connected',
                      style: TextStyle(fontSize: 12, color: AppColors.moneyOwed)),
                  trailing: TextButton(
                    onPressed: () {},
                    child: Text(AppStrings.isUrdu ? 'منسلک کریں' : 'Connect'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_rounded, color: Colors.blue),
                  title: Text(AppStrings.isUrdu ? 'گوگل ڈرائیو بیک اپ' : 'Google Drive Backup', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'ہر رات آٹو بیک اپ' : 'Nightly auto backup',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Switch(value: false, onChanged: (val) {}, activeColor: AppColors.primary),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_rounded, color: AppColors.warning),
                  title: Text(AppStrings.isUrdu ? 'بحالی (Restore)' : 'Restore from Backup', style: AppTextStyles.urduBody),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Account ──
          _SectionHeader(AppStrings.isUrdu ? 'اکاؤنٹ' : 'Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'پروفائل' : 'Profile', style: AppTextStyles.urduBody),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.moneyOwed),
                  title: Text(AppStrings.isUrdu ? 'لاگ آؤٹ' : 'Logout',
                      style: AppTextStyles.urduBody.copyWith(color: AppColors.moneyOwed)),
                  onTap: _logout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text('v2.0 — Built with ❤️ for Pakistani Shopkeepers',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
      child: Text(title, style: AppTextStyles.urduTitle.copyWith(fontSize: 14, color: AppColors.primary)),
    );
  }
}
