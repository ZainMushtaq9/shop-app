import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../widgets/global_app_bar.dart';
import 'sync_status_screen.dart';
import '../../utils/export_helper.dart';
import 'customer_portal_qr_screen.dart';
import 'whatsapp_queue_screen.dart';
import 'backup_screen.dart';

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
      appBar: GlobalAppBar(title: AppStrings.settings),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingMD),
        children: [
          // ── Branding ──
          _SectionHeader(AppStrings.isUrdu ? 'برانڈنگ' : 'Branding'),
          _SettingsCard(
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
          _SettingsCard(
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
                  leading: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'گاہک پورٹل QR' : 'Customer Portal QR', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'گاہکوں کے لیے سکین کوڈ' : 'Scan code for customers', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerPortalQRScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.outbox_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'آف لائن واٹس ایپ قطار' : 'Offline WhatsApp Queue', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'قطار میں موجود پیغامات دکھائیں' : 'Show pending messages', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatsAppQueueScreen()));
                  },
                ),
              ],
            ),
          ),

          // ── Security ──
          _SectionHeader(AppStrings.isUrdu ? 'سیکورٹی' : 'Security'),
          _SettingsCard(
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
          _SettingsCard(
            margin: const EdgeInsets.only(bottom: AppDimens.spacingLG),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'ڈیٹا منتقلی کی کیفیت' : 'Sync Status', style: AppTextStyles.urduBody),
                  subtitle: Text(
                    AppStrings.isUrdu ? 'آف لائن ڈیٹا اور قطار دیکھیں' : 'View offline pending items',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SyncStatusScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'ڈیٹا ایکسپورٹ' : 'Export Data', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'تمام ڈیٹا JSON فارمیٹ میں ایکسپورٹ' : 'Export all data in JSON format', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.cloud_download_outlined, color: AppColors.primary),
                  onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.isUrdu ? 'ایکسپورٹ ہو رہا ہے...' : 'Preparing export...')),
                    );
                    try {
                      await ExportHelper.exportLocalDataAsJson();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.isUrdu ? 'ایکسپورٹ ناکام: $e' : 'Export failed: $e'), backgroundColor: AppColors.moneyOwed),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
                  title: Text(AppStrings.isUrdu ? 'گوگل ڈرائیو بیک اپ' : 'Google Drive Backup', style: AppTextStyles.urduBody),
                  subtitle: Text(AppStrings.isUrdu ? 'کلاؤڈ پر محفوظ کریں' : 'Save to cloud backup', style: AppTextStyles.caption),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GoogleDriveBackupScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Account ──
          _SectionHeader(AppStrings.isUrdu ? 'اکاؤنٹ' : 'Account'),
          _SettingsCard(
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

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const _SettingsCard({
    required this.child,
    this.margin = const EdgeInsets.only(bottom: AppDimens.spacingLG),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}
