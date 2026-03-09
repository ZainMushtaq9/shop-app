import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';

/// Point of Sale (POS) / Billing screen.
/// Multi-item cart, discount, tax, payment method selection.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final List<_CartItem> _cart = [];
  double _discount = 0;
  double _taxRate = 0;
  String _paymentType = 'CASH';
  String? _selectedCustomerId;
  String _searchQuery = '';

  double get _subtotal => _cart.fold(0, (sum, item) => sum + (item.product.salePrice * item.quantity));
  double get _taxAmount => _subtotal * (_taxRate / 100);
  double get _total => _subtotal - _discount + _taxAmount;
  double get _totalProfit =>
      _cart.fold(0, (sum, item) => sum + (item.product.unitProfit * item.quantity));

  @override
  Widget build(BuildContext context) {
    final asyncProducts = _searchQuery.isNotEmpty
        ? ref.watch(productSearchProvider(_searchQuery))
        : ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.newSale),
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => setState(() => _cart.clear()),
            ),
        ],
      ),
      body: Row(
        children: [
          // ── Left: Product Selection ──
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(AppDimens.spacingSM),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppStrings.searchProducts,
                      hintStyle: AppTextStyles.urduCaption,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),

                // Product grid
                Expanded(
                  child: asyncProducts.when(
                    data: (products) {
                      final activeProducts = products.where((p) => p.stockQuantity > 0).toList();
                      if (activeProducts.isEmpty) {
                        return Center(
                          child: Text(AppStrings.noData, style: AppTextStyles.urduCaption),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(AppDimens.spacingSM),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: activeProducts.length,
                        itemBuilder: (context, index) {
                          final product = activeProducts[index];
                          return _ProductCard(
                            product: product,
                            onTap: () => _addToCart(product),
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

          // ── Right: Cart ──
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(left: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                // Cart header
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppColors.primary.withOpacity(0.05),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${AppStrings.isUrdu ? "ٹوکری" : "Cart"} (${_cart.length})',
                        style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Cart items
                Expanded(
                  child: _cart.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.isUrdu ? 'مصنوعات شامل کریں' : 'Add products',
                            style: AppTextStyles.urduCaption,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return _CartItemTile(
                              item: item,
                              onQuantityChanged: (qty) {
                                setState(() {
                                  if (qty <= 0) {
                                    _cart.removeAt(index);
                                  } else {
                                    _cart[index] = _CartItem(item.product, qty);
                                  }
                                });
                              },
                              onRemove: () => setState(() => _cart.removeAt(index)),
                            );
                          },
                        ),
                ),

                // Totals & Checkout
                if (_cart.isNotEmpty) ...[
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _TotalRow(AppStrings.subtotal, _subtotal),
                        if (_discount > 0) _TotalRow(AppStrings.discount, -_discount, color: AppColors.moneyReceived),
                        if (_taxAmount > 0) _TotalRow(AppStrings.tax, _taxAmount),
                        const Divider(),
                        _TotalRow(AppStrings.total, _total, isBold: true, fontSize: 20),
                        const SizedBox(height: 8),
                        // Payment type selector
                        Row(
                          children: [
                            _PaymentChip('CASH', AppStrings.cash, Icons.money_rounded),
                            const SizedBox(width: 4),
                            _PaymentChip('CREDIT', AppStrings.udhaar, Icons.credit_card_rounded),
                            const SizedBox(width: 4),
                            _PaymentChip('PARTIAL', AppStrings.partial, Icons.pie_chart_rounded),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Checkout button
                        SizedBox(
                          width: double.infinity,
                          height: AppDimens.minTouchTarget,
                          child: ElevatedButton.icon(
                            onPressed: _checkout,
                            icon: const Icon(Icons.check_circle_rounded),
                            label: Text(
                              AppStrings.generateBill,
                              style: AppTextStyles.urduBody.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.moneyReceived,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _PaymentChip(String type, String label, IconData icon) {
    final isSelected = _paymentType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.primary),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(Product product) {
    setState(() {
      final existing = _cart.indexWhere((item) => item.product.id == product.id);
      if (existing >= 0) {
        _cart[existing] = _CartItem(product, _cart[existing].quantity + 1);
      } else {
        _cart.add(_CartItem(product, 1));
      }
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    final db = ref.read(databaseProvider);

    final sale = Sale(
      subtotal: _subtotal,
      discount: _discount,
      tax: _taxAmount,
      total: _total,
      profit: _totalProfit,
      paymentType: _paymentType,
      amountPaid: _paymentType == 'CASH' ? _total : 0,
      balanceDue: _paymentType == 'CASH' ? 0 : _total,
      customerId: _selectedCustomerId,
    );

    final saleItems = _cart.map((item) => SaleItem(
      saleId: sale.id,
      productId: item.product.id,
      productName: item.product.displayName,
      quantity: item.quantity,
      purchasePrice: item.product.purchasePrice,
      salePrice: item.product.salePrice,
    )).toList();

    await db.insertSale(sale, saleItems);

    // Invalidate providers
    ref.invalidate(todaySalesProvider);
    ref.invalidate(todayProfitProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(lowStockProductsProvider);
    ref.invalidate(totalReceivableProvider);

    setState(() {
      _cart.clear();
      _discount = 0;
      _paymentType = 'CASH';
      _selectedCustomerId = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isUrdu
                ? 'بل کامیابی سے بنا دیا گیا! ${AppFormatters.currency(_total)}'
                : 'Bill created! ${AppFormatters.currency(_total)}',
          ),
          backgroundColor: AppColors.moneyReceived,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _CartItem {
  final Product product;
  final int quantity;

  _CartItem(this.product, this.quantity);
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              product.displayName,
              style: AppTextStyles.urduCaption.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              AppFormatters.currency(product.salePrice),
              style: AppTextStyles.amountSmall.copyWith(color: AppColors.primary, fontSize: 14),
            ),
            Text(
              '${AppStrings.stockQuantity}: ${product.stockQuantity}',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final _CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemTile({required this.item, required this.onQuantityChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.displayName, style: AppTextStyles.urduCaption.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(AppFormatters.currency(item.product.salePrice), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Quantity controls
          Row(
            children: [
              _QtyButton(Icons.remove, () => onQuantityChanged(item.quantity - 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.quantity}', style: AppTextStyles.amountSmall.copyWith(fontSize: 14)),
              ),
              _QtyButton(Icons.add, () => onQuantityChanged(item.quantity + 1)),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            AppFormatters.currency(item.product.salePrice * item.quantity),
            style: AppTextStyles.amountSmall.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final double fontSize;
  final Color? color;

  const _TotalRow(this.label, this.amount, {this.isBold = false, this.fontSize = 14, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize - 2, fontWeight: isBold ? FontWeight.bold : null)),
          Text(
            AppFormatters.currency(amount),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
