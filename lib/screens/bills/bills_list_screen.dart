import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import '../../models/models.dart';
import '../../services/pdf_export_service.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// All Bills screen — shows full bill history with filters.
/// Tabs: Tamam | Naqdh | Udhaar | Filtered by date.
class BillsListScreen extends ConsumerStatefulWidget {
  const BillsListScreen({super.key});

  @override
  ConsumerState<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends ConsumerState<BillsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Sale> _allSales = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSales();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      final sales = await db.getSalesByDateRange(_startDate, _endDate);
      setState(() {
        _allSales = sales;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.isUrdu ? 'بل لانے میں مسئلہ: $e' : 'Failed to load bills: $e',
            style: const TextStyle(color: Colors.white, fontFamily: 'JameelNoori'),
          ),
          backgroundColor: AppColors.moneyOwed,
        ),
      );
    }
  }

  List<Sale> get _cashSales => _allSales.where((s) => s.balanceDue <= 0).toList();
  List<Sale> get _creditSales => _allSales.where((s) => s.balanceDue > 0).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'تمام بل / All Bills' : 'All Bills',
      ),
      body: Column(
        children: [
          // Date filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD, vertical: AppDimens.spacingSM),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${AppFormatters.dateShort(_startDate)} – ${AppFormatters.dateShort(_endDate)}',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Summary card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat(AppStrings.isUrdu ? 'کل بل' : 'Total Bills', '${_allSales.length}', AppColors.info),
                  Container(width: 1, height: 40, color: AppColors.divider),
                  _miniStat(
                    AppStrings.isUrdu ? 'نقد' : 'Cash',
                    '${_cashSales.length}',
                    AppColors.moneyReceived,
                  ),
                  Container(width: 1, height: 40, color: AppColors.divider),
                  _miniStat(
                    AppStrings.isUrdu ? 'ادھار' : 'Credit',
                    '${_creditSales.length}',
                    AppColors.moneyOwed,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: AppStrings.isUrdu ? 'تمام' : 'All'),
              Tab(text: AppStrings.isUrdu ? 'نقد' : 'Cash'),
              Tab(text: AppStrings.isUrdu ? 'ادھار' : 'Credit'),
            ],
          ),
          // Tab content
          Expanded(
            child: _loading
              ? ListView.builder(
                  padding: const EdgeInsets.all(AppDimens.spacingMD),
                  itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: AppDimens.spacingSM),
                    child: CustomSkeleton(width: double.infinity, height: 80, borderRadius: 12),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSaleList(_allSales),
                    _buildSaleList(_cashSales),
                    _buildSaleList(_creditSales),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.amountSmall.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.urduCaption.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildSaleList(List<Sale> sales) {
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(AppStrings.isUrdu ? 'کوئی بل نہیں' : 'No bills found', style: AppTextStyles.urduBody),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.spacingMD),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        final isCredit = sale.balanceDue > 0;
        return Card(
          margin: const EdgeInsets.only(bottom: AppDimens.spacingSM),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCredit ? AppColors.moneyOwed.withOpacity(0.1) : AppColors.moneyReceived.withOpacity(0.1),
              child: Icon(
                isCredit ? Icons.schedule_rounded : Icons.check_circle_rounded,
                color: isCredit ? AppColors.moneyOwed : AppColors.moneyReceived,
              ),
            ),
            title: Text(
              '${AppStrings.isUrdu ? "بل" : "Bill"} #${sale.id.substring(0, 6).toUpperCase()}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppFormatters.dateTime(sale.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                if (isCredit)
                  Text(
                    '${AppStrings.isUrdu ? "باقی" : "Due"}: ${AppFormatters.currency(sale.balanceDue)}',
                    style: TextStyle(color: AppColors.moneyOwed, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppFormatters.currency(sale.total), style: AppTextStyles.amountSmall),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCredit ? AppColors.moneyOwed.withOpacity(0.1) : AppColors.moneyReceived.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCredit ? (AppStrings.isUrdu ? 'ادھار' : 'Credit') : (AppStrings.isUrdu ? 'نقد' : 'Cash'),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCredit ? AppColors.moneyOwed : AppColors.moneyReceived,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => _showBillDetail(sale),
          ),
        );
      },
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadSales();
    }
  }

  void _showBillDetail(Sale sale) async {
    final db = ref.read(databaseProvider);
    final items = await db.getSaleItems(sale.id);
    
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(AppDimens.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Center(child: Text(AppStrings.isUrdu ? 'بل کی تفصیل' : 'Bill Detail', style: AppTextStyles.urduTitle)),
              const SizedBox(height: 8),
              Center(child: Text('#${sale.id.substring(0, 8).toUpperCase()}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
              Center(child: Text(AppFormatters.dateTime(sale.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
              const Divider(height: 32),
              // Items
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.productName.isNotEmpty ? item.productName : item.productId.substring(0, 6)}', style: AppTextStyles.body)),
                    Text('x${item.quantity}', style: AppTextStyles.caption),
                    const SizedBox(width: 16),
                    Text(AppFormatters.currency(item.salePrice * item.quantity), style: AppTextStyles.amountSmall.copyWith(fontSize: 14)),
                  ],
                ),
              )),
              const Divider(height: 24),
              _detailRow(AppStrings.isUrdu ? 'جمع' : 'Subtotal', AppFormatters.currency(sale.subtotal)),
              if (sale.discount > 0)
                _detailRow(AppStrings.isUrdu ? 'چھوٹ' : 'Discount', '- ${AppFormatters.currency(sale.discount)}'),
              const Divider(),
              _detailRow(AppStrings.isUrdu ? 'کل' : 'Total', AppFormatters.currency(sale.total), bold: true),
              _detailRow(AppStrings.isUrdu ? 'ادا کیا' : 'Paid', AppFormatters.currency(sale.amountPaid)),
              if (sale.balanceDue > 0)
                _detailRow(AppStrings.isUrdu ? 'باقی' : 'Balance', AppFormatters.currency(sale.balanceDue), isRed: true),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { 
                        Navigator.pop(ctx); 
                        _printBill(sale, items);
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: Text(AppStrings.isUrdu ? 'پرنٹ' : 'Print'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () { 
                        Navigator.pop(ctx); 
                        _shareBill(sale, items);
                      },
                      icon: const Icon(Icons.share_rounded, color: AppColors.moneyReceived),
                      label: Text(AppStrings.isUrdu ? 'شیئر' : 'Share', style: TextStyle(color: AppColors.moneyReceived)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.moneyReceived)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Cancel Bill Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmCancelBill(sale);
                  },
                  icon: const Icon(Icons.cancel_rounded, color: AppColors.moneyOwed),
                  label: Text(
                    AppStrings.isUrdu ? 'یہ بل منسوخ کریں (Cancel)' : 'Cancel this Bill',
                    style: const TextStyle(color: AppColors.moneyOwed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? AppTextStyles.urduBody.copyWith(fontWeight: FontWeight.bold) : AppTextStyles.urduCaption),
          Text(value, style: (bold ? AppTextStyles.amountSmall : AppTextStyles.amountSmall.copyWith(fontSize: 14)).copyWith(
            color: isRed ? AppColors.moneyOwed : null,
          )),
        ],
      ),
    );
  }

  void _confirmCancelBill(Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.isUrdu ? 'بل منسوخ کریں؟' : 'Cancel Bill?', style: AppTextStyles.urduTitle),
        content: Text(
          AppStrings.isUrdu 
            ? 'کیا آپ واقعی یہ بل ختم کرنا چاہتے ہیں؟\n\n• خریدا گیا سامان واپس سٹاک میں شامل ہو جائے گا۔\n• ادھار خودبخود واپس ہو جائے گا۔' 
            : 'Are you sure you want to cancel this bill? Items will return to stock and credit will be reversed.',
          style: AppTextStyles.urduBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _cancelBill(sale);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.moneyOwed, foregroundColor: Colors.white),
            child: Text(AppStrings.isUrdu ? 'جی ہاں، ختم کریں' : 'Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBill(Sale sale) async {
    setState(() => _loading = true);
    try {
      final db = ref.read(databaseProvider);
      await db.deleteSale(sale.id); // Reverses stock and balances internally
      
      if (mounted) {
        // Remove from local lists
        setState(() {
          _allSales.removeWhere((s) => s.id == sale.id);
          _loading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.isUrdu ? '✅ بل کامیابی سے ختم ہو گیا' : '✅ Bill cancelled successfully'),
            backgroundColor: AppColors.moneyReceived,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.moneyOwed,
          ),
        );
      }
    }
  }

  Future<void> _printBill(Sale sale, List<SaleItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopName = prefs.getString('app_name') ?? 'Super Business Shop';
      
      final pdfBytes = await PdfExportService.generateBill(
        shopName: shopName,
        shopPhone: '', // Add logic to get shop phone later if added to settings
        billNo: sale.id.substring(0, 8).toUpperCase(),
        customerName: sale.customerId != null ? 'Customer (${sale.customerId})' : 'Walk-in Customer',
        items: items,
        subtotal: sale.subtotal,
        discount: sale.discount,
        discountPercentage: 0, // Usually stored, omitting for simplicity
        tax: sale.taxAmount,
        total: sale.total,
        amountPaid: sale.amountPaid,
        balanceDue: sale.balanceDue,
        paymentType: sale.paymentMethod,
        date: sale.createdAt,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Bill_${sale.id}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print error: $e'), backgroundColor: AppColors.moneyOwed),
      );
    }
  }

  Future<void> _shareBill(Sale sale, List<SaleItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopName = prefs.getString('app_name') ?? 'Super Business Shop';
      
      final pdfBytes = await PdfExportService.generateBill(
        shopName: shopName,
        shopPhone: '',
        billNo: sale.id.substring(0, 8).toUpperCase(),
        customerName: sale.customerId != null ? 'Customer (${sale.customerId})' : 'Walk-in Customer',
        items: items,
        subtotal: sale.subtotal,
        discount: sale.discount,
        discountPercentage: 0,
        tax: sale.taxAmount,
        total: sale.total,
        amountPaid: sale.amountPaid,
        balanceDue: sale.balanceDue,
        paymentType: sale.paymentMethod,
        date: sale.createdAt,
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/receipt_${sale.id}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Receipt from $shopName (Bill #${sale.id.substring(0, 6)})',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share error: $e'), backgroundColor: AppColors.moneyOwed),
      );
    }
  }
}
