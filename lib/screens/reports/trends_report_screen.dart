import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/skeleton_loader.dart';

/// Weekly/Monthly Trends — bar chart of sales and profits over time.
class TrendsReportScreen extends ConsumerStatefulWidget {
  const TrendsReportScreen({super.key});

  @override
  ConsumerState<TrendsReportScreen> createState() => _TrendsReportScreenState();
}

class _TrendsReportScreenState extends ConsumerState<TrendsReportScreen> {
  bool _showWeek = true;
  bool _loading = true;
  List<Map<String, dynamic>> _data = [];
  double _totalSales = 0;
  double _totalExpenses = 0;
  int _salesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final start = _showWeek
      ? now.subtract(const Duration(days: 7))
      : DateTime(now.year, now.month, 1);

    try {
      final data = await db.getDailySalesBreakdown(start, now);
      final sales = await db.getSalesTotalByDateRange(start, now);
      final expenses = await db.getExpenseTotalByDateRange(start, now);
      final count = await db.getSalesCountByDateRange(start, now);
      setState(() {
        _data = data;
        _totalSales = sales;
        _totalExpenses = expenses;
        _salesCount = count;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'بکری کے رجحانات' : 'Sales Trends',
      ),
      body: _loading
        ? Padding(
            padding: const EdgeInsets.all(AppDimens.spacingMD),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 50, borderRadius: 8)),
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 50, borderRadius: 8)),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingMD),
                Row(
                  children: [
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 80, borderRadius: 12)),
                    const SizedBox(width: 8),
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 80, borderRadius: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 80, borderRadius: 12)),
                    const SizedBox(width: 8),
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 80, borderRadius: 12)),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingLG),
                const CustomSkeleton(width: double.infinity, height: 250, borderRadius: 12),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Toggle Week / Month
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () { setState(() => _showWeek = true); _loadData(); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showWeek ? AppColors.primary : AppColors.surface,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.isUrdu ? '7 دن' : '7 Days',
                              style: TextStyle(
                                color: _showWeek ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () { setState(() => _showWeek = false); _loadData(); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_showWeek ? AppColors.primary : AppColors.surface,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.isUrdu ? '30 دن' : '30 Days',
                              style: TextStyle(
                                color: !_showWeek ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingMD),
                
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        AppStrings.isUrdu ? '💰 کل بکری' : '💰 Total Sales',
                        AppFormatters.currency(_totalSales),
                        AppColors.moneyReceived,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                        AppStrings.isUrdu ? '🧾 بل بنائے' : '🧾 Bills Made',
                        '$_salesCount',
                        AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        AppStrings.isUrdu ? '📊 خرچے' : '📊 Expenses',
                        AppFormatters.currency(_totalExpenses),
                        AppColors.moneyOwed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statCard(
                        AppStrings.isUrdu ? '✅ منافع' : '✅ Profit',
                        AppFormatters.currency(_totalSales - _totalExpenses),
                        _totalSales - _totalExpenses >= 0 ? AppColors.moneyReceived : AppColors.moneyOwed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingLG),
                
                // Chart
                if (_data.isNotEmpty) ...[
                  Text(
                    AppStrings.isUrdu ? 'روزانہ بکری' : 'Daily Sales',
                    style: AppTextStyles.urduTitle,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                AppFormatters.currency(rod.toY),
                                const TextStyle(color: Colors.white, fontSize: 12),
                              );
                            },
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < _data.length) {
                                  final day = _data[idx]['day'] as String;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(day.substring(8), style: const TextStyle(fontSize: 10)),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(_data.length, (i) {
                          final sales = (_data[i]['total_sales'] as num).toDouble();
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: sales,
                                color: AppColors.moneyReceived,
                                width: _showWeek ? 20 : 8,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.urduCaption.copyWith(fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.amountSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
