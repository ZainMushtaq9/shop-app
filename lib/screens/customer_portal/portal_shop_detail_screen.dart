import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'portal_providers.dart';
import 'portal_bill_detail_screen.dart';

class PortalShopDetailScreen extends ConsumerWidget {
  final String shopId;
  final Map<String, dynamic> shopData;

  const PortalShopDetailScreen({
    super.key,
    required this.shopId,
    required this.shopData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urdu = AppStrings.isUrdu;
    final shopName = urdu ? (shopData['shop_name_urdu'] ?? shopData['shop_name']) : shopData['shop_name'];
    final balance = (shopData['balance'] as num?)?.toDouble() ?? 0.0;
    
    final transactionsAsync = ref.watch(customerTransactionsProvider(shopId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(shopName ?? (urdu ? 'دکان کی تفصیل' : 'Shop Details')),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: balance > 0 ? AppColors.moneyOwed.withOpacity(0.1) : AppColors.moneyReceived.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: balance > 0 ? AppColors.moneyOwed.withOpacity(0.5) : AppColors.moneyReceived.withOpacity(0.5),
                width: 2,
              )
            ),
            child: Column(
              children: [
                Text(
                  urdu ? 'کل بقایا جات' : 'Total Amount Owed',
                  style: TextStyle(
                    color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppFormatters.currency(balance),
                  style: TextStyle(
                    color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (balance == 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    urdu ? 'آپ کا کھاتہ بالکل صاف ہے!' : 'Your account is completely clear!',
                    style: const TextStyle(color: AppColors.moneyReceived, fontWeight: FontWeight.w600),
                  )
                ]
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: \$err')),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            urdu ? 'کوئی لین دین نہیں ملا' : 'No transactions found',
                            style: AppTextStyles.urduTitle.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final isPayment = t['type'] == 'payment';
                      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
                      final dateStr = t['date'] as String;
                      final date = DateTime.parse(dateStr);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isPayment ? AppColors.moneyReceived.withOpacity(0.1) : AppColors.moneyOwed.withOpacity(0.1),
                            child: Icon(
                              isPayment ? Icons.download_rounded : Icons.receipt_rounded,
                              color: isPayment ? AppColors.moneyReceived : AppColors.moneyOwed,
                            ),
                          ),
                          title: Text(
                            isPayment 
                                ? (urdu ? 'رقم جمع کرائی' : 'Payment Made')
                                : (urdu ? 'بل (\${t['bill_number']})' : 'Bill (\${t['bill_number']})'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(date) + 
                            (isPayment && t['description'] != null ? '\\n\${t['description']}' : ''),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          isThreeLine: isPayment && t['description'] != null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppFormatters.currency(amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isPayment ? AppColors.moneyReceived : AppColors.moneyOwed,
                                ),
                              ),
                              Text(
                                isPayment ? (urdu ? 'وصول ہوئے' : 'Paid') : (urdu ? 'ادھار پر' : 'Charged'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isPayment ? AppColors.moneyReceived : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          onTap: isPayment ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PortalBillDetailScreen(
                                  saleId: t['id'],
                                  billNumber: t['bill_number'] ?? 'N/A',
                                  dateStr: t['date'],
                                  totalAmount: amount,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
