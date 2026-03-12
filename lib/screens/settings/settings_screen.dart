import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

/// Settings screen — Branding, store type, language, security, backup, account.
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

  void _changePassword() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(AppStrings.isUrdu ? 'پاس ورڈ تبدیل کریں' : 'Change Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.isUrdu ? 'نیا پاس ورڈ' : 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.isUrdu ? 'نئے پاس ورڈ کی تصدیق' : 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isChanging ? null : () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isChanging
                  ? null
                  : () async {
                      if (newPasswordCtrl.text.trim().length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppStrings.isUrdu ? 'پاس ورڈ کم از کم 6 حروف' : 'Password must be at least 6 characters'),
                          backgroundColor: AppColors.moneyOwed,
                        ));
                        return;
                      }
                      if (newPasswordCtrl.text.trim() != confirmPasswordCtrl.text.trim()) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppStrings.isUrdu ? 'پاس ورڈ میچ نہیں ہو رہا' : 'Passwords do not match'),
                          backgroundColor: AppColors.moneyOwed,
                        ));
                        return;
                      }

                      setDialogState(() => isChanging = true);
                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService.updatePassword(newPasswordCtrl.text.trim());
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppStrings.isUrdu ? 'پاس ورڈ تبدیل ہو گیا' : 'Password changed successfully'),
                          backgroundColor: AppColors.moneyReceived,
                        ));
                      } catch (e) {
                        setDialogState(() => isChanging = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppStrings.isUrdu ? 'خرابی: $e' : 'Error: $e'),
                          backgroundColor: AppColors.moneyOwed,
                        ));
                      }
                    },
              child: isChanging
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(AppStrings.isUrdu ? 'تبدیل کریں' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewActiveSessions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.devices, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(AppStrings.isUrdu ? 'ایکٹو سیشنز' : 'Active Sessions'),
          ],
        ),
        content: FutureBuilder(
          future: _loadDeviceSessions(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            final sessions = snap.data as List<Map<String, dynamic>>? ?? [];
            if (sessions.isEmpty) {
              return Text(AppStrings.isUrdu ? 'کوئی ایکٹو سیشن نہیں' : 'No active sessions');
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sessions.length,
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  return ListTile(
                    leading: Icon(
                      s['device_name'].toString().contains('Web') ? Icons.language : Icons.phone_android,
                      color: AppColors.primary,
                    ),
                    title: Text(s['device_name'] ?? 'Unknown', style: AppTextStyles.urduBody),
                    subtitle: Text(s['device_id'] ?? '', style: const TextStyle(fontSize: 10)),
                    trailing: s['is_active'] == true
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.moneyReceived.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Active', style: TextStyle(fontSize: 10, color: AppColors.moneyReceived)),
                          )
                        : null,
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadDeviceSessions() async {
    try {
      final authService = ref.read(authServiceProvider);
      return await authService.getDeviceSessions();
    } catch (e) {
      return [];
    }
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
      final authService = ref.read(authServiceProvider);
      await authService.logout();

      if (!mounted) return;
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
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    final userEmail = user?.email ?? '';
    final userName = user?.userMetadata?['full_name'] ?? '';

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

          // ── Security ──
          _SectionHeader(AppStrings.isUrdu ? 'سیکورٹی' : 'Security'),
          Card(
            margin: const EdgeInsets.only(bottom: AppDimens.spacingLG),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'پاس ورڈ تبدیل کریں' : 'Change Password', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'اپنا پاس ورڈ اپ ڈیٹ کریں' : 'Update your password', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _changePassword,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.devices_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'ایکٹو ڈیوائسز' : 'Active Devices', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'لاگ ان شدہ ڈیوائسز دیکھیں' : 'View logged-in devices', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _viewActiveSessions,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fingerprint, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'بائیو میٹرک لاگ ان' : 'Biometric Login', style: AppTextStyles.urduBody),
                  subtitle: Text(
                    AppStrings.isUrdu ? 'صرف موبائل ایپ پر دستیاب' : 'Available on mobile app only',
                    style: AppTextStyles.caption,
                  ),
                  trailing: Switch(
                    value: false,
                    onChanged: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.isUrdu
                            ? 'بائیو میٹرک صرف موبائل ایپ پر فعال ہو گا'
                            : 'Biometric will be enabled on mobile app')),
                      );
                    },
                    activeColor: AppColors.primary,
                  ),
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
                  leading: const Icon(Icons.cloud_done_rounded, color: Colors.green),
                  title: Text(AppStrings.isUrdu ? 'سپاباس سنک' : 'Supabase Cloud Sync', style: AppTextStyles.urduBody),
                  subtitle: Text(
                    AppStrings.isUrdu ? 'تمام ڈیٹا ریئل ٹائم کلاؤڈ پر محفوظ ہے' : 'All data is saved to cloud in real-time',
                    style: TextStyle(fontSize: 12, color: AppColors.moneyReceived),
                  ),
                  trailing: const Icon(Icons.check_circle, color: AppColors.moneyReceived),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Colors.blue),
                  title: Text(AppStrings.isUrdu ? 'ڈیٹا ایکسپورٹ' : 'Export Data', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'JSON فارمیٹ میں' : 'In JSON format', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.isUrdu ? 'ایکسپورٹ جلد آ رہا ہے' : 'Export coming soon')),
                    );
                  },
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
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(userName.isNotEmpty ? userName : 'User', style: AppTextStyles.urduBody),
                  subtitle: Text(userEmail, style: AppTextStyles.caption.copyWith(color: AppColors.info)),
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
            child: Text('v3.0 — Production Build (Supabase)',
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
