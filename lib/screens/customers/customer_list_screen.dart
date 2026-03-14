import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/skeleton_loader.dart';
import 'customer_detail_screen.dart';
import '../../core/services/marketing_service.dart';

/// Customer list screen showing all buyers with their balance.
/// Balance shown in RED if customer owes, GREEN if customer has advance.
class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCustomers = ref.watch(customersWithBalanceProvider);

    return Scaffold(
      body: Column(
        children: [
          // Total Receivable header
          Consumer(
            builder: (context, ref, _) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppDimens.spacingMD),
                padding: const EdgeInsets.all(AppDimens.spacingLG),
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
                child: Column(
                  children: [
                    Text(
                      AppStrings.totalReceivable,
                      style: AppTextStyles.urduCaption.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 8),
                    asyncTotal.when(
                      data: (total) => Text(
                        AppStrings.formatAmount(total),
                        style: AppTextStyles.amountLarge.copyWith(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      loading: () => const CircularProgressIndicator(color: AppColors.primary),
                      error: (_, __) => Text('Rs. 0',
                          style: AppTextStyles.amountLarge.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
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
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimens.spacingSM),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                      ),
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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.name,
                                style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                              onPressed: () => _editCustomerDialog(context, ref, customer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.moneyOwed),
                              onPressed: () => _deleteCustomer(context, ref, customer),
                            ),
                          ],
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
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingSM, horizontal: AppDimens.spacingMD),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppDimens.spacingSM),
                  child: CustomSkeleton(width: double.infinity, height: 72, borderRadius: 12),
                ),
              ),
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
              maxLength: 11,
              decoration: InputDecoration(
                labelText: AppStrings.isUrdu ? 'فون (03...)' : 'Phone (03...)',
                labelStyle: AppTextStyles.urduCaption,
                prefixIcon: const Icon(Icons.phone_rounded),
                counterText: '',
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.isUrdu ? 'نام درج کریں' : 'Enter name'),
                    backgroundColor: AppColors.moneyOwed,
                  ),
                );
                return;
              }
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty && (phone.length != 11 || !phone.startsWith('03'))) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.isUrdu ? 'فون نمبر غلط ہے (11 ہندسے، 03 سے شروع)' : 'Invalid phone (11 digits, starts with 03)'),
                    backgroundColor: AppColors.moneyOwed,
                  ),
                );
                return;
              }
              try {
                final db = ref.read(databaseProvider);
                final customer = Customer(
                  name: name,
                  phone: phone,
                );
                await db.insertCustomer(customer);

                // Save to marketing database asynchronously
                MarketingService.saveCustomerProfile(
                  customerName: name,
                  phone: phone,
                  shopCity: 'Unknown', // Will be enriched/linked via shop
                );

                ref.invalidate(customersWithBalanceProvider);
                ref.invalidate(customersProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.isUrdu ? 'گاہک شامل ہو گیا' : 'Customer added'),
                    backgroundColor: AppColors.moneyReceived,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.isUrdu ? 'خرابی: $e' : 'Error: $e'),
                    backgroundColor: AppColors.moneyOwed,
                  ),
                );
              }
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _editCustomerDialog(BuildContext context, WidgetRef ref, Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.isUrdu ? 'ترمیم کریں' : 'Edit Customer', style: AppTextStyles.urduTitle),
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
              maxLength: 11,
              decoration: InputDecoration(
                labelText: AppStrings.isUrdu ? 'فون (03...)' : 'Phone (03...)',
                labelStyle: AppTextStyles.urduCaption,
                prefixIcon: const Icon(Icons.phone_rounded),
                counterText: '',
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              
              try {
                final db = ref.read(databaseProvider);
                final updated = customer.copyWith(
                  name: name,
                  phone: phoneController.text.trim(),
                );
                await db.updateCustomer(updated);
                ref.invalidate(customersWithBalanceProvider);
                ref.invalidate(customersProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.moneyOwed),
                );
              }
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer(BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.deleteConfirmTitle, style: AppTextStyles.urduTitle),
        content: Text(
          AppStrings.isUrdu 
            ? 'کیا آپ واقعی "${customer.name}" کو حذف کرنا چاہتے ہیں؟' 
            : 'Are you sure you want to delete "${customer.name}"?', 
          style: AppTextStyles.urduBody
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final db = ref.read(databaseProvider);
                await db.deleteCustomer(customer.id);
                ref.invalidate(customersWithBalanceProvider);
                ref.invalidate(customersProvider);
                ref.invalidate(totalReceivableProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${customer.name} deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.moneyOwed),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.moneyOwed),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
