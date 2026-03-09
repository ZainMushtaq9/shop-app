import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Expense tracking screen for shop operations (rent, bills, tea/food, staff).
class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  // Mock data for UI demonstration
  final List<Map<String, dynamic>> _mockExpenses = [
    {'date': DateTime.now(), 'category': 'بجلی/گیس بل', 'amount': 15000, 'note': 'Electricity Bill'},
    {'date': DateTime.now(), 'category': 'چائے/کھانا', 'amount': 800, 'note': 'Guests tea'},
    {'date': DateTime.now().subtract(const Duration(days: 1)), 'category': 'ملازم کی تنخواہ', 'amount': 5000, 'note': 'Advance to staff'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.expenses),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.spacingMD),
        itemCount: _mockExpenses.length,
        itemBuilder: (context, index) {
          final expense = _mockExpenses[index];
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpenseDialog(),
        backgroundColor: AppColors.warning,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
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
              onChanged: (_) {},
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
            onPressed: () {
              // Add to DB then pop
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
