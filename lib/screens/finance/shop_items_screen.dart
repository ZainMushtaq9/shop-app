import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';

/// Dukaan ki Cheezein — Simple list of shop's big purchases /equipment.
/// No depreciation, no complex calculations. Just a list of what you own.
class ShopItemsScreen extends ConsumerStatefulWidget {
  const ShopItemsScreen({super.key});

  @override
  ConsumerState<ShopItemsScreen> createState() => _ShopItemsScreenState();
}

class _ShopItemsScreenState extends ConsumerState<ShopItemsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  double _totalValue = 0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      // Shop items stored locally for now — can be migrated to Supabase table later
      // Using in-memory list since the shop_items table may not exist yet
      setState(() {
        _loading = false;
        _totalValue = _items.fold<double>(0, (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0));
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'دکان کی چیزیں / Shop Items' : 'Shop Items',
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty ? _buildEmptyState() : _buildItemList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItemDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          AppStrings.isUrdu ? 'نئی چیز' : 'Add Item',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📦', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            AppStrings.isUrdu
              ? 'ابھی کچھ نہیں ہے'
              : 'No items yet',
            style: AppTextStyles.urduTitle,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.isUrdu
              ? 'دکان کی بڑی چیزیں یہاں لکھیں\n(فریج، کاؤنٹر، CCTV وغیرہ)'
              : 'Record your shop equipment here\n(Fridge, Counter, CCTV, etc.)',
            style: AppTextStyles.urduCaption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addItemDialog,
            icon: const Icon(Icons.add_rounded),
            label: Text(AppStrings.isUrdu ? 'پہلی چیز شامل کرو' : 'Add First Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    return Column(
      children: [
        // Total value card
        Container(
          margin: const EdgeInsets.all(AppDimens.spacingMD),
          padding: const EdgeInsets.all(AppDimens.spacingLG),
          decoration: BoxDecoration(
            gradient: AppColors.profitGradient,
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          ),
          child: Column(
            children: [
              Text(
                AppStrings.isUrdu
                  ? 'آپ نے اپنی دکان پر کل خریداری کی'
                  : 'Total Shop Equipment Value',
                style: AppTextStyles.urduCaption.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                AppFormatters.currency(_totalValue),
                style: AppTextStyles.amountLarge.copyWith(color: Colors.white),
              ),
              Text(
                '${_items.length} ${AppStrings.isUrdu ? "چیزیں" : "items"}',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ),
        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppDimens.spacingSM),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF8E1),
                    child: Text('📦', style: TextStyle(fontSize: 24)),
                  ),
                  title: Text(item['name'] as String, style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['date'] != null)
                        Text(
                          '${AppStrings.isUrdu ? "خریدا" : "Bought"}: ${item['date']}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                  trailing: Text(
                    AppFormatters.currency((item['price'] as num).toDouble()),
                    style: AppTextStyles.amountSmall.copyWith(color: AppColors.primary),
                  ),
                  onLongPress: () {
                    setState(() => _items.removeAt(index));
                    _recalcTotal();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _recalcTotal() {
    _totalValue = _items.fold<double>(0, (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0));
  }

  void _addItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.isUrdu ? 'نئی چیز شامل کرو' : 'Add New Item', style: AppTextStyles.urduTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppStrings.isUrdu ? 'چیز کا نام' : 'Item Name',
                hintText: AppStrings.isUrdu ? 'مثلاً: فریج، کاؤنٹر' : 'e.g., Fridge, Counter',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: AppStrings.isUrdu ? 'کتنے میں خریدا؟' : 'Purchase Price',
                prefixText: 'Rs. ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.isUrdu ? 'رد کرو' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              if (name.isEmpty || price <= 0) return;

              setState(() {
                _items.add({
                  'name': name,
                  'price': price,
                  'date': AppFormatters.date(selectedDate),
                });
                _recalcTotal();
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(AppStrings.isUrdu ? 'محفوظ کرو' : 'Save', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
