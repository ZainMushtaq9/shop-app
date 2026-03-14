import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/skeleton_loader.dart';

/// Expense tracking screen for shop operations (rent, bills, tea/food, staff).
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch actual expenses from the database provider (we need to ensure expensesProvider exists)
    // If it doesn't exist, we'll watch the database provider directly and FutureBuilder.
    final db = ref.watch(databaseProvider);
    
    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.expenses,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchExpenses(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(AppDimens.spacingMD),
              itemCount: 6,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: AppDimens.spacingSM),
                child: CustomSkeleton(width: double.infinity, height: 64, borderRadius: 12),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final expenses = snapshot.data ?? [];
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.disabled),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.isUrdu ? 'ابھی کوئی خرچہ نہیں' : 'No expenses yet',
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
              return Card(
                margin: const EdgeInsets.only(bottom: AppDimens.spacingSM),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.warning.withOpacity(0.1),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.warning),
                  ),
                  title: Text(expense['category'], style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(expense['note']),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpenseDialog(),
        backgroundColor: AppColors.warning,
        child: const Icon(Icons.add_rounded, color: Colors.white),
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
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.isUrdu ? 'نیا خرچہ' : 'New Expense', style: AppTextStyles.urduTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: category,
              items: ['چائے/کھانا', 'بجلی/گیس بل', 'دکان کا کرایہ', 'ملازم کی تنخواہ', 'دیگر']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTextStyles.urduBody)))
                  .toList(),
              onChanged: (val) {
                if (val != null) category = val;
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: AppStrings.amount, prefixText: 'Rs. '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: AppStrings.isUrdu ? 'تفصیل' : 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
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
                  setState(() {}); // refresh future builder
                  Navigator.pop(ctx);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
