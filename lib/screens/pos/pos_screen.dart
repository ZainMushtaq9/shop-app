import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../services/pdf_export_service.dart';
import '../../widgets/skeleton_loader.dart';

/// Point of Sale (POS) / Billing screen.
/// Multi-item cart, discount, tax, payment method selection.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final List<_CartItem> _cart = [];
  double _taxRate = 0;
  String _paymentType = 'CASH';
  String? _selectedCustomerId;
  String _searchQuery = '';

  double get _subtotal => _cart.fold(0, (sum, item) => sum + (item.product.salePrice * item.quantity));
  double get _taxAmount => _subtotal * (_taxRate / 100);
  double get _totalProfit =>
      _cart.fold(0, (sum, item) => sum + (item.product.unitProfit * item.quantity));

  @override
  Widget build(BuildContext context) {
    final asyncProducts = _searchQuery.isNotEmpty
        ? ref.watch(productSearchProvider(_searchQuery))
        : ref.watch(productsProvider);

    return Scaffold(
      body: Row(
        children: [
          // ── Left: Product Selection ──
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Autocomplete search bar
                Padding(
                  padding: const EdgeInsets.all(AppDimens.spacingSM),
                  child: Autocomplete<Product>(
                    optionsBuilder: (textEditingValue) async {
                      final query = textEditingValue.text.trim();
                      if (query.isEmpty) return const Iterable<Product>.empty();
                      final db = ref.read(databaseProvider);
                      return await db.searchProducts(query);
                    },
                    displayStringForOption: (product) => product.displayName,
                    onSelected: (product) => _addToCart(product),
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: AppStrings.isUrdu ? 'پہلا حرف لکھیں...' : 'Type to search...',
                          hintStyle: AppTextStyles.urduCaption,
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final product = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20),
                                  title: Text(product.displayName, style: AppTextStyles.urduBody.copyWith(fontSize: 14)),
                                  subtitle: Text('${AppFormatters.currency(product.salePrice)} | Stock: ${product.stockQuantity}',
                                      style: const TextStyle(fontSize: 11)),
                                  onTap: () => onSelected(product),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
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
                    loading: () => GridView.builder(
                      padding: const EdgeInsets.all(AppDimens.spacingMD),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 8,
                      itemBuilder: (_, __) => CustomSkeleton(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 12,
                      ),
                    ),
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
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(left: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkDivider : AppColors.lightDivider)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                  blurRadius: 24,
                  offset: const Offset(-8, 0),
                ),
              ],
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
                      Expanded(
                        child: Text(
                          '${AppStrings.isUrdu ? "ٹوکری" : "Cart"} (${_cart.length})',
                          style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_cart.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 20, color: AppColors.moneyOwed),
                          onPressed: () => setState(() => _cart.clear()),
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
                        if (_taxAmount > 0) _TotalRow(AppStrings.tax, _taxAmount),
                        const Divider(),
                        _TotalRow(AppStrings.total, _subtotal + _taxAmount, isBold: true, fontSize: 20),
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
                            onPressed: () => _showCheckoutSummaryDialog(context),
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

  void _showCheckoutSummaryDialog(BuildContext context) {
    if (_cart.isEmpty) return;
    
    // Dialog state
    double discountAmount = 0;
    double discountPercentage = 0;
    bool isPercentage = false;
    DateTime selectedDate = DateTime.now();
    bool isWalkIn = _selectedCustomerId == null;
    final totalWithoutDiscount = _subtotal + _taxAmount;
    String localPaymentType = _paymentType;
    double partialAmountReceived = 0;
    final partialController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            double currentTotal = totalWithoutDiscount - discountAmount;
            if (currentTotal < 0) currentTotal = 0;
            
            double amountPaid = localPaymentType == 'CASH' ? currentTotal
                : localPaymentType == 'PARTIAL' ? partialAmountReceived
                : 0;
            double balanceDue = currentTotal - amountPaid;
            if (balanceDue < 0) balanceDue = 0;

            return AlertDialog(
              title: Text(AppStrings.isUrdu ? 'بل تفصیل' : 'Checkout Summary', style: AppTextStyles.title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Walk-in Toggle
                    SwitchListTile(
                      title: Text(AppStrings.isUrdu ? 'عام گاہک (بغیر فون)' : 'Walk-in Customer (No Phone)', style: AppTextStyles.body),
                      value: isWalkIn,
                      onChanged: (val) => setStateBuilder(() => isWalkIn = val),
                    ),
                    const Divider(),
                    // Date picker
                    ListTile(
                      title: Text('${AppStrings.isUrdu ? "تاریخ" : "Date"}: ${AppFormatters.date(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setStateBuilder(() => selectedDate = picked);
                      },
                    ),
                    const Divider(),
                    // Discount section
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(AppStrings.isUrdu ? '% میں چھوٹ' : 'Discount in %', style: AppTextStyles.body),
                            value: isPercentage,
                            onChanged: (val) {
                              setStateBuilder(() {
                                isPercentage = val;
                                discountAmount = 0;
                                discountPercentage = 0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: isPercentage
                          ? (AppStrings.isUrdu ? 'چھوٹ فی صد (%)' : 'Discount Percentage (%)')
                          : (AppStrings.isUrdu ? 'چھوٹ رقم (Rs)' : 'Discount Amount (Rs)'),
                        prefixIcon: Icon(isPercentage ? Icons.percent : Icons.money_off),
                      ),
                      onChanged: (val) {
                        final numValue = double.tryParse(val) ?? 0;
                        setStateBuilder(() {
                          if (isPercentage) {
                            discountPercentage = numValue.clamp(0, 100);
                            discountAmount = _subtotal * (discountPercentage / 100);
                          } else {
                            discountAmount = numValue;
                            discountPercentage = (_subtotal > 0) ? (discountAmount / _subtotal) * 100 : 0;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // ═══ PAYMENT TYPE ═══
                    Text(
                      AppStrings.isUrdu ? 'ادائیگی کا طریقہ' : 'Payment Method',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _paymentChip('CASH', AppStrings.isUrdu ? '💵 نقد' : '💵 Cash', localPaymentType, AppColors.moneyReceived, (v) => setStateBuilder(() => localPaymentType = v)),
                        const SizedBox(width: 6),
                        _paymentChip('CREDIT', AppStrings.isUrdu ? '📋 ادھار' : '📋 Udhaar', localPaymentType, AppColors.moneyOwed, (v) => setStateBuilder(() => localPaymentType = v)),
                        const SizedBox(width: 6),
                        _paymentChip('PARTIAL', AppStrings.isUrdu ? '➗ جزوی' : '➗ Partial', localPaymentType, AppColors.warning, (v) => setStateBuilder(() => localPaymentType = v)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // ═══ PARTIAL PAYMENT AMOUNT ═══
                    if (localPaymentType == 'PARTIAL') ...[
                      TextField(
                        controller: partialController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppStrings.isUrdu ? 'کتنا موصول ہوا (Rs)' : 'Amount Received (Rs)',
                          prefixText: 'Rs. ',
                          prefixIcon: const Icon(Icons.payments_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.warning, width: 2),
                          ),
                        ),
                        onChanged: (val) {
                          setStateBuilder(() {
                            partialAmountReceived = double.tryParse(val) ?? 0;
                            if (partialAmountReceived > currentTotal) partialAmountReceived = currentTotal;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.moneyOwed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppStrings.isUrdu ? 'باقی رقم:' : 'Balance Due:', style: AppTextStyles.body.copyWith(color: AppColors.moneyOwed)),
                            Text(AppFormatters.currency(balanceDue), style: AppTextStyles.amountSmall.copyWith(color: AppColors.moneyOwed)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Final Total
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppStrings.isUrdu ? 'کل رقم:' : 'Final Total:', style: AppTextStyles.title),
                              Text(AppFormatters.currency(currentTotal), style: AppTextStyles.amountMedium.copyWith(color: AppColors.primary)),
                            ],
                          ),
                          if (localPaymentType != 'CASH') ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppStrings.isUrdu ? 'ادا:' : 'Paid:', style: AppTextStyles.caption),
                                Text(AppFormatters.currency(amountPaid), style: AppTextStyles.caption.copyWith(color: AppColors.moneyReceived)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppStrings.isUrdu ? 'باقی:' : 'Due:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                                Text(AppFormatters.currency(balanceDue), style: AppTextStyles.caption.copyWith(color: AppColors.moneyOwed, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (isWalkIn) _selectedCustomerId = null;
                    setState(() => _paymentType = localPaymentType);
                    _finalizeSaleWithPayment(selectedDate, discountAmount, discountPercentage, currentTotal, amountPaid, balanceDue);
                  },
                  child: Text(AppStrings.isUrdu ? 'بل بنائیں' : 'Confirm Sale'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _paymentChip(String value, String label, String selected, Color color, Function(String) onSelect) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : AppColors.divider, width: isSelected ? 2 : 1),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? color : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  Future<void> _finalizeSale(DateTime date, double discountAmount, double discountPercentage, double finalTotal) async {
    // backward-compat: redirect to the new method
    double amountPaid = _paymentType == 'CASH' ? finalTotal : 0;
    double balanceDue = finalTotal - amountPaid;
    await _finalizeSaleWithPayment(date, discountAmount, discountPercentage, finalTotal, amountPaid, balanceDue);
  }

  Future<void> _finalizeSaleWithPayment(DateTime date, double discountAmount, double discountPercentage, double finalTotal, double amountPaid, double balanceDue) async {
    final db = ref.read(databaseProvider);
    final saleItems = _cart.map((item) => SaleItem(
      saleId: '',
      productId: item.product.id,
      productName: item.product.displayName,
      quantity: item.quantity,
      purchasePrice: item.product.purchasePrice,
      salePrice: item.product.salePrice,
    )).toList();

    final sale = Sale(
      date: date,
      subtotal: _subtotal,
      discount: discountAmount,
      discountPercentage: discountPercentage,
      tax: _taxAmount,
      total: finalTotal,
      profit: _totalProfit - discountAmount,
      paymentType: _paymentType,
      amountPaid: amountPaid,
      balanceDue: balanceDue,
      customerId: _selectedCustomerId,
    );

    final linkedItems = saleItems.map((item) => SaleItem(
      saleId: sale.id,
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      purchasePrice: item.purchasePrice,
      salePrice: item.salePrice,
    )).toList();

    await db.insertSale(sale, linkedItems);

    // Invalidate providers
    ref.invalidate(todaySalesProvider);
    ref.invalidate(todayProfitProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(lowStockProductsProvider);
    ref.invalidate(totalReceivableProvider);

    final savedTaxAmount = _taxAmount;
    final savedSubtotal = _subtotal;
    final savedPaymentType = _paymentType;

    setState(() {
      _cart.clear();
      _paymentType = 'CASH';
      _selectedCustomerId = null;
    });

    if (mounted) {
      _showBillOptionsDialog(
        sale: sale,
        items: linkedItems,
        subtotal: savedSubtotal,
        discount: discountAmount,
        taxAmount: savedTaxAmount,
        total: finalTotal,
        paymentType: savedPaymentType,
        selectedDate: date,
      );
    }
  }

  void _showBillOptionsDialog({
    required Sale sale,
    required List<SaleItem> items,
    required double subtotal,
    required double discount,
    required double taxAmount,
    required double total,
    required String paymentType,
    required DateTime selectedDate,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.moneyReceived, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.isUrdu ? 'بل بن گیا! ${AppFormatters.currency(total)}' : 'Bill Created! ${AppFormatters.currency(total)}',
                style: AppTextStyles.urduTitle.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Print option
            _BillOptionTile(
              icon: Icons.print_rounded,
              color: AppColors.primary,
              title: AppStrings.isUrdu ? 'پرنٹ کریں' : 'Print Bill',
              subtitle: AppStrings.isUrdu ? 'منسلک پرنٹر سے' : 'Via attached printer',
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final pdfBytes = await _generateBillPdf(sale, items, subtotal, discount, sale.discountPercentage, taxAmount, total, paymentType, selectedDate);
                  await Printing.layoutPdf(onLayout: (_) => pdfBytes);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Print error: $e'), backgroundColor: AppColors.moneyOwed),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),

            // PDF Export option
            _BillOptionTile(
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.moneyOwed,
              title: AppStrings.isUrdu ? 'PDF محفوظ کریں' : 'Save as PDF',
              subtitle: AppStrings.isUrdu ? 'ڈاؤن لوڈ / محفوظ' : 'Download / save',
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final pdfBytes = await _generateBillPdf(sale, items, subtotal, discount, sale.discountPercentage, taxAmount, total, paymentType, selectedDate);
                  await Printing.sharePdf(bytes: pdfBytes, filename: 'bill_${sale.id.substring(0, 8)}.pdf');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF error: $e'), backgroundColor: AppColors.moneyOwed),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),

            // Share via social media
            _BillOptionTile(
              icon: Icons.share_rounded,
              color: AppColors.info,
              title: AppStrings.isUrdu ? 'شیئر کریں' : 'Share Bill',
              subtitle: AppStrings.isUrdu ? 'واٹس ایپ / سوشل میڈیا' : 'WhatsApp / Social Media',
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final pdfBytes = await _generateBillPdf(sale, items, subtotal, discount, sale.discountPercentage, taxAmount, total, paymentType, selectedDate);
                  if (!kIsWeb) {
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/bill_${sale.id.substring(0, 8)}.pdf');
                    await file.writeAsBytes(pdfBytes);
                    await Share.shareXFiles([XFile(file.path)], text: AppStrings.isUrdu ? 'بل — ${AppFormatters.currency(total)}' : 'Bill — ${AppFormatters.currency(total)}');
                  } else {
                    await Printing.sharePdf(bytes: pdfBytes, filename: 'bill_${sale.id.substring(0, 8)}.pdf');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Share error: $e'), backgroundColor: AppColors.moneyOwed),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.isUrdu ? 'بعد میں' : 'Later'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generateBillPdf(
    Sale sale,
    List<SaleItem> items,
    double subtotal,
    double discount,
    double discountPercentage,
    double taxAmount,
    double total,
    String paymentType,
    DateTime selectedDate,
  ) async {
    return await PdfExportService.generateBill(
      shopName: 'Super Business Shop',
      shopPhone: '',
      billNo: sale.id.substring(0, 8).toUpperCase(),
      customerName: sale.customerId != null ? 'Customer' : 'Walk-in Customer',
      items: items,
      subtotal: subtotal,
      discount: discount,
      discountPercentage: discountPercentage,
      tax: taxAmount,
      total: total,
      amountPaid: sale.amountPaid,
      balanceDue: sale.balanceDue,
      paymentType: paymentType,
      date: selectedDate,
    );
  }
}

class _CartItem {
  final Product product;
  final double quantity;

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkDivider : AppColors.lightDivider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
  final Function(double) onQuantityChanged;
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
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final qtyCtrl = TextEditingController(text: item.quantity.toString());
                      final priceCtrl = TextEditingController(text: (item.quantity * item.product.salePrice).toStringAsFixed(2));

                      return AlertDialog(
                        title: Text(AppStrings.isUrdu ? 'مقدار یا رقم درج کریں' : 'Enter Quantity or Price'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: AppStrings.isUrdu ? 'مقدار' : 'Quantity',
                                prefixIcon: const Icon(Icons.scale),
                              ),
                              onChanged: (val) {
                                final q = double.tryParse(val) ?? 0;
                                priceCtrl.text = (q * item.product.salePrice).toStringAsFixed(2);
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('OR / یا', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: AppStrings.isUrdu ? 'کل رقم' : 'Total Price',
                                prefixIcon: const Icon(Icons.attach_money),
                                prefixText: 'Rs. ',
                              ),
                              onChanged: (val) {
                                final p = double.tryParse(val) ?? 0;
                                if (item.product.salePrice > 0) {
                                  qtyCtrl.text = (p / item.product.salePrice).toStringAsFixed(3);
                                }
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
                          ElevatedButton(
                            onPressed: () {
                              final numValue = double.tryParse(qtyCtrl.text);
                              if (numValue != null && numValue > 0) {
                                onQuantityChanged(numValue);
                              }
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            child: Text(AppStrings.save),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(AppFormatters.quantity(item.quantity), style: AppTextStyles.amountSmall.copyWith(fontSize: 14)),
                ),
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

class _BillOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BillOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
