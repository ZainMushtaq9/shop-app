import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import '../../models/models.dart';

/// Maal Wapsi (Returns) screen — customer return flow.
/// Flow: Find bill → Select items → Choose refund method → Confirm.
class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  int _step = 0; // 0=search, 1=select items, 2=confirm
  final _searchController = TextEditingController();
  List<Sale> _searchResults = [];
  Sale? _selectedSale;
  List<SaleItem> _saleItems = [];
  Map<String, int> _returnQty = {}; // productId -> qty to return
  Map<String, String> _returnCondition = {}; // productId -> condition
  String _refundMethod = 'cash';
  bool _loading = false;
  List<Map<String, dynamic>> _returnHistory = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'مال واپسی / Returns' : 'Returns',
      ),
      body: IndexedStack(
        index: _step,
        children: [
          _buildSearchStep(),
          _buildSelectItemsStep(),
          _buildConfirmStep(),
        ],
      ),
    );
  }

  // ─── STEP 0: SEARCH ───
  Widget _buildSearchStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingLG),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMD),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text('↩️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  AppStrings.isUrdu ? 'گاہک نے مال واپس کیا' : 'Customer Returned Goods',
                  style: AppTextStyles.urduTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.isUrdu
                    ? 'پہلے اصل بل تلاش کریں'
                    : 'First find the original bill',
                  style: AppTextStyles.urduCaption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spacingMD),
          
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: AppStrings.isUrdu ? 'بل نمبر یا تاریخ' : 'Bill number or date',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchBills,
              ),
            ),
            onSubmitted: (_) => _searchBills(),
          ),
          const SizedBox(height: 12),
          
          // Or load recent bills
          TextButton.icon(
            onPressed: _loadRecentBills,
            icon: const Icon(Icons.history_rounded),
            label: Text(AppStrings.isUrdu ? 'حالیہ بل دکھاؤ' : 'Show Recent Bills'),
          ),
          
          // Search results
          if (_loading) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD),
              child: CustomSkeleton(width: double.infinity, height: 80, borderRadius: 12),
            ),
          
          ..._searchResults.map((sale) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.info.withOpacity(0.1),
                child: const Icon(Icons.receipt_rounded, color: AppColors.info),
              ),
              title: Text('Bill #${sale.id.substring(0, 6).toUpperCase()}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(AppFormatters.dateTime(sale.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              trailing: Text(AppFormatters.currency(sale.total), style: AppTextStyles.amountSmall),
              onTap: () => _selectBill(sale),
            ),
          )),
        ],
      ),
    );
  }

  // ─── STEP 1: SELECT ITEMS ───
  Widget _buildSelectItemsStep() {
    if (_selectedSale == null) return const SizedBox();
    
    double totalReturn = 0;
    _returnQty.forEach((pid, qty) {
      final item = _saleItems.firstWhere((i) => i.productId == pid, orElse: () => _saleItems.first);
      totalReturn += qty * item.salePrice;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bill header
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDimens.radiusMD),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bill #${_selectedSale!.id.substring(0, 6).toUpperCase()}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                Text(AppFormatters.currency(_selectedSale!.total), style: AppTextStyles.amountSmall.copyWith(color: AppColors.info)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            AppStrings.isUrdu ? 'کون سی چیزیں واپس آ رہی ہیں؟' : 'Which items are being returned?',
            style: AppTextStyles.urduTitle,
          ),
          const SizedBox(height: 12),
          
          // Items with return qty controls
          ..._saleItems.map((item) {
            final returnQty = _returnQty[item.productId] ?? 0;
            final condition = _returnCondition[item.productId] ?? 'good';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.productName.isNotEmpty ? item.productName : 'Product',
                            style: AppTextStyles.urduBody,
                          ),
                        ),
                        Text('${AppFormatters.currency(item.salePrice)} × ${item.quantity.toInt()}', style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Qty controls
                    Row(
                      children: [
                        Text(AppStrings.isUrdu ? 'واپسی:' : 'Return:', style: AppTextStyles.caption),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: returnQty > 0 ? () => setState(() => _returnQty[item.productId] = returnQty - 1) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.moneyOwed,
                        ),
                        Text('$returnQty', style: AppTextStyles.amountSmall),
                        IconButton(
                          onPressed: returnQty < item.quantity.toInt() ? () => setState(() => _returnQty[item.productId] = returnQty + 1) : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.moneyReceived,
                        ),
                        const Spacer(),
                        if (returnQty > 0)
                          Text(AppFormatters.currency(returnQty * item.salePrice), style: AppTextStyles.amountSmall.copyWith(color: AppColors.warning, fontSize: 14)),
                      ],
                    ),
                    // Condition selector (only if returning)
                    if (returnQty > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            _conditionChip(item.productId, 'good', AppStrings.isUrdu ? 'ٹھیک ✅' : 'Good ✅', AppColors.moneyReceived),
                            const SizedBox(width: 8),
                            _conditionChip(item.productId, 'damaged', AppStrings.isUrdu ? 'خراب ❌' : 'Damaged ❌', AppColors.moneyOwed),
                            const SizedBox(width: 8),
                            _conditionChip(item.productId, 'expired', AppStrings.isUrdu ? 'ختم ⚠️' : 'Expired ⚠️', AppColors.warning),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Refund method
          if (totalReturn > 0) ...[
            Text(
              AppStrings.isUrdu ? 'پیسے کیسے واپس کرو گے؟' : 'How to refund?',
              style: AppTextStyles.urduTitle,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _refundMethodCard(
                    'cash',
                    Icons.payments_rounded,
                    AppStrings.isUrdu ? '💵 کیش واپس دو' : '💵 Cash Refund',
                    AppColors.moneyReceived,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _refundMethodCard(
                    'udhaar_adjust',
                    Icons.receipt_long_rounded,
                    AppStrings.isUrdu ? '📋 ادھار میں سے کم کرو' : '📋 Adjust Credit',
                    AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total return amount
            Container(
              padding: const EdgeInsets.all(AppDimens.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.isUrdu ? 'کل واپسی رقم' : 'Total Return Amount', style: AppTextStyles.urduBody),
                  Text(AppFormatters.currency(totalReturn), style: AppTextStyles.amountMedium.copyWith(color: AppColors.warning)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() { _step = 0; _selectedSale = null; }),
                  child: Text(AppStrings.isUrdu ? 'واپس' : 'Back'),
                ),
              ),
              if (totalReturn > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _step = 2),
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    label: Text(
                      AppStrings.isUrdu ? 'واپسی کنفرم کرو' : 'Confirm Return',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.moneyReceived,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _conditionChip(String productId, String value, String label, Color color) {
    final selected = (_returnCondition[productId] ?? 'good') == value;
    return GestureDetector(
      onTap: () => setState(() => _returnCondition[productId] = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? color : AppColors.textSecondary, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _refundMethodCard(String method, IconData icon, String label, Color color) {
    final selected = _refundMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _refundMethod = method),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.textSecondary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: selected ? color : AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── STEP 2: CONFIRM ───
  Widget _buildConfirmStep() {
    double totalReturn = 0;
    final returningItems = <MapEntry<SaleItem, int>>[];
    _returnQty.forEach((pid, qty) {
      if (qty > 0) {
        final item = _saleItems.firstWhere((i) => i.productId == pid);
        totalReturn += qty * item.salePrice;
        returningItems.add(MapEntry(item, qty));
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('📋', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            AppStrings.isUrdu ? 'واپسی کی تصدیق' : 'Return Confirmation',
            style: AppTextStyles.urduTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMD),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                ...returningItems.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${entry.key.productName.isNotEmpty ? entry.key.productName : "Product"} × ${entry.value}', style: AppTextStyles.urduBody)),
                      Text(AppFormatters.currency(entry.value * entry.key.salePrice), style: AppTextStyles.amountSmall.copyWith(fontSize: 14)),
                    ],
                  ),
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.isUrdu ? 'کل واپسی' : 'Total Return', style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold)),
                    Text(AppFormatters.currency(totalReturn), style: AppTextStyles.amountMedium.copyWith(color: AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.isUrdu ? 'واپسی کا طریقہ' : 'Refund Method', style: AppTextStyles.urduCaption),
                    Text(
                      _refundMethod == 'cash'
                        ? (AppStrings.isUrdu ? '💵 کیش واپس' : '💵 Cash')
                        : (AppStrings.isUrdu ? '📋 ادھار سے کم' : '📋 Credit Adjust'),
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Process return
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _processReturn,
              icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_rounded, color: Colors.white),
              label: Text(
                _loading
                  ? (AppStrings.isUrdu ? 'انتظار کرو...' : 'Processing...')
                  : (AppStrings.isUrdu ? 'واپسی کنفرم کرو' : 'Confirm Return'),
                style: AppTextStyles.urduBody.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.moneyReceived,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => _step = 1),
            child: Text(AppStrings.isUrdu ? 'واپس جاؤ' : 'Go Back'),
          ),
        ],
      ),
    );
  }

  // ─── ACTIONS ───
  Future<void> _searchBills() async {
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final sales = await db.getSalesByDateRange(thirtyDaysAgo, DateTime.now());
      setState(() {
        _searchResults = sales;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRecentBills() async {
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final sales = await db.getSalesByDateRange(sevenDaysAgo, DateTime.now());
      setState(() {
        _searchResults = sales;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectBill(Sale sale) async {
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final items = await db.getSaleItems(sale.id);
      setState(() {
        _selectedSale = sale;
        _saleItems = items;
        _returnQty = {for (var item in items) item.productId: 0};
        _returnCondition = {for (var item in items) item.productId: 'good'};
        _loading = false;
        _step = 1;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _processReturn() async {
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      
      // Process each returned item
      for (final entry in _returnQty.entries) {
        if (entry.value > 0) {
          final condition = _returnCondition[entry.key] ?? 'good';
          // Restock if condition is good
          if (condition == 'good') {
            await db.updateStock(entry.key, entry.value);
          }
        }
      }
      
      // If udhaar adjustment and customer exists
      if (_refundMethod == 'udhaar_adjust' && _selectedSale?.customerId != null) {
        double totalReturn = 0;
        _returnQty.forEach((pid, qty) {
          if (qty > 0) {
            final item = _saleItems.firstWhere((i) => i.productId == pid);
            totalReturn += qty * item.salePrice;
          }
        });
        
        // Lower customer balance by adding a 'received' transaction
        final tx = CustomerTransaction(
          customerId: _selectedSale!.customerId!,
          creditAmount: totalReturn,
          type: 'RETURN',
          description: AppStrings.isUrdu ? 'مال واپسی کی کٹوتی (بل #${_selectedSale!.id.substring(0, 6).toUpperCase()})' : 'Return Adj. (Bill #${_selectedSale!.id.substring(0, 6).toUpperCase()})',
          date: DateTime.now(),
        );
        await db.insertCustomerTransaction(tx);
      }
      
      setState(() => _loading = false);
      
      if (mounted) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.isUrdu ? '✅ واپسی کامیاب!' : '✅ Return processed!'),
            backgroundColor: AppColors.moneyReceived,
          ),
        );
        // Reset
        setState(() {
          _step = 0;
          _selectedSale = null;
          _saleItems = [];
          _returnQty = {};
          _searchResults = [];
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.isUrdu ? '❌ کچھ غلط ہوا' : '❌ Something went wrong'),
            backgroundColor: AppColors.moneyOwed,
          ),
        );
      }
    }
  }
}
