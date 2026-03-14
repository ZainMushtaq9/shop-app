import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/skeleton_loader.dart';

/// Munafa Nuqsan — Simple P&L screen for shopkeepers.
/// Shows: Kul Bikri, Maal ki Lagat, Kharche, Asal Munafa.
class MunafaNuqsanScreen extends ConsumerStatefulWidget {
  const MunafaNuqsanScreen({super.key});

  @override
  ConsumerState<MunafaNuqsanScreen> createState() => _MunafaNuqsanScreenState();
}

class _MunafaNuqsanScreenState extends ConsumerState<MunafaNuqsanScreen> {
  String _selectedFilter = 'today';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _loading = true;

  // Data
  double _totalSales = 0;
  double _costOfGoods = 0;
  double _totalExpenses = 0;
  double _grossProfit = 0;
  double _netProfit = 0;
  List<Map<String, dynamic>> _dailyData = [];
  List<Map<String, dynamic>> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _setFilter('today');
  }

  void _setFilter(String filter) {
    final now = DateTime.now();
    setState(() => _selectedFilter = filter);
    switch (filter) {
      case 'today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'custom':
        return; // handled by date picker
    }
    _loadData();
  }

  Future<void> _pickCustomDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _selectedFilter = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    try {
      final sales = await db.getSalesTotalByDateRange(_startDate, _endDate);
      final cost = await db.getCostByDateRange(_startDate, _endDate);
      final expenses = await db.getExpenseTotalByDateRange(_startDate, _endDate);
      final daily = await db.getDailySalesBreakdown(_startDate, _endDate);
      final categories = await db.getExpensesByCategory(_startDate, _endDate);
      
      setState(() {
        _totalSales = sales;
        _costOfGoods = cost;
        _totalExpenses = expenses;
        _grossProfit = sales - cost;
        _netProfit = sales - cost - expenses;
        _dailyData = daily;
        _expenseCategories = categories;
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
        title: AppStrings.isUrdu ? 'منافع نقصان / Munafa Nuqsan' : 'Profit & Loss',
      ),
      body: _loading
        ? Padding(
            padding: const EdgeInsets.all(AppDimens.spacingMD),
            child: Column(
              children: [
                const CustomSkeleton(width: double.infinity, height: 40, borderRadius: 20),
                const SizedBox(height: AppDimens.spacingMD),
                const CustomSkeleton(width: double.infinity, height: 180, borderRadius: 16),
                const SizedBox(height: AppDimens.spacingMD),
                Row(
                  children: [
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 100, borderRadius: 12)),
                    const SizedBox(width: AppDimens.spacingSM),
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 100, borderRadius: 12)),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingSM),
                Row(
                  children: [
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 100, borderRadius: 12)),
                    const SizedBox(width: AppDimens.spacingSM),
                    const Expanded(child: CustomSkeleton(width: double.infinity, height: 100, borderRadius: 12)),
                  ],
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date filter chips
                _buildDateFilters(),
                const SizedBox(height: AppDimens.spacingMD),
                
                // Big profit/loss card
                _buildMainProfitCard(),
                const SizedBox(height: AppDimens.spacingMD),
                
                // Summary cards
                _buildSummaryCards(),
                const SizedBox(height: AppDimens.spacingMD),
                
                // Calculation breakdown
                _buildCalculationBreakdown(),
                const SizedBox(height: AppDimens.spacingMD),
                
                // Expense breakdown
                if (_expenseCategories.isNotEmpty) ...[
                  _buildExpenseBreakdown(),
                  const SizedBox(height: AppDimens.spacingMD),
                ],
                
                // Daily chart
                if (_dailyData.length > 1) ...[
                  _buildDailyChart(),
                  const SizedBox(height: AppDimens.spacingMD),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildDateFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('today', AppStrings.isUrdu ? 'آج' : 'Today'),
          const SizedBox(width: 8),
          _filterChip('week', AppStrings.isUrdu ? 'اس ہفتے' : 'This Week'),
          const SizedBox(width: 8),
          _filterChip('month', AppStrings.isUrdu ? 'اس مہینے' : 'This Month'),
          const SizedBox(width: 8),
          ActionChip(
            label: Text(
              _selectedFilter == 'custom'
                ? '${AppFormatters.dateShort(_startDate)} – ${AppFormatters.dateShort(_endDate)}'
                : (AppStrings.isUrdu ? 'اپنی تاریخ' : 'Custom'),
              style: TextStyle(
                color: _selectedFilter == 'custom' ? Colors.white : AppColors.textPrimary,
                fontWeight: _selectedFilter == 'custom' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            backgroundColor: _selectedFilter == 'custom' ? AppColors.primary : AppColors.surface,
            onPressed: _pickCustomDates,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      onSelected: (_) => _setFilter(key),
    );
  }

  Widget _buildMainProfitCard() {
    final isProfit = _netProfit >= 0;
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
            ? [const Color(0xFF198754), const Color(0xFF20C997)]
            : [const Color(0xFFDC3545), const Color(0xFFE8596A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      ),
      child: Column(
        children: [
          Icon(
            isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            isProfit
              ? (AppStrings.isUrdu ? '🟢 اصل منافع' : '🟢 Net Profit')
              : (AppStrings.isUrdu ? '🔴 نقصان' : '🔴 Net Loss'),
            style: AppTextStyles.urduTitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.currency(_netProfit.abs()),
            style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 36),
          ),
          const SizedBox(height: 8),
          Text(
            isProfit
              ? (AppStrings.isUrdu ? 'آپ نے فائدہ کمایا!' : 'You earned profit!')
              : (AppStrings.isUrdu ? 'نقصان ہوا - خرچے کم کریں' : 'Loss occurred - reduce expenses'),
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Wrap(
      spacing: AppDimens.spacingSM,
      runSpacing: AppDimens.spacingSM,
      children: [
        _summaryCard(
          icon: Icons.shopping_bag_rounded,
          label: AppStrings.isUrdu ? '💰 کل بکری' : '💰 Total Sales',
          amount: _totalSales,
          color: AppColors.info,
        ),
        _summaryCard(
          icon: Icons.inventory_2_rounded,
          label: AppStrings.isUrdu ? '📦 مال کی لاگت' : '📦 Cost of Goods',
          amount: _costOfGoods,
          color: AppColors.warning,
        ),
        _summaryCard(
          icon: Icons.receipt_long_rounded,
          label: AppStrings.isUrdu ? '🧾 خرچے' : '🧾 Expenses',
          amount: _totalExpenses,
          color: AppColors.moneyOwed,
        ),
        _summaryCard(
          icon: Icons.trending_up_rounded,
          label: AppStrings.isUrdu ? '💹 بکری منافع' : '💹 Gross Profit',
          amount: _grossProfit,
          color: AppColors.moneyReceived,
        ),
      ],
    );
  }

  Widget _summaryCard({required IconData icon, required String label, required double amount, required Color color}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spacingMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.urduCaption),
            const SizedBox(height: 8),
            Text(
              AppFormatters.currency(amount),
              style: AppTextStyles.amountSmall.copyWith(color: amount >= 0 ? color : AppColors.moneyOwed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationBreakdown() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.isUrdu ? 'حساب کتاب' : 'Calculation', style: AppTextStyles.urduTitle),
          const SizedBox(height: 12),
          _calcRow(AppStrings.isUrdu ? 'کل بکری' : 'Total Sales', _totalSales, null),
          _calcRow(AppStrings.isUrdu ? 'مال کی لاگت' : 'Cost of Goods', _costOfGoods, false),
          const Divider(),
          _calcRow(AppStrings.isUrdu ? 'بکری کا منافع' : 'Sales Profit', _grossProfit, null),
          _calcRow(AppStrings.isUrdu ? 'خرچے' : 'Expenses', _totalExpenses, false),
          const Divider(thickness: 2),
          _calcRow(
            AppStrings.isUrdu ? 'اصل منافع' : 'NET PROFIT',
            _netProfit,
            null,
            isBold: true,
            showCheckmark: _netProfit >= 0,
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, double amount, bool? isSubtracted, {bool isBold = false, bool showCheckmark = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.urduCaption),
          Row(
            children: [
              if (isSubtracted == false) Text('- ', style: TextStyle(color: AppColors.moneyOwed, fontWeight: FontWeight.bold)),
              Text(
                AppFormatters.currency(amount.abs()),
                style: (isBold ? AppTextStyles.amountSmall : AppTextStyles.amountSmall.copyWith(fontSize: 16)).copyWith(
                  color: amount >= 0 ? AppColors.moneyReceived : AppColors.moneyOwed,
                ),
              ),
              if (showCheckmark) const Text(' ✅', style: TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseBreakdown() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.isUrdu ? 'خرچوں کی تفصیل' : 'Expense Breakdown', style: AppTextStyles.urduTitle),
          const SizedBox(height: 12),
          ..._expenseCategories.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e['category'] as String, style: AppTextStyles.urduCaption),
                Text(
                  AppFormatters.currency((e['total'] as num).toDouble()),
                  style: AppTextStyles.amountSmall.copyWith(fontSize: 16, color: AppColors.moneyOwed),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDailyChart() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.isUrdu ? 'روزانہ بکری کا گراف' : 'Daily Sales Chart',
            style: AppTextStyles.urduTitle,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(enabled: true),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
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
                        if (idx >= 0 && idx < _dailyData.length) {
                          final day = _dailyData[idx]['day'] as String;
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
                barGroups: List.generate(_dailyData.length, (i) {
                  final sales = (_dailyData[i]['total_sales'] as num).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: sales,
                        color: AppColors.moneyReceived,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
