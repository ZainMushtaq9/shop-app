import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Reports & Analytics screen. Accessible from bottom nav tab "رپورٹس" (Reports).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.reports),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Sales Report
            _ReportCard(
              title: AppStrings.isUrdu ? 'آج کی سیلز اور منافع' : 'Today\'s Sales & Profit',
              subtitle: AppStrings.isUrdu ? 'آج کی مکمل رپورٹ دیکھیں اور پی ڈی ایف بنائیں' : 'View today\'s full report and export to PDF',
              icon: Icons.today_rounded,
              color: AppColors.primary,
              onTap: () {},
            ),
            const SizedBox(height: AppDimens.spacingMD),

            // Weekly/Monthly Trends
            _ReportCard(
              title: AppStrings.isUrdu ? 'ہفتہ وار / ماہانہ رجحانات' : 'Weekly / Monthly Trends',
              subtitle: AppStrings.isUrdu ? 'پچھلے 7 یا 30 دنوں کا گرافیکل جائزہ' : 'Graphical overview of last 7 or 30 days',
              icon: Icons.auto_graph_rounded,
              color: AppColors.moneyReceived,
              onTap: () {},
            ),
            const SizedBox(height: AppDimens.spacingMD),

            // Low Stock Report
            _ReportCard(
              title: AppStrings.lowStockAlerts,
              subtitle: AppStrings.isUrdu ? 'وہ تمام اشیاء جو ختم ہونے والی ہیں' : 'All items that are running out of stock',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              onTap: () {},
            ),
            const SizedBox(height: AppDimens.spacingMD),

            // Customer Ledgers Export
            _ReportCard(
              title: AppStrings.isUrdu ? 'گاہکوں کے کھاتے ایکسل میں' : 'Customer Ledgers to Excel',
              subtitle: AppStrings.isUrdu ? 'تمام گاہکوں کا بیلنس ایک ساتھ ڈاؤنلوڈ کریں' : 'Download all customers balances at once',
              icon: Icons.file_download_rounded,
              color: Colors.green.shade600,
              onTap: () {},
            ),
            const SizedBox(height: AppDimens.spacingMD),
            
            // Supplier Ledgers Export
            _ReportCard(
              title: AppStrings.isUrdu ? 'سپلائرز کے کھاتے ایکسل میں' : 'Supplier Ledgers to Excel',
              subtitle: AppStrings.isUrdu ? 'سپلیئرز کا ریکارڈ ایکسل فارمیٹ میں نکالیں' : 'Export suppliers records in Excel format',
              icon: Icons.file_upload_rounded,
              color: Colors.blue.shade600,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spacingLG),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppDimens.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.urduTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.disabled),
          ],
        ),
      ),
    );
  }
}
