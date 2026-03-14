import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';

/// Money Flow screen showing big picture cash flow:
/// Cash In Hand calculation = (Total Sales) - (Total Purchases) - (Expenses) + (Received) - (Paid)
/// Shows Total Receivable vs Total Payable visually.
class MoneyFlowScreen extends ConsumerWidget {
  const MoneyFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReceivable = ref.watch(totalReceivableProvider);
    final asyncPayable = ref.watch(totalPayableProvider);
    
    final asyncCashInHand = ref.watch(cashInHandProvider);

    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.moneyFlow,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalReceivableProvider);
          ref.invalidate(totalPayableProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimens.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cash In Hand Card ──
              Container(
                padding: const EdgeInsets.all(AppDimens.spacingLG),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.isUrdu ? 'نقد رقم' : 'Cash in Hand',
                      style: AppTextStyles.urduCaption.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    asyncCashInHand.when(
                      data: (cash) => Text(
                        AppStrings.formatAmount(cash),
                        style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 32),
                      ),
                      loading: () => const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(color: Colors.white)),
                      error: (_, __) => Text('Rs. 0', style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 32)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spacingLG),

              // ── Market Summary Details ──
              Text(
                AppStrings.isUrdu ? 'مارکیٹ کی صورتحال' : 'Market Status',
                style: AppTextStyles.urduTitle,
              ),
              const SizedBox(height: AppDimens.spacingMD),

              Row(
                children: [
                  Expanded(
                    child: _BalanceCard(
                      title: AppStrings.totalReceivable,
                      provider: asyncReceivable,
                      gradient: AppColors.receivableGradient,
                      icon: Icons.arrow_downward_rounded,
                      subtitle: AppStrings.isUrdu ? 'گاہکوں سے لینا ہے' : 'To collect from buyers',
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingSM),
                  Expanded(
                    child: _BalanceCard(
                      title: AppStrings.totalPayable,
                      provider: asyncPayable,
                      gradient: AppColors.payableGradient,
                      icon: Icons.arrow_upward_rounded,
                      subtitle: AppStrings.isUrdu ? 'سپلائرز کو دینا ہے' : 'To pay to suppliers',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacingLG),

              // ── Visual Graph of Net Worth ──
              Container(
                padding: const EdgeInsets.all(AppDimens.spacingMD),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.isUrdu ? 'کاروبار کی مالیت' : 'Net Business Worth', style: AppTextStyles.urduTitle),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final recv = asyncReceivable.valueOrNull ?? 0;
                        final pay = asyncPayable.valueOrNull ?? 0;
                        final cash = asyncCashInHand.valueOrNull ?? 0;

                        if (recv == 0 && pay == 0 && cash == 0) {
                           return Center(
                             child: Text(
                               AppStrings.isUrdu ? 'کوئی ڈیٹا نہیں' : 'No Data',
                               style: AppTextStyles.urduCaption,
                             ),
                           );
                        }

                        double total = recv + pay + cash;
                        if (total <= 0) total = 1;

                        return SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                if (cash > 0)
                                  PieChartSectionData(
                                    color: AppColors.primary,
                                    value: cash,
                                    title: '${((cash/total)*100).toStringAsFixed(0)}%',
                                    radius: 50,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                if (recv > 0)
                                  PieChartSectionData(
                                    color: AppColors.success,
                                    value: recv,
                                    title: '${((recv/total)*100).toStringAsFixed(0)}%',
                                    radius: 50,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                if (pay > 0)
                                  PieChartSectionData(
                                    color: AppColors.error,
                                    value: pay,
                                    title: '${((pay/total)*100).toStringAsFixed(0)}%',
                                    radius: 50,
                                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendItem(color: AppColors.primary, label: AppStrings.isUrdu ? 'نقد' : 'Cash'),
                        const SizedBox(width: 8),
                        _LegendItem(color: AppColors.success, label: AppStrings.isUrdu ? 'لینا ہے' : 'Recv'),
                        const SizedBox(width: 8),
                        _LegendItem(color: AppColors.error, label: AppStrings.isUrdu ? 'دینا ہے' : 'Pay'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final AsyncValue<double> provider;
  final LinearGradient gradient;
  final IconData icon;
  final String subtitle;

  const _BalanceCard({
    required this.title,
    required this.provider,
    required this.gradient,
    required this.icon,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: gradient.colors.first.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppTextStyles.urduCaption.copyWith(fontSize: 12), maxLines: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          provider.when(
            data: (amount) => Text(
              AppFormatters.number(amount),
              style: AppTextStyles.amountLarge.copyWith(
                color: gradient.colors.first,
                fontSize: 20,
              ),
            ),
            loading: () => const SizedBox(height: 24, child: CircularProgressIndicator()),
            error: (_, __) => Text('Rs. 0', style: AppTextStyles.amountLarge.copyWith(fontSize: 20)),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
