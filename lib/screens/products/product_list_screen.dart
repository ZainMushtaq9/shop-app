import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../../widgets/skeleton_loader.dart';
import 'product_form_screen.dart';

/// Product list screen with search, category filter, and swipe-to-delete.
/// Accessible from bottom nav tab "مال" (Stock).
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(productSearchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final asyncProducts = searchQuery.isNotEmpty
        ? ref.watch(productSearchProvider(searchQuery))
        : selectedCategory != null
            ? ref.watch(productsByCategoryProvider(selectedCategory))
            : ref.watch(productsProvider);

    return Scaffold(
      body: Column(
        children: [
          // Search bar + Category filter
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingMD),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: AppStrings.searchProducts,
                    hintStyle: AppTextStyles.urduCaption,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              ref.read(productSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    ref.read(productSearchQueryProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: AppDimens.spacingSM),
                // Category chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: AppStrings.isUrdu ? 'سب' : 'All',
                        isSelected: selectedCategory == null,
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state = null;
                        },
                      ),
                      ...ref.watch(productCategoriesProvider).maybeWhen(
                            data: (cats) => cats.map((cat) => _CategoryChip(
                              label: cat,
                              isSelected: selectedCategory == cat,
                              onTap: () {
                                ref.read(selectedCategoryProvider.notifier).state = cat;
                              },
                            )),
                            orElse: () => AppConstants.defaultCategories.map((cat) => _CategoryChip(
                              label: cat,
                              isSelected: selectedCategory == cat,
                              onTap: () {
                                ref.read(selectedCategoryProvider.notifier).state = cat;
                              },
                            )),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product list
          Expanded(
            child: asyncProducts.when(
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingSM),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _ProductTile(
                      product: products[index],
                      onTap: () => _navigateToEditProduct(context, ref, products[index]),
                      onDelete: () => _deleteProduct(context, ref, products[index]),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingSM),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingMD, vertical: AppDimens.spacingXS),
                  child: CustomSkeleton(width: double.infinity, height: 72, borderRadius: 12),
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.moneyOwed),
                    const SizedBox(height: 16),
                    Text(AppStrings.error, style: AppTextStyles.urduBody),
                    TextButton(
                      onPressed: () => ref.invalidate(productsProvider),
                      child: Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddProduct(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          AppStrings.addProduct,
          style: AppTextStyles.urduBody.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _navigateToAddProduct(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (result == true) {
      ref.invalidate(productsProvider);
      ref.invalidate(lowStockProductsProvider);
    }
  }

  void _navigateToEditProduct(BuildContext context, WidgetRef ref, Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (result == true) {
      ref.invalidate(productsProvider);
      ref.invalidate(lowStockProductsProvider);
    }
  }

  void _deleteProduct(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.deleteConfirmTitle, style: AppTextStyles.urduTitle),
        content: Text(AppStrings.deleteConfirmMessage, style: AppTextStyles.urduBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseProvider);
              await db.deleteProduct(product.id);
              ref.invalidate(productsProvider);
              ref.invalidate(lowStockProductsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${product.displayName} ${AppStrings.isUrdu ? "حذف ہو گیا" : "deleted"}',
                    ),
                    action: SnackBarAction(
                      label: AppStrings.undoMessage,
                      onPressed: () async {
                        // Re-insert (undo soft delete)
                        await db.insertProduct(product.copyWith(isActive: true));
                        ref.invalidate(productsProvider);
                      },
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.moneyOwed),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

/// Single product tile in the list
class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingMD,
        vertical: AppDimens.spacingXS,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingMD),
          child: Row(
            children: [
              // Product icon/image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: product.isLowStock
                      ? AppColors.moneyOwed.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: product.isLowStock ? AppColors.moneyOwed : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimens.spacingMD),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.displayName,
                      style: AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${AppStrings.salePrice}: ${AppFormatters.currency(product.salePrice)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${AppStrings.category}: ${product.category}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stock badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: product.isLowStock
                      ? AppColors.moneyOwed.withOpacity(0.1)
                      : AppColors.moneyReceived.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${product.stockQuantity}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: product.isLowStock
                        ? AppColors.moneyOwed
                        : AppColors.moneyReceived,
                  ),
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.disabled),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state when no products exist
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.disabled),
          const SizedBox(height: 16),
          Text(
            AppStrings.isUrdu ? 'ابھی کوئی مصنوعات نہیں' : 'No products yet',
            style: AppTextStyles.urduTitle.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.isUrdu
                ? 'نیا مصنوع شامل کرنے کے لیے + بٹن دبائیں'
                : 'Tap + to add your first product',
            style: AppTextStyles.urduCaption,
          ),
        ],
      ),
    );
  }
}

/// Category filter chip
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceVariant,
        onSelected: (_) => onTap(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
