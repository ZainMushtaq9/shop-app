import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/skeleton_loader.dart';

/// Supplier list screen showing all suppliers with "you owe" amounts.
class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSuppliers = ref.watch(suppliersWithBalanceProvider);

    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.suppliers,
      ),
      body: Column(
        children: [
          // Total Payable header
          Consumer(
            builder: (context, ref, _) {
              final asyncTotal = ref.watch(totalPayableProvider);
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
                      AppStrings.youOwe,
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

          // Supplier list
          Expanded(
            child: asyncSuppliers.when(
              data: (suppliers) {
                if (suppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 80, color: AppColors.disabled),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.isUrdu ? 'ابھی کوئی سپلائر نہیں' : 'No suppliers yet',
                          style: AppTextStyles.urduTitle.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final data = suppliers[index];
                    final supplier = Supplier.fromMap(data);
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
                            Icons.local_shipping_rounded,
                            color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                          ),
                        ),
                        title: Text(
                          supplier.name,
                          style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          supplier.companyName ?? supplier.phone,
                          style: AppTextStyles.caption,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.currency(balance.abs()),
                              style: AppTextStyles.amountSmall.copyWith(
                                color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              balance > 0
                                  ? (AppStrings.isUrdu ? 'آپ کے ذمے' : 'You Owe')
                                  : (AppStrings.isUrdu ? 'صاف' : 'Clear'),
                              style: TextStyle(
                                fontSize: 11,
                                color: balance > 0 ? AppColors.moneyOwed : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _SupplierDetailScreen(supplier: supplier),
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
        onPressed: () => _addSupplierDialog(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          AppStrings.addSupplier,
          style: AppTextStyles.urduBody.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _addSupplierDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final companyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.addSupplier, style: AppTextStyles.urduTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: AppTextStyles.urduBody,
              decoration: InputDecoration(
                labelText: AppStrings.supplierName,
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
            const SizedBox(height: 12),
            TextField(
              controller: companyController,
              decoration: InputDecoration(
                labelText: AppStrings.companyName,
                labelStyle: AppTextStyles.urduCaption,
                prefixIcon: const Icon(Icons.business_rounded),
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
              final supplier = Supplier(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                companyName: companyController.text.trim().isNotEmpty ? companyController.text.trim() : null,
              );
              await db.insertSupplier(supplier);
              ref.invalidate(suppliersWithBalanceProvider);
              ref.invalidate(suppliersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}

/// Supplier detail screen with ledger table and actions.
class _SupplierDetailScreen extends ConsumerWidget {
  final Supplier supplier;

  const _SupplierDetailScreen({required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBalance = ref.watch(supplierBalanceProvider(supplier.id));
    final asyncTransactions = ref.watch(supplierTransactionsProvider(supplier.id));

    return Scaffold(
      appBar: GlobalAppBar(
        title: supplier.name,
      ),
      body: Column(
        children: [
          // Balance header
          asyncBalance.when(
            data: (balance) => Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppDimens.spacingMD),
              padding: const EdgeInsets.all(AppDimens.spacingLG),
              decoration: BoxDecoration(
                gradient: balance > 0 ? AppColors.payableGradient : AppColors.receivableGradient,
                borderRadius: BorderRadius.circular(AppDimens.radiusLG),
              ),
              child: Column(
                children: [
                  Text(
                    AppStrings.youOwe,
                    style: AppTextStyles.urduCaption.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.formatAmount(balance.abs()),
                    style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 32),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SupplierAction(
                        icon: Icons.payments_rounded,
                        label: AppStrings.makePayment,
                        onTap: () => _showPaymentDialog(context, ref, balance),
                      ),
                      _SupplierAction(
                        icon: Icons.add_shopping_cart_rounded,
                        label: AppStrings.addPurchase,
                        onTap: () => _showPurchaseDialog(context, ref, balance),
                      ),
                      _SupplierAction(
                        icon: Icons.message_rounded,
                        label: AppStrings.isUrdu ? 'واٹس ایپ' : 'WhatsApp',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Ledger table
          Expanded(
            child: asyncTransactions.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.isUrdu ? 'ابھی کوئی لین دین نہیں' : 'No transactions yet',
                      style: AppTextStyles.urduCaption,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppDimens.spacingMD),
                  itemCount: transactions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Table header
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: Row(
                          children: [
                            _Cell(AppStrings.date, flex: 2, isBold: true),
                            _Cell(AppStrings.description, flex: 3, isBold: true),
                            _Cell(AppStrings.isUrdu ? 'مال لیا' : 'DR', flex: 2, isBold: true),
                            _Cell(AppStrings.isUrdu ? 'ادائیگی' : 'CR', flex: 2, isBold: true),
                            _Cell(AppStrings.balance, flex: 2, isBold: true),
                          ],
                        ),
                      );
                    }

                    final tx = transactions[index - 1];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.divider)),
                      ),
                      child: Row(
                        children: [
                          _Cell(AppFormatters.dateShort(tx.date), flex: 2),
                          _Cell(tx.typeUrdu, flex: 3, isUrdu: true),
                          _Cell(
                            tx.debitAmount > 0 ? AppFormatters.number(tx.debitAmount) : '-',
                            flex: 2,
                            color: tx.debitAmount > 0 ? AppColors.moneyOwed : null,
                          ),
                          _Cell(
                            tx.creditAmount > 0 ? AppFormatters.number(tx.creditAmount) : '-',
                            flex: 2,
                            color: tx.creditAmount > 0 ? AppColors.moneyReceived : null,
                          ),
                          _Cell(
                            AppFormatters.number(tx.runningBalance),
                            flex: 2,
                            color: tx.runningBalance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                            isBold: true,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD),
                itemCount: 3,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppDimens.spacingSM),
                  child: CustomSkeleton(width: double.infinity, height: 60, borderRadius: 8),
                ),
              ),
              error: (_, __) => Center(child: Text(AppStrings.error)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPurchaseDialog(context, ref, 0),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: Text(
          '+ ${AppStrings.addPurchase}',
          style: AppTextStyles.urduBody.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, double currentBalance) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.makePayment, style: AppTextStyles.urduTitle),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.amountMedium,
          decoration: InputDecoration(
            labelText: AppStrings.amount,
            prefixText: 'Rs. ',
            prefixIcon: const Icon(Icons.payments_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              final db = ref.read(databaseProvider);
              final newBalance = currentBalance - amount;
              final tx = SupplierTransaction(
                supplierId: supplier.id,
                type: AppConstants.txPaymentMade,
                description: AppStrings.paymentMade,
                creditAmount: amount,
                runningBalance: newBalance,
                paymentMethod: AppConstants.paymentCash,
              );
              await db.insertSupplierTransaction(tx);
              ref.invalidate(supplierBalanceProvider(supplier.id));
              ref.invalidate(supplierTransactionsProvider(supplier.id));
              ref.invalidate(suppliersWithBalanceProvider);
              ref.invalidate(totalPayableProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, WidgetRef ref, double currentBalance) {
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.addPurchase, style: AppTextStyles.urduTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.amountMedium,
              decoration: InputDecoration(
                labelText: AppStrings.amount,
                prefixText: 'Rs. ',
                prefixIcon: const Icon(Icons.shopping_bag_rounded),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: AppTextStyles.urduBody,
              decoration: InputDecoration(
                labelText: AppStrings.description,
                prefixIcon: const Icon(Icons.note_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              final db = ref.read(databaseProvider);
              final newBalance = currentBalance + amount;
              final tx = SupplierTransaction(
                supplierId: supplier.id,
                type: AppConstants.txCreditPurchase,
                description: descController.text.trim().isNotEmpty
                    ? descController.text.trim()
                    : AppStrings.creditPurchase,
                debitAmount: amount,
                runningBalance: newBalance,
              );
              await db.insertSupplierTransaction(tx);
              ref.invalidate(supplierBalanceProvider(supplier.id));
              ref.invalidate(supplierTransactionsProvider(supplier.id));
              ref.invalidate(suppliersWithBalanceProvider);
              ref.invalidate(totalPayableProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}

class _SupplierAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SupplierAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.urduCaption.copyWith(color: Colors.white, fontSize: 10), maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool isBold;
  final bool isUrdu;
  final Color? color;

  const _Cell(this.text, {this.flex = 1, this.isBold = false, this.isUrdu = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: isUrdu
            ? AppTextStyles.urduCaption.copyWith(fontSize: 11, fontWeight: isBold ? FontWeight.bold : null, color: color)
            : TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color ?? AppColors.textPrimary),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
