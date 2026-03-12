import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../../services/pdf_export_service.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';

class BuyerDashboardScreen extends ConsumerStatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  ConsumerState<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends ConsumerState<BuyerDashboardScreen> {
  String _userName = '';
  String _userPhone = '';
  bool _hideAmounts = false;
  DateTime? _filterStart;
  DateTime? _filterEnd;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Buyer';
      _userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  void _logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _toggleHideAmounts() {
    setState(() => _hideAmounts = !_hideAmounts);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filterStart != null && _filterEnd != null
          ? DateTimeRange(start: _filterStart!, end: _filterEnd!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _filterStart = picked.start;
        _filterEnd = picked.end;
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _filterStart = null;
      _filterEnd = null;
    });
  }

  String _hideValue(String value) => _hideAmounts ? '****' : value;

  @override
  Widget build(BuildContext context) {
    final asyncCustomers = ref.watch(customersWithBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isUrdu ? 'گاہک ڈیشبورڈ' : 'Buyer Dashboard'),
        actions: [
          IconButton(
            icon: Icon(_hideAmounts ? Icons.visibility_off : Icons.visibility),
            tooltip: AppStrings.isUrdu ? 'رقم چھپائیں/دکھائیں' : 'Hide/Show amounts',
            onPressed: _toggleHideAmounts,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // User info card
            Card(
              margin: const EdgeInsets.all(AppDimens.spacingMD),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.spacingMD),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userName, style: AppTextStyles.urduTitle.copyWith(fontSize: 18)),
                          Text(_userPhone, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    // Total balance badge
                    asyncCustomers.when(
                      data: (customers) {
                        double total = 0;
                        for (final c in customers) {
                          total += (c['balance'] as num?)?.toDouble() ?? 0.0;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: total > 0 ? AppColors.moneyOwed.withOpacity(0.1) : AppColors.moneyReceived.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                AppStrings.isUrdu ? 'کل بیلنس' : 'Total',
                                style: TextStyle(fontSize: 10, color: total > 0 ? AppColors.moneyOwed : AppColors.moneyReceived),
                              ),
                              Text(
                                _hideValue(AppFormatters.currency(total.abs())),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: total > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),

            // Date filter row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD),
              child: Row(
                children: [
                  Text(
                    AppStrings.isUrdu ? 'لین دین:' : 'Transactions:',
                    style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_filterStart != null)
                    Chip(
                      label: Text(
                        '${AppFormatters.dateShort(_filterStart!)} - ${AppFormatters.dateShort(_filterEnd!)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: _clearFilter,
                      deleteIconColor: AppColors.moneyOwed,
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.date_range, size: 20),
                    tooltip: AppStrings.isUrdu ? 'تاریخ فلٹر' : 'Filter by date',
                    onPressed: _pickDateRange,
                  ),
                ],
              ),
            ),

            // Customer ledger list
            Expanded(
              child: asyncCustomers.when(
                data: (customers) {
                  if (customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.disabled),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.isUrdu ? 'ابھی کوئی لین دین نہیں' : 'No transactions yet',
                            style: AppTextStyles.urduTitle.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.isUrdu ? 'دکاندار آپ کو شامل کرے گا' : 'Shopkeeper will add you',
                            style: AppTextStyles.urduCaption,
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
                              Icons.store_rounded,
                              color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            balance > 0
                                ? (AppStrings.isUrdu ? 'آپ کے ذمے' : 'You owe')
                                : balance < 0
                                    ? (AppStrings.isUrdu ? 'پیشگی' : 'Advance')
                                    : (AppStrings.isUrdu ? 'صاف' : 'Clear'),
                            style: TextStyle(
                              fontSize: 12,
                              color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _hideValue(AppFormatters.currency(balance.abs())),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                                ),
                              ),
                              // Export PDF button
                              InkWell(
                                onTap: () => _exportPdf(customer, balance),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.picture_as_pdf, size: 14, color: AppColors.info),
                                    const SizedBox(width: 2),
                                    Text('PDF', style: TextStyle(fontSize: 10, color: AppColors.info)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showLedgerDetail(customer, balance),
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
      ),
    );
  }

  void _showLedgerDetail(Customer customer, double balance) {
    final asyncTx = ref.read(customerTransactionsProvider(customer.id));
    asyncTx.when(
      data: (transactions) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(AppDimens.spacingMD),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.disabled,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(customer.name, style: AppTextStyles.urduTitle),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: balance > 0 ? AppColors.moneyOwed.withOpacity(0.1) : AppColors.moneyReceived.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${AppStrings.isUrdu ? 'بیلنس:' : 'Balance:'} ${_hideValue(AppFormatters.currency(balance.abs()))}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: transactions.isEmpty
                        ? Center(
                            child: Text(AppStrings.isUrdu ? 'کوئی لین دین نہیں' : 'No transactions'),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: transactions.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final tx = transactions[i];
                              return ListTile(
                                dense: true,
                                title: Text(tx.description, style: AppTextStyles.urduBody.copyWith(fontSize: 14)),
                                subtitle: Text(AppFormatters.date(tx.date), style: AppTextStyles.caption),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (tx.debitAmount > 0)
                                      Text(
                                        _hideValue('+${AppFormatters.currency(tx.debitAmount)}'),
                                        style: TextStyle(color: AppColors.moneyOwed, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    if (tx.creditAmount > 0)
                                      Text(
                                        _hideValue('-${AppFormatters.currency(tx.creditAmount)}'),
                                        style: TextStyle(color: AppColors.moneyReceived, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _exportPdf(Customer customer, double balance) async {
    try {
      final db = ref.read(databaseProvider);
      List<CustomerTransaction> transactions;

      if (_filterStart != null && _filterEnd != null) {
        transactions = await db.getCustomerTransactionsByDateRange(
          customer.id,
          _filterStart!,
          _filterEnd!,
        );
      } else {
        transactions = await db.getCustomerTransactions(customer.id);
      }

      double totalDebit = 0, totalCredit = 0;
      for (final tx in transactions) {
        totalDebit += tx.debitAmount;
        totalCredit += tx.creditAmount;
      }

      final pdfBytes = await PdfExportService.generateCustomerLedger(
        customerName: customer.name,
        shopName: 'Super Business Shop',
        transactions: transactions,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        balance: balance,
        startDate: _filterStart,
        endDate: _filterEnd,
      );

      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.isUrdu ? 'PDF خرابی:' : 'PDF error:'} $e'),
          backgroundColor: AppColors.moneyOwed,
        ),
      );
    }
  }
}
