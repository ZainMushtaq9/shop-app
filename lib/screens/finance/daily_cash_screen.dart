import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';

/// Daily Cash / Aaj ka Hisaab — Tracks daily opening/closing cash.
/// Concept: Subah kitna tha + jo aaya - jo gaya = raat ko kitna hona chahiye
class DailyCashScreen extends ConsumerStatefulWidget {
  const DailyCashScreen({super.key});

  @override
  ConsumerState<DailyCashScreen> createState() => _DailyCashScreenState();
}

class _DailyCashScreenState extends ConsumerState<DailyCashScreen> {
  bool _loading = true;
  bool _sessionOpen = false;
  bool _sessionClosed = false;
  double _openingCash = 0;
  double _todaySales = 0;
  double _todayExpenses = 0;
  double _expectedCash = 0;
  double _closingCash = 0;
  double _difference = 0;

  final _openingController = TextEditingController();
  final _closingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _openingController.dispose();
    _closingController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      _todaySales = await db.getTodaySales();
      _todayExpenses = await db.getTodayExpenses();
      
      // Check SharedPreferences for today's session
      // For now, use simple in-memory state
      setState(() {
        _expectedCash = _openingCash + _todaySales - _todayExpenses;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _openDay() {
    final amount = double.tryParse(_openingController.text.trim()) ?? 0;
    setState(() {
      _openingCash = amount;
      _sessionOpen = true;
      _expectedCash = _openingCash + _todaySales - _todayExpenses;
    });
  }

  void _closeDay() {
    final counted = double.tryParse(_closingController.text.trim()) ?? 0;
    setState(() {
      _closingCash = counted;
      _difference = counted - _expectedCash;
      _sessionClosed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'آج کا حساب / Daily Cash' : "Today's Cash",
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_sessionOpen && !_sessionClosed)
                  _buildOpenDayCard()
                else if (_sessionOpen && !_sessionClosed)
                  _buildLiveSessionCard()
                else
                  _buildDaySummaryCard(),
              ],
            ),
          ),
    );
  }

  // ─── OPEN THE DAY ───
  Widget _buildOpenDayCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wb_sunny_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            AppStrings.isUrdu ? 'دکان شروع کرو!' : 'Start Your Day!',
            style: AppTextStyles.urduTitle,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.isUrdu
              ? 'آج صبح آپ کی دکان میں کتنا کیش ہے؟'
              : 'How much cash is in your shop this morning?',
            style: AppTextStyles.urduCaption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _openingController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: AppTextStyles.amountLarge,
            decoration: InputDecoration(
              prefixText: 'Rs. ',
              hintText: '0',
              hintStyle: AppTextStyles.amountLarge.copyWith(color: AppColors.disabled),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _openDay,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                AppStrings.isUrdu ? 'دکان شروع کرو' : 'Start Day',
                style: AppTextStyles.urduBody.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.moneyReceived,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LIVE SESSION ───
  Widget _buildLiveSessionCard() {
    return Column(
      children: [
        // Running total card
        Container(
          padding: const EdgeInsets.all(AppDimens.spacingLG),
          decoration: BoxDecoration(
            gradient: AppColors.receivableGradient,
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          ),
          child: Column(
            children: [
              Text(
                AppStrings.isUrdu ? '💵 ابھی ہاتھ میں کتنا پیسا ہے؟' : '💵 Expected Cash Right Now',
                style: AppTextStyles.urduBody.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                AppFormatters.currency(_expectedCash),
                style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 36),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.spacingMD),
        
        // Breakdown
        Container(
          padding: const EdgeInsets.all(AppDimens.spacingMD),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _cashRow(AppStrings.isUrdu ? 'صبح کا کیش' : 'Opening Cash', _openingCash, null),
              _cashRow(AppStrings.isUrdu ? 'بکری سے آیا' : 'From Sales', _todaySales, true),
              _cashRow(AppStrings.isUrdu ? 'خرچے گئے' : 'Expenses', _todayExpenses, false),
              const Divider(thickness: 2),
              _cashRow(AppStrings.isUrdu ? 'ہونا چاہیے' : 'Expected', _expectedCash, null, isBold: true),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.spacingLG),
        
        // Close day
        Container(
          padding: const EdgeInsets.all(AppDimens.spacingLG),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                AppStrings.isUrdu ? 'دکان بند کرو' : 'Close Day',
                style: AppTextStyles.urduTitle,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.isUrdu
                  ? 'ابھی گنو اور بتاؤ کتنا کیش ہے؟'
                  : 'Count your cash and enter amount',
                style: AppTextStyles.urduCaption.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _closingController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: AppTextStyles.amountMedium,
                decoration: InputDecoration(
                  prefixText: 'Rs. ',
                  hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _closeDay,
                  icon: const Icon(Icons.lock_rounded, color: Colors.white),
                  label: Text(
                    AppStrings.isUrdu ? 'حساب بند کرو' : 'Close Day',
                    style: AppTextStyles.urduBody.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Refresh button
        TextButton.icon(
          onPressed: _loadSession,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(AppStrings.isUrdu ? 'تازہ کرو' : 'Refresh'),
        ),
      ],
    );
  }

  // ─── DAY SUMMARY ───
  Widget _buildDaySummaryCard() {
    final match = _difference.abs() < 1;
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: match ? AppColors.moneyReceived : AppColors.warning, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            match ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            size: 64,
            color: match ? AppColors.moneyReceived : AppColors.warning,
          ),
          const SizedBox(height: 12),
          Text(
            match
              ? (AppStrings.isUrdu ? '✅ حساب ٹھیک ہے! مبارک ہو!' : '✅ Cash matches! Well done!')
              : (AppStrings.isUrdu ? '⚠️ فرق ہے' : '⚠️ Difference found'),
            style: AppTextStyles.urduTitle,
          ),
          const SizedBox(height: 24),
          
          _cashRow(AppStrings.isUrdu ? 'کل بکری' : 'Total Sales', _todaySales, null),
          _cashRow(AppStrings.isUrdu ? 'خرچے' : 'Expenses', _todayExpenses, null),
          const Divider(),
          _cashRow(AppStrings.isUrdu ? 'جو ہونا چاہیے تھا' : 'Expected', _expectedCash, null),
          _cashRow(AppStrings.isUrdu ? 'جو گنا' : 'Counted', _closingCash, null),
          if (!match) ...[
            const Divider(),
            _cashRow(
              AppStrings.isUrdu ? 'فرق' : 'Difference',
              _difference,
              null,
              isBold: true,
              color: _difference >= 0 ? AppColors.moneyReceived : AppColors.moneyOwed,
            ),
          ],
        ],
      ),
    );
  }

  Widget _cashRow(String label, double amount, bool? isPositive, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.urduCaption),
          Row(
            children: [
              if (isPositive == true) const Text('+ ', style: TextStyle(color: AppColors.moneyReceived)),
              if (isPositive == false) const Text('- ', style: TextStyle(color: AppColors.moneyOwed)),
              Text(
                AppFormatters.currency(amount.abs()),
                style: (isBold ? AppTextStyles.amountSmall : AppTextStyles.amountSmall.copyWith(fontSize: 16)).copyWith(
                  color: color ?? (isPositive == false ? AppColors.moneyOwed : isPositive == true ? AppColors.moneyReceived : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
