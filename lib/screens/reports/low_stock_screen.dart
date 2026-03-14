import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import '../../models/models.dart';

/// Low Stock Report — shows products running low.
/// Simple list: name, current stock, alert threshold.
class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'کم اسٹاک والی اشیاء' : 'Low Stock Items',
      ),
      body: lowStockAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD, vertical: AppDimens.spacingSM),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppDimens.spacingSM),
            child: CustomSkeleton(width: double.infinity, height: 72, borderRadius: 12),
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.moneyOwed),
              const SizedBox(height: 12),
              Text(AppStrings.isUrdu ? 'کچھ غلط ہوا۔ دوبارہ کوشش کریں' : 'Something went wrong. Try again'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(lowStockProductsProvider),
                child: Text(AppStrings.isUrdu ? 'دوبارہ' : 'Retry'),
              ),
            ],
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✅', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.isUrdu ? 'سب اسٹاک ٹھیک ہے!' : 'All stock levels are good!',
                    style: AppTextStyles.urduTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.isUrdu ? 'کوئی بھی چیز کم نہیں ہے' : 'No items are running low',
                    style: AppTextStyles.urduCaption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Alert banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppDimens.spacingMD),
                padding: const EdgeInsets.all(AppDimens.spacingMD),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.isUrdu
                              ? '${products.length} اشیاء کم ہو رہی ہیں'
                              : '${products.length} items running low',
                            style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            AppStrings.isUrdu
                              ? 'یہ چیزیں منگوانی چاہیں'
                              : 'These items need to be reordered',
                            style: AppTextStyles.urduCaption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Products list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final isZero = p.stockQuantity <= 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppDimens.spacingSM),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isZero ? AppColors.moneyOwed.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                          child: Icon(
                            isZero ? Icons.error_rounded : Icons.warning_rounded,
                            color: isZero ? AppColors.moneyOwed : AppColors.warning,
                          ),
                        ),
                        title: Text(p.nameUrdu.isNotEmpty ? p.nameUrdu : p.nameEnglish, style: AppTextStyles.urduBody),
                        subtitle: Text(
                          AppStrings.isUrdu
                            ? 'موجودہ اسٹاک: ${p.stockQuantity.toInt()}'
                            : 'Current stock: ${p.stockQuantity.toInt()}',
                          style: TextStyle(
                            color: isZero ? AppColors.moneyOwed : AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isZero ? AppColors.moneyOwed : AppColors.warning,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isZero
                              ? (AppStrings.isUrdu ? 'ختم' : 'OUT')
                              : (AppStrings.isUrdu ? 'کم' : 'LOW'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
