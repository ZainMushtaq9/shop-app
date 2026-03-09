import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';

/// Customer detail screen showing:
/// - Balance header card (RED if owed, GREEN if advance)
/// - Action buttons (WhatsApp, Receive Payment, View Bill)
/// - Complete ledger table (Date | Description | DR | CR | Balance)
class CustomerDetailScreen extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBalance = ref.watch(customerBalanceProvider(customer.id));
    final asyncTransactions = ref.watch(customerTransactionsProvider(customer.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name, style: AppTextStyles.urduTitle.copyWith(color: Colors.white)),
      ),
      body: Column(
        children: [
          // ── Balance Header Card ──
          asyncBalance.when(
            data: (balance) => _BalanceCard(
              customerName: customer.name,
              balance: balance,
              onWhatsApp: () => _sendWhatsAppReminder(context, balance),
              onReceivePayment: () => _showReceivePaymentDialog(context, ref, balance),
            ),
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Ledger Table ──
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

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.spacingMD),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: Row(
                          children: [
                            _HeaderCell(AppStrings.date, flex: 2),
                            _HeaderCell(AppStrings.description, flex: 3),
                            _HeaderCell(AppStrings.debit, flex: 2),
                            _HeaderCell(AppStrings.credit, flex: 2),
                            _HeaderCell(AppStrings.balance, flex: 2),
                          ],
                        ),
                      ),
                      // Table rows
                      ...transactions.map((tx) => _LedgerRow(transaction: tx)),

                      const SizedBox(height: 16),

                      // Footer totals
                      _LedgerFooter(transactions: transactions),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(AppStrings.error)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReceivePaymentDialog(context, ref, 0),
        icon: const Icon(Icons.payments_rounded),
        label: Text(
          '+ ${AppStrings.receivePayment}',
          style: AppTextStyles.urduBody.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _sendWhatsAppReminder(BuildContext context, double balance) {
    // In a real app, this would use url_launcher to open WhatsApp
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.whatsappReminderMessage(customer.name, AppStrings.appName, balance),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showReceivePaymentDialog(BuildContext context, WidgetRef ref, double currentBalance) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.receivePayment, style: AppTextStyles.urduTitle),
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
                labelStyle: AppTextStyles.urduCaption,
                prefixText: 'Rs. ',
                prefixIcon: const Icon(Icons.payments_rounded),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              style: AppTextStyles.urduBody,
              decoration: InputDecoration(
                labelText: AppStrings.isUrdu ? 'نوٹ (اختیاری)' : 'Notes (optional)',
                labelStyle: AppTextStyles.urduCaption,
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
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;

              final db = ref.read(databaseProvider);
              final newBalance = currentBalance - amount;

              final tx = CustomerTransaction(
                customerId: customer.id,
                type: AppConstants.txPaymentReceived,
                description: AppStrings.paymentReceived,
                creditAmount: amount,
                runningBalance: newBalance,
                paymentMethod: AppConstants.paymentCash,
                notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
              );

              await db.insertCustomerTransaction(tx);
              ref.invalidate(customerBalanceProvider(customer.id));
              ref.invalidate(customerTransactionsProvider(customer.id));
              ref.invalidate(customersWithBalanceProvider);
              ref.invalidate(totalReceivableProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}

/// Balance header card for customer detail screen
class _BalanceCard extends StatelessWidget {
  final String customerName;
  final double balance;
  final VoidCallback onWhatsApp;
  final VoidCallback onReceivePayment;

  const _BalanceCard({
    required this.customerName,
    required this.balance,
    required this.onWhatsApp,
    required this.onReceivePayment,
  });

  @override
  Widget build(BuildContext context) {
    final isOwed = balance > 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimens.spacingMD),
      padding: const EdgeInsets.all(AppDimens.spacingLG),
      decoration: BoxDecoration(
        gradient: isOwed ? AppColors.payableGradient : AppColors.receivableGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        boxShadow: [
          BoxShadow(
            color: (isOwed ? AppColors.moneyOwed : AppColors.moneyReceived).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.totalRemaining,
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
              _ActionButton(
                icon: Icons.message_rounded,
                label: AppStrings.isUrdu ? 'واٹس ایپ' : 'WhatsApp',
                onTap: onWhatsApp,
              ),
              _ActionButton(
                icon: Icons.payments_rounded,
                label: AppStrings.receivePayment,
                onTap: onReceivePayment,
              ),
              _ActionButton(
                icon: Icons.receipt_long_rounded,
                label: AppStrings.viewBill,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.urduCaption.copyWith(color: Colors.white, fontSize: 10),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _HeaderCell(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppTextStyles.urduCaption.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final CustomerTransaction transaction;

  const _LedgerRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              AppFormatters.dateShort(transaction.date),
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              transaction.typeUrdu,
              style: AppTextStyles.urduCaption.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction.debitAmount > 0 ? AppFormatters.number(transaction.debitAmount) : '-',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: transaction.debitAmount > 0 ? AppColors.moneyOwed : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction.creditAmount > 0 ? AppFormatters.number(transaction.creditAmount) : '-',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: transaction.creditAmount > 0 ? AppColors.moneyReceived : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppFormatters.number(transaction.runningBalance),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: transaction.runningBalance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerFooter extends StatelessWidget {
  final List<CustomerTransaction> transactions;

  const _LedgerFooter({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final totalDR = transactions.fold<double>(0, (sum, tx) => sum + tx.debitAmount);
    final totalCR = transactions.fold<double>(0, (sum, tx) => sum + tx.creditAmount);
    final balance = totalDR - totalCR;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('${AppStrings.isUrdu ? "کل ڈیبٹ" : "Total DR"}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(AppFormatters.currency(totalDR),
                  style: AppTextStyles.amountSmall.copyWith(color: AppColors.moneyOwed, fontSize: 14)),
            ],
          ),
          Column(
            children: [
              Text('${AppStrings.isUrdu ? "کل کریڈٹ" : "Total CR"}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(AppFormatters.currency(totalCR),
                  style: AppTextStyles.amountSmall.copyWith(color: AppColors.moneyReceived, fontSize: 14)),
            ],
          ),
          Column(
            children: [
              Text(AppStrings.balance,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(AppFormatters.currency(balance.abs()),
                  style: AppTextStyles.amountSmall.copyWith(
                    color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                    fontSize: 14,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
