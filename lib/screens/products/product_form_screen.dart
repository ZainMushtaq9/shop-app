import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';

/// Add / Edit product form screen.
/// All fields have Urdu labels, big input areas, and numeric keypads for prices.
class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product; // null = Add mode, non-null = Edit mode

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameUrduController;
  late TextEditingController _nameEnglishController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _barcodeController;
  String _selectedCategory = AppConstants.defaultCategories.first;
  bool _isSaving = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameUrduController = TextEditingController(text: p?.nameUrdu ?? '');
    _nameEnglishController = TextEditingController(text: p?.nameEnglish ?? '');
    _purchasePriceController =
        TextEditingController(text: p?.purchasePrice.toStringAsFixed(0) ?? '');
    _salePriceController =
        TextEditingController(text: p?.salePrice.toStringAsFixed(0) ?? '');
    _stockController =
        TextEditingController(text: p?.stockQuantity.toString() ?? '0');
    _minStockController =
        TextEditingController(text: p?.minStockAlert.toString() ?? '5');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _selectedCategory = p?.category ?? AppConstants.defaultCategories.first;
  }

  @override
  void dispose() {
    _nameUrduController.dispose();
    _nameEnglishController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: isEdit ? AppStrings.editProduct : AppStrings.addProduct,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Product Name (Urdu) ──
              _buildLabel(AppStrings.productName, isRequired: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameUrduController,
                style: AppTextStyles.urduBody,
                decoration: InputDecoration(
                  hintText: AppStrings.isUrdu ? 'مصنوع کا نام لکھیں' : 'Enter product name',
                  hintStyle: AppTextStyles.urduCaption,
                  prefixIcon: const Icon(Icons.edit_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.isUrdu ? 'نام ضروری ہے' : 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.spacingMD),

              // ── Product Name (English) ──
              _buildLabel(AppStrings.productNameEnglish),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameEnglishController,
                decoration: InputDecoration(
                  hintText: 'English name (optional)',
                  prefixIcon: const Icon(Icons.language_rounded),
                ),
              ),
              const SizedBox(height: AppDimens.spacingMD),

              // ── Prices Row ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(AppStrings.purchasePrice, isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: '0',
                            prefixIcon: const Icon(Icons.shopping_bag_outlined),
                            prefixText: 'Rs. ',
                          ),
                          style: AppTextStyles.amountSmall,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.isUrdu ? 'ضروری' : 'Required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(AppStrings.salePrice, isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _salePriceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: '0',
                            prefixIcon: const Icon(Icons.sell_outlined),
                            prefixText: 'Rs. ',
                          ),
                          style: AppTextStyles.amountSmall,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.isUrdu ? 'ضروری' : 'Required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacingMD),

              // ── Profit preview ──
              Builder(builder: (context) {
                final purchase = double.tryParse(_purchasePriceController.text) ?? 0;
                final sale = double.tryParse(_salePriceController.text) ?? 0;
                final profit = sale - purchase;
                if (purchase > 0 && sale > 0) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: profit >= 0
                          ? AppColors.moneyReceived.withOpacity(0.1)
                          : AppColors.moneyOwed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          profit >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: profit >= 0
                              ? AppColors.moneyReceived
                              : AppColors.moneyOwed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${AppStrings.isUrdu ? "منافع" : "Profit"}: ${AppFormatters.currency(profit)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: profit >= 0
                                ? AppColors.moneyReceived
                                : AppColors.moneyOwed,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: AppDimens.spacingMD),

              // ── Stock Row ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(AppStrings.stockQuantity),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixIcon: Icon(Icons.inventory_rounded),
                          ),
                          style: AppTextStyles.amountSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(AppStrings.minStockAlert),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _minStockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            hintText: '5',
                            prefixIcon: Icon(Icons.notifications_active_outlined),
                          ),
                          style: AppTextStyles.amountSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacingMD),

              // ── Category ──
              _buildLabel(AppStrings.category),
              const SizedBox(height: 8),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _selectedCategory),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return AppConstants.defaultCategories;
                  }
                  return AppConstants.defaultCategories.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _selectedCategory = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.addListener(() {
                    _selectedCategory = controller.text;
                  });
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: AppTextStyles.urduBody,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category_rounded),
                      hintText: AppStrings.isUrdu ? 'منتخب کریں یا نیا درج کریں' : 'Select or type custom category',
                      hintStyle: AppTextStyles.urduCaption,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimens.spacingMD),

              // ── Barcode ──
              _buildLabel(AppStrings.barcode),
              const SizedBox(height: 8),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  hintText: AppStrings.isUrdu ? 'اختیاری' : 'Optional',
                  prefixIcon: const Icon(Icons.qr_code_rounded),
                ),
              ),
              const SizedBox(height: AppDimens.spacingXL),

              // ── Save Button ──
              SizedBox(
                height: AppDimens.minTouchTarget,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProduct,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    AppStrings.save,
                    style: AppTextStyles.urduBody.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spacingLG),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(text, style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.w600)),
        if (isRequired)
          const Text(' *', style: TextStyle(color: AppColors.moneyOwed, fontSize: 16)),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);

      final product = Product(
        id: widget.product?.id,
        nameUrdu: _nameUrduController.text.trim(),
        nameEnglish: _nameEnglishController.text.trim(),
        category: _selectedCategory,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
        salePrice: double.tryParse(_salePriceController.text) ?? 0,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        minStockAlert: int.tryParse(_minStockController.text) ?? 5,
        barcode: _barcodeController.text.trim().isNotEmpty
            ? _barcodeController.text.trim()
            : null,
        isActive: true,
        createdAt: widget.product?.createdAt,
      );

      if (isEdit) {
        await db.updateProduct(product);
      } else {
        await db.insertProduct(product);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.error}: $e'),
            backgroundColor: AppColors.moneyOwed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
