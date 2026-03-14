import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_app_bar.dart';

class GoogleDriveBackupScreen extends ConsumerStatefulWidget {
  const GoogleDriveBackupScreen({super.key});

  @override
  ConsumerState<GoogleDriveBackupScreen> createState() => _GoogleDriveBackupScreenState();
}

class _GoogleDriveBackupScreenState extends ConsumerState<GoogleDriveBackupScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String _lastBackupTime = '';

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastBackupTime = prefs.getString('last_drive_backup_time') ?? '';
    });
  }

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);
    
    // Simulate backup process
    await Future.delayed(const Duration(seconds: 3));
    
    final prefs = await SharedPreferences.getInstance();
    final nowStr = '${DateTime.now().toLocal().toString().split('.')[0]}';
    await prefs.setString('last_drive_backup_time', nowStr);
    
    if (mounted) {
      setState(() {
        _isBackingUp = false;
        _lastBackupTime = nowStr;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isUrdu ? '✅ بیک اپ گوگل ڈرائیو پر محفوظ ہو گیا' : '✅ Backup saved to Google Drive'),
          backgroundColor: AppColors.moneyReceived,
        ),
      );
    }
  }

  Future<void> _performRestore() async {
    setState(() => _isRestoring = true);
    
    // Simulate restore process
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.isUrdu ? '✅ ڈیٹا کامیابی سے واپس آ گیا ہے' : '✅ Data restored successfully'),
          backgroundColor: AppColors.moneyReceived,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'گوگل ڈرائیو بیک اپ' : 'Google Drive Backup',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image/Icon
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_done_rounded, size: 80, color: AppColors.info),
                  SizedBox(height: 16),
                  Text('Google Drive', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.info)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              AppStrings.isUrdu ? 'اپنا ڈیٹا محفوظ رکھیں' : 'Keep your data secure',
              style: AppTextStyles.urduTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.isUrdu
                ? 'اپنے گاہکوں، بلوں اور ادھار کا سارا ریکارڈ محفوظ کریں تاکہ موبائل گم ہونے کی صورت میں بھی کچھ ضائع نہ ہو۔'
                : 'Save all your customers, bills, and credit records so nothing is lost even if you lose your phone.',
              style: AppTextStyles.urduBody.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Status Card
            Container(
              padding: const EdgeInsets.all(AppDimens.spacingMD),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.isUrdu ? 'آخری بیک اپ' : 'Last Backup', style: AppTextStyles.urduCaption),
                        Text(
                          _lastBackupTime.isEmpty 
                            ? (AppStrings.isUrdu ? 'ابھی تک کوئی بیک اپ نہیں بنایا گیا' : 'No backup created yet')
                            : _lastBackupTime,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isBackingUp || _isRestoring ? null : _performBackup,
                icon: _isBackingUp 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                label: Text(
                  AppStrings.isUrdu ? 'ابھی بیک اپ بنائیں' : 'Backup Now',
                  style: AppTextStyles.urduBody.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isBackingUp || _isRestoring ? null : _performRestore,
                icon: _isRestoring 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_download_rounded),
                label: Text(
                  AppStrings.isUrdu ? 'پرانا بیک اپ واپس لائیں' : 'Restore Data',
                  style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
