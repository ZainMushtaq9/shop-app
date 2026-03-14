import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import '../../services/pdf_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {

  @override
  Widget build(BuildContext context) {
    final asyncSales = ref.watch(todaySalesListProvider);

    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'آج کی سیلز' : 'Today\'s Sales',
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _exportDailyReport(context, ref, asyncSales.valueOrNull ?? []),
          ),
        ],
      ),
      body: asyncSales.when(
        data: (sales) {
          if (sales.isEmpty) {
            return Center(
              child: Text(
                AppStrings.isUrdu ? 'آج کوئی سیلز نہیں ہوئیں' : 'No sales recorded today',
                style: AppTextStyles.urduCaption,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimens.spacingMD),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppDimens.spacingSM),
                child: ListTile(
                  title: Row(
                    children: [
                      Text(
                        '#${sale.id.substring(0, 5)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        AppFormatters.currency(sale.total),
                        style: AppTextStyles.amountSmall,
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${AppStrings.isUrdu ? "گاہک" : "Customer"}: ${sale.customerId ?? "Walk-in"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.assignment_return_rounded, color: AppColors.moneyOwed),
                    onPressed: () => _confirmReturn(context, ref, sale),
                    tooltip: AppStrings.isUrdu ? 'سیلز واپسی' : 'Sales Return',
                  ),
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD, vertical: AppDimens.spacingSM),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppDimens.spacingSM),
            child: CustomSkeleton(width: double.infinity, height: 72, borderRadius: 12),
          ),
        ),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _confirmReturn(BuildContext context, WidgetRef ref, Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.isUrdu ? 'سیلز واپسی' : 'Sales Return', style: AppTextStyles.urduTitle),
        content: Text(
          AppStrings.isUrdu
              ? 'کیا آپ اس بل کی واپسی کرنا چاہتے ہیں؟ اس سے انوینٹری اور بقایا جات برابر ہو جائیں گے۔'
              : 'Do you want to return this sale? This will restore stock and adjust customer balance.',
          style: AppTextStyles.urduBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseProvider);
              await db.deleteSale(sale.id);
              ref.invalidate(todaySalesListProvider);
              ref.invalidate(productsProvider);
              ref.invalidate(customersWithBalanceProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.isUrdu ? 'بل حذف کر دیا گیا' : 'Sale returned successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.moneyOwed),
            child: Text(AppStrings.isUrdu ? 'واپسی' : 'Return'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDailyReport(BuildContext context, WidgetRef ref, List<Sale> sales) async {
    if (sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.isUrdu ? 'کوئی سیلز نہیں ہیں' : 'No sales to export')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.isUrdu ? 'پی ڈی ایف بن رہی ہے...' : 'Generating PDF...'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final db = ref.read(databaseProvider);
      final totalSales = await db.getTodaySales();
      final totalExpenses = await db.getTodayExpenses();
      
      final prefs = await SharedPreferences.getInstance();
      final shopName = prefs.getString('app_name') ?? 'Super Business Shop';
      
      // Expected cash logically assumes opening cash is unknown here, so we just show net
      final expectedCash = totalSales - totalExpenses;

      final pdfBytes = await PdfExportService.generateDailyReport(
        shopName: shopName,
        date: DateTime.now(),
        sales: sales,
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        expectedCash: expectedCash,
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/daily_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], subject: 'Daily Report');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: AppColors.moneyOwed),
      );
    }
  }
}

final todaySalesListProvider = FutureProvider<List<Sale>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.getSalesByDate(DateTime.now());
});
