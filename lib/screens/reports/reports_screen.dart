import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_providers.dart';
import '../../utils/constants.dart';
import 'daily_report_screen.dart';
import 'munafa_nuqsan_screen.dart';
import 'trends_report_screen.dart';
import 'low_stock_screen.dart';
import '../../core/ads/app_banner_ad.dart';
import '../../core/ads/adsense_widget.dart';
import 'package:flutter/foundation.dart';

/// Reports & Analytics screen — all cards linked to REAL working screens.
/// ZERO "Coming Soon" — every card opens a real functional screen.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── AD BANNER ──
            kIsWeb ? const AdSenseWidget(adSlot: 'reports_top') : const AppBannerAd(screenName: 'reports'),
            const SizedBox(height: AppDimens.spacingMD),

            // Munafa Nuqsan (P&L)
            _ReportCard(
              title: AppStrings.isUrdu ? 'منافع نقصان / Munafa Nuqsan' : 'Profit & Loss',
              subtitle: AppStrings.isUrdu ? 'کتنا بکا، کتنا خرچ، کتنا فائدہ' : 'Sales, expenses, and net profit',
              icon: Icons.trending_up_rounded,
              color: AppColors.moneyReceived,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MunafaNuqsanScreen()),
                );
              },
            ),
            const SizedBox(height: AppDimens.spacingMD),

            // Daily Sales Report
            _ReportCard(
              title: AppStrings.isUrdu ? 'آج کی سیلز اور منافع' : 'Today\'s Sales & Profit',
              subtitle: AppStrings.isUrdu ? 'آج کی مکمل رپورٹ دیکھیں اور پی ڈی ایف بنائیں' : 'View today\'s full report and export to PDF',
              icon: Icons.today_rounded,
              color: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyReportScreen()),
                );
              },
            ),
            const SizedBox(height: AppDimens.spacingMD),

            // Weekly/Monthly Trends
            _ReportCard(
              title: AppStrings.isUrdu ? 'ہفتہ وار / ماہانہ رجحانات' : 'Weekly / Monthly Trends',
              subtitle: AppStrings.isUrdu ? 'پچھلے 7 یا 30 دنوں کا گرافیکل جائزہ' : 'Graphical overview of last 7 or 30 days',
              icon: Icons.auto_graph_rounded,
              color: AppColors.info,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrendsReportScreen()),
                );
              },
            ),
            const SizedBox(height: AppDimens.spacingMD),

            // Low Stock Report
            _ReportCard(
              title: AppStrings.lowStockAlerts,
              subtitle: AppStrings.isUrdu ? 'وہ تمام اشیاء جو ختم ہونے والی ہیں' : 'All items that are running out of stock',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LowStockScreen()),
                );
              },
            ),
            const SizedBox(height: AppDimens.spacingMD),

            // Customer Ledgers Export
            _ReportCard(
              title: AppStrings.isUrdu ? 'گاہکوں کے کھاتے ایکسل میں' : 'Customer Ledgers to Excel',
              subtitle: AppStrings.isUrdu ? 'تمام گاہکوں کا بیلنس ایک ساتھ ڈاؤنلوڈ کریں' : 'Download all customers balances at once',
              icon: Icons.file_download_rounded,
              color: Colors.green.shade600,
              onTap: () => _exportCustomerLedger(context, ref),
            ),
            const SizedBox(height: AppDimens.spacingMD),
            
            // Supplier Ledgers Export
            _ReportCard(
              title: AppStrings.isUrdu ? 'سپلائرز کے کھاتے ایکسل میں' : 'Supplier Ledgers to Excel',
              subtitle: AppStrings.isUrdu ? 'سپلیئرز کا ریکارڈ ایکسل فارمیٹ میں نکالیں' : 'Export suppliers records in Excel format',
              icon: Icons.file_upload_rounded,
              color: AppColors.primary,
              onTap: () => _exportSupplierLedger(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCustomerLedger(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.isUrdu ? 'ڈاؤنلوڈ ہو رہا ہے...' : 'Downloading...'),
        backgroundColor: AppColors.moneyReceived,
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      final db = ref.read(databaseProvider);
      final customers = await db.getAllCustomers();
      
      final StringBuffer csv = StringBuffer();
      csv.writeln('Name,Phone,Balance');
      
      for (final c in customers) {
        final name = c.name.replaceAll(',', ' ');
        final phone = c.phone.replaceAll(',', ' ');
        final balance = await db.getCustomerBalance(c.id);
        csv.writeln('$name,$phone,$balance');
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/customers_ledger.csv');
      await file.writeAsString(csv.toString());
      
      await Share.shareXFiles([XFile(file.path)], subject: 'Customers Ledger');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)
        );
      }
    }
  }

  Future<void> _exportSupplierLedger(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.isUrdu ? 'ڈاؤنلوڈ ہو رہا ہے...' : 'Downloading...'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      final db = ref.read(databaseProvider);
      final suppliers = await db.getAllSuppliers();
      
      final StringBuffer csv = StringBuffer();
      csv.writeln('Name,Phone,Balance');
      
      for (final s in suppliers) {
        final name = s.name.replaceAll(',', ' ');
        final phone = s.phone.replaceAll(',', ' ');
        final balance = await db.getSupplierBalance(s.id);
        csv.writeln('$name,$phone,$balance');
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/suppliers_ledger.csv');
      await file.writeAsString(csv.toString());
      
      await Share.shareXFiles([XFile(file.path)], subject: 'Suppliers Ledger');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)
        );
      }
    }
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
