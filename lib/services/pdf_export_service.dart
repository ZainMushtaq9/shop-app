import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/models.dart';
import '../utils/constants.dart';

/// PDF generation service for ledger reports, bills, and exports.
/// Both shopkeepers and customers can export filtered ledger as PDF.
class PdfExportService {
  PdfExportService._();

  /// Generate a daily sales and profit report
  static Future<Uint8List> generateDailyReport({
    required String shopName,
    required DateTime date,
    required List<Sale> sales,
    required double totalSales,
    required double totalExpenses,
    required double expectedCash,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          title: 'Daily Report / روزانہ رپورٹ',
          customerName: 'All Customers',
          shopName: shopName,
          startDate: date,
          endDate: date,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary card
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem('Total Sales / کل بکری', 'Rs. ${AppFormatters.number(totalSales)}', PdfColors.green),
                _summaryItem('Expenses / خرچے', 'Rs. ${AppFormatters.number(totalExpenses)}', PdfColors.red),
                _summaryItem('Expected Cash / کیش', 'Rs. ${AppFormatters.number(expectedCash)}', PdfColors.blue),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Sales table
          pw.Text('Sales List / بل کی تفصیل', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey800),
                children: [
                  _tableHeader('Bill No / بل نمب'),
                  _tableHeader('Customer / گاہک'),
                  _tableHeader('Total'),
                  _tableHeader('Paid'),
                  _tableHeader('Remaining'),
                ],
              ),
              // Data rows
              ...sales.map((s) => pw.TableRow(
                    children: [
                      _tableCell('#${s.id.substring(0, 6)}'),
                      _tableCell(s.customerId ?? 'Walk-in'),
                      _tableCell('Rs. ${AppFormatters.number(s.total)}'),
                      _tableCell('Rs. ${AppFormatters.number(s.amountPaid)}'),
                      _tableCell('Rs. ${AppFormatters.number(s.balanceDue)}',
                          color: s.balanceDue > 0 ? PdfColors.red : PdfColors.black),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate a customer ledger PDF with date filtering
  static Future<Uint8List> generateCustomerLedger({
    required String customerName,
    required String shopName,
    required List<CustomerTransaction> transactions,
    required double totalDebit,
    required double totalCredit,
    required double balance,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          title: 'Customer Ledger / گاہک کھاتہ',
          customerName: customerName,
          shopName: shopName,
          startDate: startDate,
          endDate: endDate,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary card
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem('Total Debit / کل ڈیبٹ', 'Rs. ${AppFormatters.number(totalDebit)}', PdfColors.red),
                _summaryItem('Total Credit / کل کریڈٹ', 'Rs. ${AppFormatters.number(totalCredit)}', PdfColors.green),
                _summaryItem(
                  'Balance / بیلنس',
                  'Rs. ${AppFormatters.number(balance.abs())}',
                  balance > 0 ? PdfColors.red : PdfColors.green,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Transaction table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey800),
                children: [
                  _tableHeader('Date / تاریخ'),
                  _tableHeader('Description / تفصیل'),
                  _tableHeader('Debit (DR)'),
                  _tableHeader('Credit (CR)'),
                  _tableHeader('Balance'),
                ],
              ),
              // Data rows
              ...transactions.map((tx) => pw.TableRow(
                    children: [
                      _tableCell(AppFormatters.dateShort(tx.date)),
                      _tableCell(tx.description),
                      _tableCell(tx.debitAmount > 0 ? 'Rs. ${AppFormatters.number(tx.debitAmount)}' : '-'),
                      _tableCell(tx.creditAmount > 0 ? 'Rs. ${AppFormatters.number(tx.creditAmount)}' : '-'),
                      _tableCell('Rs. ${AppFormatters.number(tx.runningBalance.abs())}',
                          color: tx.runningBalance > 0 ? PdfColors.red : PdfColors.green),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate a bill PDF
  static Future<Uint8List> generateBill({
    required String shopName,
    String? shopPhone,
    required String billNo,
    required String customerName,
    required List<SaleItem> items,
    required double subtotal,
    required double discount,
    required double discountPercentage,
    required double tax,
    required double total,
    required double amountPaid,
    required double balanceDue,
    required String paymentType,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Shop header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(shopName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  if (shopPhone != null && shopPhone.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('Phone: $shopPhone', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                  pw.SizedBox(height: 4),
                  pw.Text('Bill No: $billNo', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  pw.Text('Date: ${AppFormatters.dateTime(date)}', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),

            // Items table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey800),
                  children: [
                    _tableHeader('#'),
                    _tableHeader('Item'),
                    _tableHeader('Qty'),
                    _tableHeader('Price'),
                    _tableHeader('Total'),
                  ],
                ),
                ...items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    children: [
                      _tableCell('${i + 1}'),
                      _tableCell(item.productName),
                      _tableCell('${item.quantity}'),
                      _tableCell('Rs. ${AppFormatters.number(item.salePrice)}'),
                      _tableCell('Rs. ${AppFormatters.number(item.salePrice * item.quantity)}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),

            // Totals
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 250,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal', subtotal),
                    if (discount > 0) _totalRow('Discount ${discountPercentage > 0 ? "(${AppFormatters.percentage(discountPercentage)})" : ""}', -discount),
                    if (tax > 0) _totalRow('Tax', tax),
                    pw.Divider(),
                    _totalRow('Total', total, bold: true),
                    _totalRow('Paid', amountPaid),
                    if (balanceDue > 0) _totalRow('Balance Due', balanceDue, color: PdfColors.red),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Payment: $paymentType', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ─── Helper Widgets ───

  static pw.Widget _buildHeader({
    required String title,
    required String customerName,
    required String shopName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(shopName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text('Customer: $customerName', style: const pw.TextStyle(fontSize: 14)),
        if (startDate != null && endDate != null)
          pw.Text(
            'Period: ${AppFormatters.date(startDate)} — ${AppFormatters.date(endDate)}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Generated by Super Business Shop', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        pw.Text('Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
      ],
    );
  }

  static pw.Widget _summaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  static pw.Widget _tableCell(String text, {PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, color: color)),
    );
  }

  static pw.Widget _totalRow(String label, double amount, {bool bold = false, PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            'Rs. ${AppFormatters.number(amount.abs())}',
            style: pw.TextStyle(fontSize: 12, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }
}
