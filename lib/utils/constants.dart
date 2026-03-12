import 'package:intl/intl.dart';

/// Utility formatters for currency, dates, and numbers used throughout the app.
class AppFormatters {
  AppFormatters._();

  // ─── Currency ───
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  /// Format amount as "Rs. 1,234"
  static String currency(double amount) {
    return 'Rs. ${_currencyFormat.format(amount.round())}';
  }

  /// Format amount as "1,234" (without currency symbol)
  static String number(double amount) {
    return _currencyFormat.format(amount.round());
  }

  // ─── Dates ───
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateShort = DateFormat('dd MMM');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeOnly = DateFormat('hh:mm a');

  /// Format as "09 Mar 2026"
  static String date(DateTime dt) => _dateFormat.format(dt);

  /// Format as "09 Mar"
  static String dateShort(DateTime dt) => _dateShort.format(dt);

  /// Format as "09 Mar 2026, 03:30 PM"
  static String dateTime(DateTime dt) => _dateTime.format(dt);

  /// Format as "2026-03-09" (ISO for database)
  static String dateISO(DateTime dt) => _isoFormat.format(dt);

  /// Format as "03:30 PM"
  static String time(DateTime dt) => _timeOnly.format(dt);

  /// Parse ISO date string
  static DateTime parseISO(String dateStr) => DateTime.parse(dateStr);

  /// Get today's date as ISO string
  static String todayISO() => dateISO(DateTime.now());

  // ─── Percentage ───
  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // ─── Quantity ───
  static String quantity(double qty) {
    if (qty == qty.toInt()) {
      return _currencyFormat.format(qty.toInt());
    }
    return qty.toString();
  }
}

/// Constants used across the app.
class AppConstants {
  AppConstants._();

  // Database
  static const String dbName = 'shop_app_v4.db';
  static const int dbVersion = 4;

  // Tables
  static const String tableProducts = 'products';
  static const String tableCustomers = 'customers';
  static const String tableCustomerTransactions = 'customer_transactions';
  static const String tableSuppliers = 'suppliers';
  static const String tableSupplierTransactions = 'supplier_transactions';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';
  static const String tableExpenses = 'expenses';
  static const String tableSyncQueue = 'sync_queue';
  static const String tableUsers = 'users';
  static const String tableInstallments = 'installments';

  // Transaction types — Buyer
  static const String txCreditSale = 'CREDIT_SALE';
  static const String txCashSale = 'CASH_SALE';
  static const String txPaymentReceived = 'PAYMENT_RECEIVED';
  static const String txReturn = 'RETURN';
  static const String txAdvance = 'ADVANCE';
  static const String txPartialPayment = 'PARTIAL_PAYMENT';

  // Transaction types — Supplier
  static const String txCreditPurchase = 'CREDIT_PURCHASE';
  static const String txCashPurchase = 'CASH_PURCHASE';
  static const String txPaymentMade = 'PAYMENT_MADE';
  static const String txReturnToSupplier = 'RETURN_TO_SUPPLIER';
  static const String txAdvancePaid = 'ADVANCE_PAID';

  // Payment methods
  static const String paymentCash = 'CASH';
  static const String paymentCredit = 'CREDIT';
  static const String paymentPartial = 'PARTIAL';
  static const String paymentBankTransfer = 'BANK_TRANSFER';

  // Sync status
  static const String syncPending = 'PENDING';
  static const String syncSynced = 'SYNCED';
  static const String syncFailed = 'FAILED';

  // Sync actions
  static const String syncInsert = 'INSERT';
  static const String syncUpdate = 'UPDATE';
  static const String syncDelete = 'DELETE';

  // Backup
  static const String backupFolderPrefix = 'ShopApp Backup';
  static const String backupFilePrefix = 'backup_';
  static const int maxBackupDays = 30;

  // Default categories for products
  static const List<String> defaultCategories = [
    'عام', // General
    'خوراک', // Food
    'مشروبات', // Beverages
    'صفائی', // Cleaning
    'ذاتی نگہداشت', // Personal Care
    'الیکٹرانکس', // Electronics
    'اسٹیشنری', // Stationery
    'دیگر', // Other
  ];

  // Default expense categories
  static const List<String> defaultExpenseCategories = [
    'کرایہ', // Rent
    'تنخواہ', // Salary
    'بجلی', // Electricity
    'پانی', // Water
    'ٹرانسپورٹ', // Transport
    'مرمت', // Repairs
    'دیگر', // Other
  ];

  // Sheet sync interval in minutes
  static const int sheetSyncIntervalMinutes = 30;

  // Currency
  static const String defaultCurrency = 'PKR';
  static const String currencySymbol = 'Rs.';
}
