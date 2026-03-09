import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import 'customer_detail_screen.dart';

/// Customer list screen showing all buyers with their balance.
/// Balance shown in RED if customer owes, GREEN if customer has advance.
class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCustomers = ref.watch(customersWithBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.customers),
      ),
      body: Column(
        children: [
          // Total Receivable header
          Consumer(
            builder: (context, ref, _) {
              final asyncTotal = ref.watch(totalReceivableProvider);
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppDimens.spacingMD),
                padding: const EdgeInsets.all(AppDimens.spacingMD),
                decoration: BoxDecoration(
                  gradient: AppColors.payableGradient,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                ),
                child: Column(
                  children: [
                    Text(
                      AppStrings.totalReceivable,
                      style: AppTextStyles.urduCaption.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    asyncTotal.when(
                      data: (total) => Text(
                        AppStrings.formatAmount(total),
                        style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
                      ),
                      loading: () => const CircularProgressIndicator(color: Colors.white54),
                      error: (_, __) => Text('Rs. 0',
                          style: AppTextStyles.amountLarge.copyWith(color: Colors.white54)),
                    ),
                  ],
                ),
              );
            },
          ),

          // Customer list
          Expanded(
            child: asyncCustomers.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 80, color: AppColors.disabled),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.isUrdu ? 'ابھی کوئی گاہک نہیں' : 'No customers yet',
                          style: AppTextStyles.urduTitle.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final data = customers[index];
                    final customer = Customer.fromMap(data);
                    final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppDimens.spacingSM),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spacingMD,
                          vertical: AppDimens.spacingSM,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: balance > 0
                              ? AppColors.moneyOwed.withOpacity(0.1)
                              : AppColors.moneyReceived.withOpacity(0.1),
                          radius: 24,
                          child: Icon(
                            Icons.person_rounded,
                            color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: customer.phone.isNotEmpty
                            ? Text(customer.phone, style: AppTextStyles.caption)
                            : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.currency(balance.abs()),
                              style: AppTextStyles.amountSmall.copyWith(
                                color: balance > 0
                                    ? AppColors.moneyOwed
                                    : balance < 0
                                        ? AppColors.moneyReceived
                                        : AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              balance > 0
                                  ? (AppStrings.isUrdu ? 'باقی' : 'Owed')
                                  : balance < 0
                                      ? (AppStrings.isUrdu ? 'پیشگی' : 'Advance')
                                      : (AppStrings.isUrdu ? 'صاف' : 'Clear'),
                              style: TextStyle(
                                fontSize: 11,
                                color: balance > 0
                                    ? AppColors.moneyOwed
                                    : balance < 0
                                        ? AppColors.moneyReceived
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(customer: customer),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.error)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustomerDialog(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          AppStrings.addCustomer,
          style: AppTextStyles.urduBody.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _addCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.addCustomer, style: AppTextStyles.urduTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: AppTextStyles.urduBody,
              decoration: InputDecoration(
                labelText: AppStrings.customerName,
                labelStyle: AppTextStyles.urduCaption,
                prefixIcon: const Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppStrings.phone,
                labelStyle: AppTextStyles.urduCaption,
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final db = ref.read(databaseProvider);
              final customer = Customer(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
              );
              await db.insertCustomer(customer);
              ref.invalidate(customersWithBalanceProvider);
              ref.invalidate(customersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
