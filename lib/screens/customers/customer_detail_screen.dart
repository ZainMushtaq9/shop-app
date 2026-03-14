import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_db_service.dart';
import '../../widgets/global_app_bar.dart';

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
    final asyncLastActivity = ref.watch(customerLastActivityProvider(customer.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name, style: AppTextStyles.urduTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, color: AppColors.primary),
            onPressed: () => _showVisibilitySettingsDialog(context, ref),
          ),
        ],
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

          // ── Last Portal Activity ──
          asyncLastActivity.when(
            data: (date) {
               if (date == null) return const SizedBox.shrink();
               return Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.history, size: 14, color: AppColors.textSecondary),
                     const SizedBox(width: 4),
                     Text(
                       AppStrings.isUrdu 
                        ? 'گاہک نے آخری بار پورٹل دیکھا: ${AppFormatters.dateShort(date)}'
                        : 'Customer last viewed portal: ${AppFormatters.dateShort(date)}',
                       style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                     )
                   ]
                 )
               );
            },
            loading: () => const SizedBox.shrink(),
            error: (_,__) => const SizedBox.shrink(),
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
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkDivider : AppColors.lightDivider),
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
                      ...transactions.map((tx) => _LedgerRow(
                        transaction: tx,
                        ref: ref,
                        onRefresh: () => ref.refresh(customerTransactionsProvider(customer.id)),
                      )),

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

  void _sendWhatsAppReminder(BuildContext context, double balance) async {
    final phone = customer.phone.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this customer.')),
      );
      return;
    }
    
    final message = AppStrings.whatsappReminderMessage(customer.name, AppStrings.appName, balance);
    // Remove leading 0 and add +92 (Pakistan) if needed, simple logic for now:
    final formattedPhone = phone.startsWith('+') ? phone : (phone.startsWith('0') ? '+92${phone.substring(1)}' : '+$phone');
    
    if (!ConnectivityService.instance.isOnline) {
      await LocalDbService.instance.enqueueWhatsAppMessage(const Uuid().v4(), formattedPhone, message);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.isUrdu ? 'آف لائن۔ پیغام قطار میں شامل کر دیا گیا۔' : 'Offline. Message queued.')),
        );
      }
      return;
    }

    final url = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showVisibilitySettingsDialog(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final settings = await db.getCustomerVisibility(customer.id);
    
    bool showUdhaar = settings['show_udhaar'] ?? true;
    bool showPaidBills = settings['show_paid_bills'] ?? true;
    bool showBalance = settings['show_balance'] ?? true;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppStrings.isUrdu ? 'گاہک پورٹل کی ترتیبات' : 'Customer Portal Settings', style: AppTextStyles.urduTitle.copyWith(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(AppStrings.isUrdu ? 'کل بیلنس دکھائیں' : 'Show Total Balance', style: AppTextStyles.urduBody),
                value: showBalance,
                onChanged: (v) => setState(() => showBalance = v),
              ),
              SwitchListTile(
                title: Text(AppStrings.isUrdu ? 'ادھار بل دکھائیں' : 'Show Udhaar Bills', style: AppTextStyles.urduBody),
                value: showUdhaar,
                onChanged: (v) => setState(() => showUdhaar = v),
              ),
              SwitchListTile(
                title: Text(AppStrings.isUrdu ? 'ادا شدہ بل دکھائیں' : 'Show Paid Bills', style: AppTextStyles.urduBody),
                value: showPaidBills,
                onChanged: (v) => setState(() => showPaidBills = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                await db.setCustomerVisibility(customer.id, {
                  'show_balance': showBalance,
                  'show_udhaar': showUdhaar,
                  'show_paid_bills': showPaidBills,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(AppStrings.save),
            ),
          ],
        ),
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
            AppStrings.totalRemaining,
            style: AppTextStyles.urduCaption.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.formatAmount(balance.abs()),
            style: AppTextStyles.amountLarge.copyWith(color: isOwed ? AppColors.moneyOwed : AppColors.moneyReceived, fontSize: 32),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.urduCaption.copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
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
  final WidgetRef ref;
  final VoidCallback onRefresh;

  const _LedgerRow({required this.transaction, required this.ref, required this.onRefresh});

  Future<void> _toggleVisibility(BuildContext context) async {
    final db = ref.read(databaseProvider);
    try {
      if (transaction.saleId != null && transaction.saleId!.isNotEmpty) {
        await db.toggleBillVisibility(transaction.saleId!, !transaction.hiddenFromCustomer);
        onRefresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(transaction.hiddenFromCustomer ? 'بل اب ظاہر ہے' : 'بل اب چھپا ہوا ہے'), backgroundColor: AppColors.primary),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteTransaction(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.isUrdu ? 'حذف کریں؟' : 'Delete?'),
        content: Text(AppStrings.isUrdu ? 'کیا آپ اس ریکارڑ کو حذف کرنا چاہتے ہیں؟' : 'Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.moneyOwed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.isUrdu ? 'حذف کریں' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (transaction.saleId != null && transaction.saleId!.isNotEmpty) {
          await db.deleteSale(transaction.saleId!);
        } else {
          await db.deleteInstallment(transaction.id);
        }
        onRefresh();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      color: transaction.hiddenFromCustomer ? Colors.grey.withOpacity(0.1) : null,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (transaction.hiddenFromCustomer)
                  const Icon(Icons.visibility_off, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    transaction.typeUrdu,
                    style: AppTextStyles.urduCaption.copyWith(
                      fontSize: 11,
                      color: transaction.hiddenFromCustomer ? Colors.grey : AppColors.textMain,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'toggle') _toggleVisibility(context);
              if (value == 'delete') _deleteTransaction(context);
            },
            itemBuilder: (context) => [
              if (transaction.saleId != null && transaction.saleId!.isNotEmpty)
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(transaction.hiddenFromCustomer ? Icons.visibility : Icons.visibility_off, size: 18),
                      const SizedBox(width: 8),
                      Text(AppStrings.isUrdu 
                        ? (transaction.hiddenFromCustomer ? 'ظاہر کریں' : 'گاہک سے چھپائیں') 
                        : (transaction.hiddenFromCustomer ? 'Show to Customer' : 'Hide from Customer')
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: AppColors.moneyOwed, size: 18),
                    const SizedBox(width: 8),
                    Text(AppStrings.isUrdu ? 'حذف کریں' : 'Delete', style: const TextStyle(color: AppColors.moneyOwed)),
                  ],
                ),
              ),
            ],
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
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface.withOpacity(0.5) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSM),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkDivider : AppColors.lightDivider),
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
