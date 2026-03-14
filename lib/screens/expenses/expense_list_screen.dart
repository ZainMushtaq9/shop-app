import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/skeleton_loader.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  double _todayTotal = 0;
  double _monthTotal = 0;
  bool _isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    try {
      final db = ref.read(databaseProvider);
      final today = await db.getTodayExpenses();
      final now = DateTime.now();
      final month = await db.getMonthlyExpenses(now.year, now.month);
      
      if (mounted) {
        setState(() {
          _todayTotal = today;
          _monthTotal = month;
          _isLoadingSummary = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('چائے') || category.contains('کھانا') || category.toLowerCase().contains('tea') || category.toLowerCase().contains('food')) {
      return Icons.restaurant_rounded;
    } else if (category.contains('بجلی') || category.contains('گیس') || category.toLowerCase().contains('bill')) {
      return Icons.flash_on_rounded;
    } else if (category.contains('کرایہ') || category.toLowerCase().contains('rent')) {
      return Icons.storefront_rounded;
    } else if (category.contains('ملازم') || category.toLowerCase().contains('salary')) {
      return Icons.person_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'میرے خرچے' : 'My Expenses',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSummary();
          setState(() {}); // trigger futurebuilder rebuild
        },
        child: Column(
          children: [
            // Top Summary Bar
            Container(
              padding: const EdgeInsets.all(AppDimens.spacingMD),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(bottom: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryBox(
                      title: AppStrings.isUrdu ? 'آج کا خرچہ' : 'Today',
                      amount: _todayTotal,
                      isLoading: _isLoadingSummary,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingMD),
                  Expanded(
                    child: _SummaryBox(
                      title: AppStrings.isUrdu ? 'اس مہینے کا خرچہ' : 'This Month',
                      amount: _monthTotal,
                      isLoading: _isLoadingSummary,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // List of Expenses
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchExpenses(db),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppDimens.spacingMD),
                      itemCount: 6,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: AppDimens.spacingSM),
                        child: CustomSkeleton(width: double.infinity, height: 72, borderRadius: 12),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading expenses'));
                  }
                  final expenses = snapshot.data ?? [];
                  if (expenses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.disabled),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.isUrdu ? 'ابھی کوئی خرچہ درج نہیں ہوا' : 'No expenses recorded yet',
                            style: AppTextStyles.urduTitle.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppDimens.spacingMD),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final catIcon = _getCategoryIcon(expense['category']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppDimens.spacingSM),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.warning.withOpacity(0.1),
                            child: Icon(catIcon, color: AppColors.warning),
                          ),
                          title: Text(expense['category'], style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: expense['note'].toString().isNotEmpty 
                              ? Text(expense['note'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                              : null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(AppFormatters.currency(expense['amount'] as double), style: AppTextStyles.amountSmall.copyWith(color: AppColors.warning)),
                              Text(AppFormatters.dateShort(expense['date'] as DateTime), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpenseDialog(),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppStrings.isUrdu ? 'نیا خرچہ' : 'New Expense', style: AppTextStyles.urduBody.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchExpenses(db) async {
    try {
      final data = await db.getExpenses();
      return (data as List).map((e) => <String, dynamic>{
        'id': e['id'],
        'category': e['category'] ?? '',
        'amount': (e['amount'] as num).toDouble(),
        'note': e['note'] ?? '',
        'date': DateTime.parse(e['date']),
      }).toList();
    } catch (e) {
      return [];
    }
  }

  void _addExpenseDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String category = 'چائے/کھانا'; // Tea/Food

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Text(AppStrings.isUrdu ? 'نیا خرچہ' : 'New Expense', style: AppTextStyles.urduTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.isUrdu ? 'خرچے کی قسم / Category' : 'Category', style: AppTextStyles.urduCaption),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: category,
                    items: ['چائے/کھانا', 'بجلی/گیس بل', 'دکان کا کرایہ', 'ملازم کی تنخواہ', 'دیگر']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTextStyles.urduBody)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => category = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(AppStrings.isUrdu ? 'رقم / Amount' : 'Amount', style: AppTextStyles.urduCaption),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.amountMedium,
                decoration: InputDecoration(
                  prefixText: 'Rs. ',
                  hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(AppStrings.isUrdu ? 'تفصیل (اگر کوئی ہے) / Note' : 'Note (Optional)', style: AppTextStyles.urduCaption),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: AppStrings.isUrdu ? 'مثلاً سامان کا بل' : 'e.g. Electricity bill',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: Text(AppStrings.cancel, style: const TextStyle(color: AppColors.textSecondary))
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amt <= 0) return;

                final db = ref.read(databaseProvider);
                try {
                  await db.insertExpenseRaw({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'category': category,
                    'amount': amt,
                    'note': noteController.text.trim(),
                    'date': DateTime.now().toIso8601String(),
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  if (mounted) {
                    _loadSummary();
                    setState(() {}); // refresh future builder
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppStrings.save, style: AppTextStyles.urduBody.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final double amount;
  final bool isLoading;
  final Color color;

  const _SummaryBox({required this.title, required this.amount, required this.isLoading, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: AppTextStyles.urduCaption.copyWith(color: color, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          isLoading 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(AppFormatters.currency(amount), style: AppTextStyles.amountMedium.copyWith(color: color, fontSize: 18)),
        ],
      ),
    );
  }
}
