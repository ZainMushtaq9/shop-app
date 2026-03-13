import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';

class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSales = ref.watch(todaySalesListProvider);

    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'آج کی سیلز' : 'Today\'s Sales',
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
}

final todaySalesListProvider = FutureProvider<List<Sale>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.getSalesByDate(DateTime.now());
});
