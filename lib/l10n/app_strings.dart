/// Urdu-English localization strings for the shop app.
/// Primary language: Urdu. Toggle to English supported.
class AppStrings {
  AppStrings._();

  // Current language state
  static bool _isUrdu = true;

  static bool get isUrdu => _isUrdu;

  static void setUrdu(bool value) {
    _isUrdu = value;
  }

  static void toggleLanguage() {
    _isUrdu = !_isUrdu;
  }

  // ─── App Info ───
  static String get appName => _isUrdu ? 'سپر بزنس شاپ' : 'Super Business Shop';

  // ─── Navigation ───
  static String get home => _isUrdu ? 'گھر' : 'Home';
  static String get sale => _isUrdu ? 'فروخت' : 'Sale';
  static String get stock => _isUrdu ? 'مال' : 'Stock';
  static String get customers => _isUrdu ? 'گاہک' : 'Customers';
  static String get reports => _isUrdu ? 'رپورٹ' : 'Reports';
  static String get suppliers => _isUrdu ? 'سپلائر' : 'Suppliers';
  static String get googleSheet => _isUrdu ? 'گوگل شیٹ' : 'Google Sheet';
  static String get moneyFlow => _isUrdu ? 'نقد بہاؤ' : 'Money Flow';
  static String get expenses => _isUrdu ? 'اخراجات' : 'Expenses';
  static String get backup => _isUrdu ? 'بیک اپ' : 'Backup';
  static String get switchShop => _isUrdu ? 'دکان بدلو' : 'Switch Shop';
  static String get settings => _isUrdu ? 'ترتیبات' : 'Settings';
  static String get help => _isUrdu ? 'مدد' : 'Help';

  // ─── Dashboard ───
  static String get todaySales => _isUrdu ? 'آج کی فروخت' : 'Today\'s Sales';
  static String get todayProfit => _isUrdu ? 'آج کا منافع' : 'Today\'s Profit';
  static String get totalReceivable => _isUrdu ? 'ادھار ملنی' : 'Total Receivable';
  static String get totalPayable => _isUrdu ? 'ادھار دینی' : 'Total Payable';
  static String get newSale => _isUrdu ? 'نئی فروخت' : 'New Sale';
  static String get lowStockAlerts => _isUrdu ? 'کم اسٹاک الرٹ' : 'Low Stock Alerts';
  static String get salesVsProfit => _isUrdu ? 'فروخت بمقابلہ منافع' : 'Sales vs Profit';

  // ─── Products ───
  static String get products => _isUrdu ? 'مصنوعات' : 'Products';
  static String get addProduct => _isUrdu ? 'مصنوعات شامل کریں' : 'Add Product';
  static String get editProduct => _isUrdu ? 'مصنوعات تبدیل کریں' : 'Edit Product';
  static String get productName => _isUrdu ? 'نام' : 'Product Name';
  static String get productNameEnglish => _isUrdu ? 'انگریزی نام' : 'English Name';
  static String get purchasePrice => _isUrdu ? 'قیمت خرید' : 'Purchase Price';
  static String get salePrice => _isUrdu ? 'قیمت فروخت' : 'Sale Price';
  static String get stockQuantity => _isUrdu ? 'اسٹاک' : 'Stock';
  static String get minStockAlert => _isUrdu ? 'کم از کم اسٹاک' : 'Min Stock Alert';
  static String get category => _isUrdu ? 'زمرہ' : 'Category';
  static String get barcode => _isUrdu ? 'بارکوڈ' : 'Barcode';
  static String get searchProducts => _isUrdu ? 'مصنوعات تلاش کریں' : 'Search Products';

  // ─── Customers / Buyer Ledger ───
  static String get addCustomer => _isUrdu ? 'نیا گاہک' : 'Add Customer';
  static String get customerName => _isUrdu ? 'گاہک کا نام' : 'Customer Name';
  static String get phone => _isUrdu ? 'فون' : 'Phone';
  static String get address => _isUrdu ? 'پتہ' : 'Address';
  static String get totalRemaining => _isUrdu ? 'کل باقی' : 'Total Remaining';
  static String get receivePayment => _isUrdu ? 'ادائیگی لو' : 'Receive Payment';
  static String get creditSale => _isUrdu ? 'ادھار فروخت' : 'Credit Sale';
  static String get cashSale => _isUrdu ? 'نقد فروخت' : 'Cash Sale';
  static String get paymentReceived => _isUrdu ? 'ادائیگی موصول' : 'Payment Received';
  static String get returnGoods => _isUrdu ? 'مال واپسی' : 'Return';
  static String get advancePayment => _isUrdu ? 'پیشگی ادائیگی' : 'Advance Payment';
  static String get partialPayment => _isUrdu ? 'جزوی ادائیگی' : 'Partial Payment';
  static String get whatsappReminder => _isUrdu ? 'واٹس ایپ یاد دہانی' : 'WhatsApp Reminder';
  static String get viewBill => _isUrdu ? 'بل دیکھو' : 'View Bill';
  static String get sendPdf => _isUrdu ? 'پی ڈی ایف بھیجو' : 'Send PDF';

  // ─── Supplier Ledger ───
  static String get addSupplier => _isUrdu ? 'نیا سپلائر' : 'Add Supplier';
  static String get supplierName => _isUrdu ? 'سپلائر کا نام' : 'Supplier Name';
  static String get companyName => _isUrdu ? 'کمپنی' : 'Company';
  static String get youOwe => _isUrdu ? 'آپ کے ذمے' : 'You Owe';
  static String get makePayment => _isUrdu ? 'ادائیگی کرو' : 'Make Payment';
  static String get addPurchase => _isUrdu ? 'خریداری شامل کرو' : 'Add Purchase';
  static String get creditPurchase => _isUrdu ? 'ادھار خریداری' : 'Credit Purchase';
  static String get cashPurchase => _isUrdu ? 'نقد خریداری' : 'Cash Purchase';
  static String get paymentMade => _isUrdu ? 'ادائیگی کی' : 'Payment Made';
  static String get returnToSupplier => _isUrdu ? 'واپسی سپلائر کو' : 'Return to Supplier';

  // ─── Ledger Table Headers ───
  static String get date => _isUrdu ? 'تاریخ' : 'Date';
  static String get description => _isUrdu ? 'تفصیل' : 'Description';
  static String get debit => _isUrdu ? 'ڈیبٹ' : 'Debit (DR)';
  static String get credit => _isUrdu ? 'کریڈٹ' : 'Credit (CR)';
  static String get balance => _isUrdu ? 'بیلنس' : 'Balance';
  static String get amount => _isUrdu ? 'رقم' : 'Amount';

  // ─── Money Flow ───
  static String get moneyToReceive => _isUrdu ? 'مجھے ملنے والی رقم' : 'Money I Will Receive';
  static String get moneyToPay => _isUrdu ? 'مجھے دینی والی رقم' : 'Money I Must Pay';
  static String get netPosition => _isUrdu ? 'خالص پوزیشن' : 'Net Position';
  static String get todayPayments => _isUrdu ? 'آج کی ادائیگیاں' : 'Today\'s Payments';
  static String get agingAnalysis => _isUrdu ? 'بقایا رقم' : 'Aging Analysis';
  static String get youAreInProfit => _isUrdu ? 'آپ فائدے میں ہیں' : 'You Are In Profit';
  static String get youNeedToPay => _isUrdu ? 'آپ کو ادائیگی کرنی ہے' : 'You Need To Pay';
  static String get viewAllCustomers => _isUrdu ? 'تمام گاہک دیکھو' : 'View All Customers';
  static String get viewAllSuppliers => _isUrdu ? 'تمام سپلائر دیکھو' : 'View All Suppliers';
  static String get totalUdhaar => _isUrdu ? 'کل ادھار' : 'Total Credit';
  static String get totalPayableAmount => _isUrdu ? 'کل واجب الادا' : 'Total Payable';

  // ─── Sheets Editor ───
  static String get addRow => _isUrdu ? '+ قطار شامل کریں' : '+ Add Row';
  static String get save => _isUrdu ? 'محفوظ کریں' : 'Save';
  static String get refresh => _isUrdu ? 'تازہ کریں' : 'Refresh';
  static String get pending => _isUrdu ? 'انتظار میں' : 'Pending';
  static String get changesUploaded => _isUrdu ? 'تبدیلیاں اپ لوڈ ہوئیں' : 'Changes Uploaded';
  static String get conflictDetected => _isUrdu ? '2 جگہ تبدیلی ہوئی' : 'Changed In 2 Places';

  // ─── POS / Billing ───
  static String get billNo => _isUrdu ? 'بل نمبر' : 'Bill No';
  static String get subtotal => _isUrdu ? 'ذیلی کل' : 'Subtotal';
  static String get discount => _isUrdu ? 'رعایت' : 'Discount';
  static String get tax => _isUrdu ? 'ٹیکس' : 'Tax';
  static String get total => _isUrdu ? 'کل' : 'Total';
  static String get cash => _isUrdu ? 'نقد' : 'Cash';
  static String get udhaar => _isUrdu ? 'ادھار' : 'Credit';
  static String get partial => _isUrdu ? 'جزوی' : 'Partial';
  static String get amountPaid => _isUrdu ? 'ادا شدہ رقم' : 'Amount Paid';
  static String get balanceDue => _isUrdu ? 'باقی رقم' : 'Balance Due';
  static String get generateBill => _isUrdu ? 'بل بنائیں' : 'Generate Bill';
  static String get shareOnWhatsapp => _isUrdu ? 'واٹس ایپ پر بھیجو' : 'Share on WhatsApp';
  static String get print => _isUrdu ? 'پرنٹ' : 'Print';

  // ─── Reports ───
  static String get dailyReport => _isUrdu ? 'روزانہ رپورٹ' : 'Daily Report';
  static String get weeklyReport => _isUrdu ? 'ہفتہ وار رپورٹ' : 'Weekly Report';
  static String get monthlyReport => _isUrdu ? 'ماہانہ رپورٹ' : 'Monthly Report';
  static String get profitReport => _isUrdu ? 'منافع رپورٹ' : 'Profit Report';
  static String get inventoryReport => _isUrdu ? 'اسٹاک رپورٹ' : 'Inventory Report';
  static String get exportPdf => _isUrdu ? 'PDF ڈاؤن لوڈ' : 'Export PDF';
  static String get exportCsv => _isUrdu ? 'CSV ڈاؤن لوڈ' : 'Export CSV';

  // ─── Common Actions ───
  static String get delete => _isUrdu ? 'حذف کریں' : 'Delete';
  static String get edit => _isUrdu ? 'تبدیل کریں' : 'Edit';
  static String get cancel => _isUrdu ? 'منسوخ' : 'Cancel';
  static String get confirm => _isUrdu ? 'تصدیق' : 'Confirm';
  static String get next => _isUrdu ? 'اگلا' : 'Next';
  static String get previous => _isUrdu ? 'پچھلا' : 'Previous';
  static String get search => _isUrdu ? 'تلاش' : 'Search';
  static String get filter => _isUrdu ? 'فلٹر' : 'Filter';
  static String get sortBy => _isUrdu ? 'ترتیب' : 'Sort By';
  static String get yes => _isUrdu ? 'ہاں' : 'Yes';
  static String get no => _isUrdu ? 'نہیں' : 'No';
  static String get ok => _isUrdu ? 'ٹھیک ہے' : 'OK';
  static String get error => _isUrdu ? 'خرابی' : 'Error';
  static String get success => _isUrdu ? 'کامیاب' : 'Success';
  static String get loading => _isUrdu ? 'لوڈ ہو رہا ہے...' : 'Loading...';
  static String get noData => _isUrdu ? 'کوئی ڈیٹا نہیں' : 'No Data';
  static String get retry => _isUrdu ? 'دوبارہ کوشش' : 'Retry';

  // ─── Confirmation Dialogs ───
  static String get deleteConfirmTitle => _isUrdu ? 'حذف کریں؟' : 'Delete?';
  static String get deleteConfirmMessage =>
      _isUrdu ? 'کیا آپ واقعی حذف کرنا چاہتے ہیں؟' : 'Are you sure you want to delete?';
  static String get undoMessage => _isUrdu ? 'واپس کریں' : 'Undo';

  // ─── Currency ───
  static String get currency => 'Rs.';
  static String formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  // ─── WhatsApp Reminder Template ───
  static String whatsappReminderMessage(String customerName, String shopName, double amount) {
    if (_isUrdu) {
      return 'السلام علیکم $customerName صاحب،\n'
          'آپ کے ذمے $shopName کی طرف سے ${formatAmount(amount)} باقی ہیں۔\n'
          'براہ کرم جلد ادائیگی فرمائیں۔ شکریہ۔';
    } else {
      return 'Dear $customerName,\n'
          'Your outstanding balance at $shopName is ${formatAmount(amount)}.\n'
          'Please make the payment at your earliest convenience. Thank you.';
    }
  }

  // ─── Backup ───
  static String get backupNow => _isUrdu ? 'ابھی بیک اپ لو' : 'Backup Now';
  static String get restoreBackup => _isUrdu ? 'بیک اپ سے بحال کرو' : 'Restore Backup';
  static String get lastBackup => _isUrdu ? 'آخری بیک اپ' : 'Last Backup';

  // ─── Settings ───
  static String get shopName => _isUrdu ? 'دکان کا نام' : 'Shop Name';
  static String get ownerName => _isUrdu ? 'مالک کا نام' : 'Owner Name';
  static String get city => _isUrdu ? 'شہر' : 'City';
  static String get language => _isUrdu ? 'زبان' : 'Language';
  static String get urdu => 'اردو';
  static String get english => 'English';
  static String get pinLock => _isUrdu ? 'پن لاک' : 'PIN Lock';
  static String get biometricLock => _isUrdu ? 'فنگر پرنٹ لاک' : 'Biometric Lock';

  // ─── Expense Categories ───
  static String get rent => _isUrdu ? 'کرایہ' : 'Rent';
  static String get salary => _isUrdu ? 'تنخواہ' : 'Salary';
  static String get electricity => _isUrdu ? 'بجلی' : 'Electricity';
  static String get other => _isUrdu ? 'دیگر' : 'Other';
  static String get addExpense => _isUrdu ? 'اخراجات شامل کریں' : 'Add Expense';
}
