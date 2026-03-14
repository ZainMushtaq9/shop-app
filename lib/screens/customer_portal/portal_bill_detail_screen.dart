import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'portal_providers.dart';

class PortalBillDetailScreen extends ConsumerStatefulWidget {
  final String saleId;
  final String billNumber;
  final String dateStr;
  final double totalAmount;

  const PortalBillDetailScreen({
    super.key,
    required this.saleId,
    required this.billNumber,
    required this.dateStr,
    required this.totalAmount,
  });

  @override
  ConsumerState<PortalBillDetailScreen> createState() => _PortalBillDetailScreenState();
}

class _PortalBillDetailScreenState extends ConsumerState<PortalBillDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fire and forget: mark bill as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markBillAsRead(widget.saleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final urdu = AppStrings.isUrdu;
    final date = DateTime.parse(widget.dateStr);
    
    final itemsAsync = ref.watch(customerSaleItemsProvider(widget.saleId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(urdu ? 'بل کی تفصیل' : 'Bill Detail'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Column(
        children: [
          // Bill Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.grey[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      urdu ? 'بل نمبر:' : 'Bill Number:',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      widget.billNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      urdu ? 'تاریخ اور وقت:' : 'Date & Time:',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(date),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      urdu ? 'کل رقم:' : 'Total Amount:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      AppFormatters.currency(widget.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(color: Colors.grey[200], height: 8),
          
          // Items List
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      urdu ? 'اس بل میں کوئی آئٹم نہیں' : 'No items in this bill',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final pNameEn = item['products']?['name_en'];
                    final pNameUr = item['products']?['name_ur'];
                    final pName = (urdu && pNameUr != null) ? pNameUr : pNameEn ?? item['product_name'] ?? 'Product';
                    
                    final qty = (item['quantity'] as num?)?.toDouble() ?? 1;
                    final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
                    final sub = (item['subtotal'] as num?)?.toDouble() ?? (qty * price);
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${qty.toInt()}x',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text(
                                '${AppFormatters.currency(price)} ${urdu ? "فی آئٹم" : "per item"}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.currency(sub),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
