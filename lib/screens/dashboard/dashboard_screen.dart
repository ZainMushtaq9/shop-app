import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';

/// Dashboard — the main home screen showing today's summary.
/// Matches the dashboard layout from Section 09 of requirements:
///   Row 1: Today's Sales (GREEN) | Today's Profit (BLUE)
///   Row 2: Receivable (GREEN)    | Payable (RED)
///   Row 3: 7-day Sales vs Profit bar chart
///   Row 4: Low Stock Alerts list
///   FAB: "نئی فروخت" (New Sale) button
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate all dashboard providers to refresh data
          ref.invalidate(todaySalesProvider);
          ref.invalidate(todayProfitProvider);
          ref.invalidate(totalReceivableProvider);
          ref.invalidate(totalPayableProvider);
          ref.invalidate(weeklySalesProfitProvider);
          ref.invalidate(lowStockProductsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimens.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Sales & Profit Cards ──
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: AppStrings.todaySales,
                      icon: Icons.trending_up_rounded,
                      gradient: AppColors.salesGradient,
                      provider: todaySalesProvider,
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingSM),
                  Expanded(
                    child: _SummaryCard(
                      title: AppStrings.todayProfit,
                      icon: Icons.account_balance_rounded,
                      gradient: AppColors.profitGradient,
                      provider: todayProfitProvider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacingSM),

              // ── Row 2: Receivable & Payable Cards ──
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: AppStrings.totalReceivable,
                      icon: Icons.arrow_downward_rounded,
                      gradient: AppColors.receivableGradient,
                      provider: totalReceivableProvider,
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingSM),
                  Expanded(
                    child: _SummaryCard(
                      title: AppStrings.totalPayable,
                      icon: Icons.arrow_upward_rounded,
                      gradient: AppColors.payableGradient,
                      provider: totalPayableProvider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacingLG),

              // ── Quick Actions Row ──
              _QuickActions(),
              const SizedBox(height: AppDimens.spacingLG),

              // ── Row 3: Weekly Sales vs Profit Chart ──
              _WeeklyChart(),
              const SizedBox(height: AppDimens.spacingLG),

              // ── Row 4: Low Stock Alerts ──
              _LowStockAlerts(),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to POS tab
          ref.read(currentTabProvider.notifier).state = 1;
        },
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 28),
        label: Text(
          AppStrings.newSale,
          style: AppTextStyles.urduBody.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Summary card with gradient background, icon, title, and amount
class _SummaryCard extends ConsumerWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final FutureProvider<double> provider;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider);

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.urduCaption.copyWith(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          asyncValue.when(
            data: (amount) => Text(
              AppStrings.formatAmount(amount),
              style: AppTextStyles.amountLarge.copyWith(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            loading: () => const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
            error: (_, __) => Text(
              'Rs. 0',
              style: AppTextStyles.amountLarge.copyWith(
                color: Colors.white54,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action buttons row
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _QuickActionButton(
              icon: Icons.add_shopping_cart_rounded,
              label: AppStrings.newSale,
              color: AppColors.moneyReceived,
              onTap: () {},
            ),
            const SizedBox(width: AppDimens.spacingSM),
            _QuickActionButton(
              icon: Icons.add_box_rounded,
              label: AppStrings.addProduct,
              color: AppColors.primary,
              onTap: () {
                Navigator.pushNamed(context, '/products/add');
              },
            ),
            const SizedBox(width: AppDimens.spacingSM),
            _QuickActionButton(
              icon: Icons.payments_rounded,
              label: AppStrings.receivePayment,
              color: AppColors.moneyReceived,
              onTap: () {},
            ),
            const SizedBox(width: AppDimens.spacingSM),
            _QuickActionButton(
              icon: Icons.send_rounded,
              label: AppStrings.makePayment,
              color: AppColors.warning,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.urduCaption.copyWith(
                  color: color,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Weekly sales vs profit bar chart using fl_chart
class _WeeklyChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(weeklySalesProfitProvider);

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.salesVsProfit,
            style: AppTextStyles.urduTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppDimens.spacingMD),
          SizedBox(
            height: 180,
            child: asyncData.when(
              data: (data) => _buildChart(data),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => Center(
                child: Text(
                  AppStrings.noData,
                  style: AppTextStyles.urduCaption,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.moneyReceived, label: AppStrings.todaySales),
              const SizedBox(width: 24),
              _LegendDot(color: AppColors.primary, label: AppStrings.todayProfit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noData,
          style: AppTextStyles.urduCaption,
        ),
      );
    }

    final maxSales = data.fold<double>(
        0, (max, d) => ((d['total_sales'] as num?)?.toDouble() ?? 0) > max
            ? ((d['total_sales'] as num?)?.toDouble() ?? 0)
            : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxSales > 0 ? maxSales * 1.2 : 1000,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                final day = data[index]['day'] as String;
                // Show just the day number
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    day.substring(8),
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(data.length, (index) {
          final sales = (data[index]['total_sales'] as num?)?.toDouble() ?? 0;
          final profit = (data[index]['total_profit'] as num?)?.toDouble() ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: sales,
                color: AppColors.moneyReceived,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: profit,
                color: AppColors.primary,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Low stock alerts list
class _LowStockAlerts extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(lowStockProductsProvider);

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Text(
                AppStrings.lowStockAlerts,
                style: AppTextStyles.urduTitle.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          asyncProducts.when(
            data: (products) {
              if (products.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      AppStrings.isUrdu
                          ? 'سب ٹھیک ہے! کوئی کم اسٹاک نہیں'
                          : 'All good! No low stock items',
                      style: AppTextStyles.urduCaption,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length > 5 ? 5 : products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.moneyOwed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${product.stockQuantity}',
                          style: AppTextStyles.amountSmall.copyWith(
                            color: AppColors.moneyOwed,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      product.displayName,
                      style: AppTextStyles.urduBody.copyWith(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${AppStrings.minStockAlert}: ${product.minStockAlert}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.disabled,
                    ),
                  );
                },
              );
            },
            loading: () => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD, vertical: AppDimens.spacingXS),
                child: CustomSkeleton(width: double.infinity, height: 60, borderRadius: 8),
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(AppStrings.error, style: AppTextStyles.urduCaption),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
