/// Urdu-English localization strings for the shop app.
/// Displays both languages simultaneously (Urdu / English) in all menus.
class AppStrings {
  AppStrings._();

  // Current language state (No longer toggles strings, always shows both)
  static bool _isUrdu = true;

  static bool get isUrdu => _isUrdu;

  static void setUrdu(bool value) {
    _isUrdu = value;
  }

  static void toggleLanguage() {
    _isUrdu = !_isUrdu;
  }

  // ─── App Info ───
  static String get appName => _isUrdu ? 'سپر بزنس شاپ / Super Business Shop' : 'Super Business Shop';

  // ─── Navigation ───
  static String get home => _isUrdu ? 'ہوم / Home' : 'Home';
  static String get sale => _isUrdu ? 'فروخت / Sale' : 'Sale';
  static String get stock => _isUrdu ? 'اسٹاک / Stock' : 'Stock';
  static String get customers => _isUrdu ? 'گاہک / Customers' : 'Customers';
  static String get reports => _isUrdu ? 'رپورٹ / Reports' : 'Reports';
  static String get suppliers => _isUrdu ? 'سپلائر / Suppliers' : 'Suppliers';
  static String get googleSheet => _isUrdu ? 'گوگل شیٹ / Google Sheet' : 'Google Sheet';
  static String get moneyFlow => _isUrdu ? 'نقد بہاؤ / Money Flow' : 'Money Flow';
  static String get expenses => _isUrdu ? 'اخراجات / Expenses' : 'Expenses';
  static String get backup => _isUrdu ? 'بیک اپ / Backup' : 'Backup';
  static String get switchShop => _isUrdu ? 'دکان بدلو / Switch Shop' : 'Switch Shop';
  static String get settings => _isUrdu ? 'ترتیبات / Settings' : 'Settings';
  static String get help => _isUrdu ? 'مدد / Help' : 'Help';

  // ─── Dashboard ───
  static String get todaySales => _isUrdu ? 'آج کی فروخت / Today\'s Sales' : 'Today\'s Sales';
  static String get todayProfit => _isUrdu ? 'آج کا منافع / Today\'s Profit' : 'Today\'s Profit';
  static String get totalReceivable => _isUrdu ? 'ادھار ملنی / Total Receivable' : 'Total Receivable';
  static String get totalPayable => _isUrdu ? 'ادھار دینی / Total Payable' : 'Total Payable';
  static String get newSale => _isUrdu ? 'نئی فروخت / New Sale' : 'New Sale';
  static String get lowStockAlerts => _isUrdu ? 'کم اسٹاک الرٹ / Low Stock Alerts' : 'Low Stock Alerts';
  static String get salesVsProfit => _isUrdu ? 'فروخت بمقابلہ منافع / Sales vs Profit' : 'Sales vs Profit';

  // ─── Products ───
  static String get products => _isUrdu ? 'مصنوعات / Products' : 'Products';
  static String get addProduct => _isUrdu ? 'مصنوعات شامل کریں / Add Product' : 'Add Product';
  static String get editProduct => _isUrdu ? 'مصنوعات تبدیل کریں / Edit Product' : 'Edit Product';
  static String get productName => _isUrdu ? 'نام / Product Name' : 'Product Name';
  static String get productNameEnglish => _isUrdu ? 'انگریزی نام / English Name' : 'English Name';
  static String get purchasePrice => _isUrdu ? 'قیمت خرید / Purchase Price' : 'Purchase Price';
  static String get salePrice => _isUrdu ? 'قیمت فروخت / Sale Price' : 'Sale Price';
  static String get stockQuantity => _isUrdu ? 'اسٹاک / Stock' : 'Stock';
  static String get minStockAlert => _isUrdu ? 'کم از کم اسٹاک / Min Stock Alert' : 'Min Stock Alert';
  static String get category => _isUrdu ? 'زمرہ / Category' : 'Category';
  static String get barcode => _isUrdu ? 'بارکوڈ / Barcode' : 'Barcode';
  static String get searchProducts => _isUrdu ? 'مصنوعات تلاش کریں / Search Products' : 'Search Products';

  // ─── Customers / Buyer Ledger ───
  static String get addCustomer => _isUrdu ? 'نیا گاہک / Add Customer' : 'Add Customer';
  static String get customerName => _isUrdu ? 'گاہک کا نام / Customer Name' : 'Customer Name';
  static String get phone => _isUrdu ? 'فون / Phone' : 'Phone';
  static String get address => _isUrdu ? 'پتہ / Address' : 'Address';
  static String get totalRemaining => _isUrdu ? 'کل باقی / Total Remaining' : 'Total Remaining';
  static String get receivePayment => _isUrdu ? 'ادائیگی لو / Receive Payment' : 'Receive Payment';
  static String get creditSale => _isUrdu ? 'ادھار فروخت / Credit Sale' : 'Credit Sale';
  static String get cashSale => _isUrdu ? 'نقد فروخت / Cash Sale' : 'Cash Sale';
  static String get paymentReceived => _isUrdu ? 'ادائیگی موصول / Payment Received' : 'Payment Received';
  static String get returnGoods => _isUrdu ? 'مال واپسی / Return' : 'Return';
  static String get advancePayment => _isUrdu ? 'پیشگی ادائیگی / Advance Payment' : 'Advance Payment';
  static String get partialPayment => _isUrdu ? 'جزوی ادائیگی / Partial Payment' : 'Partial Payment';
  static String get whatsappReminder => _isUrdu ? 'واٹس ایپ یاد دہانی / WhatsApp Reminder' : 'WhatsApp Reminder';
  static String get viewBill => _isUrdu ? 'بل دیکھو / View Bill' : 'View Bill';
  static String get sendPdf => _isUrdu ? 'پی ڈی ایف بھیجو / Send PDF' : 'Send PDF';

  // ─── Supplier Ledger ───
  static String get addSupplier => _isUrdu ? 'نیا سپلائر / Add Supplier' : 'Add Supplier';
  static String get supplierName => _isUrdu ? 'سپلائر کا نام / Supplier Name' : 'Supplier Name';
  static String get companyName => _isUrdu ? 'کمپنی / Company' : 'Company';
  static String get youOwe => _isUrdu ? 'آپ کے ذمے / You Owe' : 'You Owe';
  static String get makePayment => _isUrdu ? 'ادائیگی کرو / Make Payment' : 'Make Payment';
  static String get addPurchase => _isUrdu ? 'خریداری شامل کرو / Add Purchase' : 'Add Purchase';
  static String get creditPurchase => _isUrdu ? 'ادھار خریداری / Credit Purchase' : 'Credit Purchase';
  static String get cashPurchase => _isUrdu ? 'نقد خریداری / Cash Purchase' : 'Cash Purchase';
  static String get paymentMade => _isUrdu ? 'ادائیگی کی / Payment Made' : 'Payment Made';
  static String get returnToSupplier => _isUrdu ? 'واپسی سپلائر کو / Return to Supplier' : 'Return to Supplier';

  // ─── Ledger Table Headers ───
  static String get date => _isUrdu ? 'تاریخ / Date' : 'Date';
  static String get description => _isUrdu ? 'تفصیل / Description' : 'Description';
  static String get debit => _isUrdu ? 'ڈیبٹ / Debit (DR)' : 'Debit (DR)';
  static String get credit => _isUrdu ? 'کریڈٹ / Credit (CR)' : 'Credit (CR)';
  static String get balance => _isUrdu ? 'بیلنس / Balance' : 'Balance';
  static String get amount => _isUrdu ? 'رقم / Amount' : 'Amount';

  // ─── Money Flow ───
  static String get moneyToReceive => _isUrdu ? 'مجھے ملنے والی رقم / Money I Will Receive' : 'Money I Will Receive';
  static String get moneyToPay => _isUrdu ? 'مجھے دینی والی رقم / Money I Must Pay' : 'Money I Must Pay';
  static String get netPosition => _isUrdu ? 'خالص پوزیشن / Net Position' : 'Net Position';
  static String get todayPayments => _isUrdu ? 'آج کی ادائیگیاں / Today\'s Payments' : 'Today\'s Payments';
  static String get agingAnalysis => _isUrdu ? 'بقایا رقم / Aging Analysis' : 'Aging Analysis';
  static String get youAreInProfit => _isUrdu ? 'آپ فائدے میں ہیں / You Are In Profit' : 'You Are In Profit';
  static String get youNeedToPay => _isUrdu ? 'آپ کو ادائیگی کرنی ہے / You Need To Pay' : 'You Need To Pay';
  static String get viewAllCustomers => _isUrdu ? 'تمام گاہک دیکھو / View All Customers' : 'View All Customers';
  static String get viewAllSuppliers => _isUrdu ? 'تمام سپلائر دیکھو / View All Suppliers' : 'View All Suppliers';
  static String get totalUdhaar => _isUrdu ? 'کل ادھار / Total Credit' : 'Total Credit';
  static String get totalPayableAmount => _isUrdu ? 'کل واجب الادا / Total Payable' : 'Total Payable';

  // ─── Sheets Editor ───
  static String get addRow => _isUrdu ? '+ قطار شامل کریں / + Add Row' : '+ Add Row';
  static String get save => _isUrdu ? 'محفوظ کریں / Save' : 'Save';
  static String get refresh => _isUrdu ? 'تازہ کریں / Refresh' : 'Refresh';
  static String get pending => _isUrdu ? 'انتظار میں / Pending' : 'Pending';
  static String get changesUploaded => _isUrdu ? 'تبدیلیاں اپ لوڈ ہوئیں / Changes Uploaded' : 'Changes Uploaded';
  static String get conflictDetected => _isUrdu ? '2 جگہ تبدیلی ہوئی / Changed In 2 Places' : 'Changed In 2 Places';

  // ─── POS / Billing ───
  static String get billNo => _isUrdu ? 'بل نمبر / Bill No' : 'Bill No';
  static String get subtotal => _isUrdu ? 'ذیلی کل / Subtotal' : 'Subtotal';
  static String get discount => _isUrdu ? 'رعایت / Discount' : 'Discount';
  static String get tax => _isUrdu ? 'ٹیکس / Tax' : 'Tax';
  static String get total => _isUrdu ? 'کل / Total' : 'Total';
  static String get cash => _isUrdu ? 'نقد / Cash' : 'Cash';
  static String get udhaar => _isUrdu ? 'ادھار / Credit' : 'Credit';
  static String get partial => _isUrdu ? 'جزوی / Partial' : 'Partial';
  static String get amountPaid => _isUrdu ? 'ادا شدہ رقم / Amount Paid' : 'Amount Paid';
  static String get balanceDue => _isUrdu ? 'باقی رقم / Balance Due' : 'Balance Due';
  static String get generateBill => _isUrdu ? 'بل بنائیں / Generate Bill' : 'Generate Bill';
  static String get shareOnWhatsapp => _isUrdu ? 'واٹس ایپ پر بھیجو / Share on WhatsApp' : 'Share on WhatsApp';
  static String get print => _isUrdu ? 'پرنٹ / Print' : 'Print';

  // ─── Reports ───
  static String get dailyReport => _isUrdu ? 'روزانہ رپورٹ / Daily Report' : 'Daily Report';
  static String get weeklyReport => _isUrdu ? 'ہفتہ وار رپورٹ / Weekly Report' : 'Weekly Report';
  static String get monthlyReport => _isUrdu ? 'ماہانہ رپورٹ / Monthly Report' : 'Monthly Report';
  static String get profitReport => _isUrdu ? 'منافع رپورٹ / Profit Report' : 'Profit Report';
  static String get inventoryReport => _isUrdu ? 'اسٹاک رپورٹ / Inventory Report' : 'Inventory Report';
  static String get exportPdf => _isUrdu ? 'PDF ڈاؤن لوڈ / Export PDF' : 'Export PDF';
  static String get exportCsv => _isUrdu ? 'CSV ڈاؤن لوڈ / Export CSV' : 'Export CSV';

  // ─── Common Actions ───
  static String get delete => _isUrdu ? 'حذف کریں / Delete' : 'Delete';
  static String get edit => _isUrdu ? 'تبدیل کریں / Edit' : 'Edit';
  static String get cancel => _isUrdu ? 'منسوخ / Cancel' : 'Cancel';
  static String get confirm => _isUrdu ? 'تصدیق / Confirm' : 'Confirm';
  static String get next => _isUrdu ? 'اگلا / Next' : 'Next';
  static String get previous => _isUrdu ? 'پچھلا / Previous' : 'Previous';
  static String get search => _isUrdu ? 'تلاش / Search' : 'Search';
  static String get filter => _isUrdu ? 'فلٹر / Filter' : 'Filter';
  static String get sortBy => _isUrdu ? 'ترتیب / Sort By' : 'Sort By';
  static String get yes => _isUrdu ? 'ہاں / Yes' : 'Yes';
  static String get no => _isUrdu ? 'نہیں / No' : 'No';
  static String get ok => _isUrdu ? 'ٹھیک ہے / OK' : 'OK';
  static String get error => _isUrdu ? 'خرابی / Error' : 'Error';
  static String get success => _isUrdu ? 'کامیاب / Success' : 'Success';
  static String get loading => _isUrdu ? 'لوڈ ہو رہا ہے... / Loading...' : 'Loading...';
  static String get noData => _isUrdu ? 'کوئی ڈیٹا نہیں / No Data' : 'No Data';
  static String get retry => _isUrdu ? 'دوبارہ کوشش / Retry' : 'Retry';

  // ─── Confirmation Dialogs ───
  static String get deleteConfirmTitle => _isUrdu ? 'حذف کریں؟ / Delete?' : 'Delete?';
  static String get deleteConfirmMessage =>
      _isUrdu ? 'کیا آپ واقعی حذف کرنا چاہتے ہیں؟ \n Are you sure you want to delete?' : 'Are you sure you want to delete?';
  static String get undoMessage => _isUrdu ? 'واپس کریں / Undo' : 'Undo';

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
          'براہ کرم جلد ادائیگی فرمائیں۔ شکریہ۔\n\n'
          'Dear $customerName,\n'
          'Your outstanding balance at $shopName is ${formatAmount(amount)}.\n'
          'Please make the payment at your earliest convenience. Thank you.';
    } else {
      return 'Dear $customerName,\n'
          'Your outstanding balance at $shopName is ${formatAmount(amount)}.\n'
          'Please make the payment at your earliest convenience. Thank you.';
    }
  }

  // ─── Backup ───
  static String get backupNow => _isUrdu ? 'ابھی بیک اپ لو / Backup Now' : 'Backup Now';
  static String get restoreBackup => _isUrdu ? 'بیک اپ سے بحال کرو / Restore Backup' : 'Restore Backup';
  static String get lastBackup => _isUrdu ? 'آخری بیک اپ / Last Backup' : 'Last Backup';

  // ─── Settings ───
  static String get shopName => _isUrdu ? 'دکان کا نام / Shop Name' : 'Shop Name';
  static String get ownerName => _isUrdu ? 'مالک کا نام / Owner Name' : 'Owner Name';
  static String get city => _isUrdu ? 'شہر / City' : 'City';
  static String get language => _isUrdu ? 'زبان / Language' : 'Language';
  static String get urdu => 'اردو / Urdu';
  static String get english => 'English';
  static String get pinLock => _isUrdu ? 'پن لاک / PIN Lock' : 'PIN Lock';
  static String get biometricLock => _isUrdu ? 'فنگر پرنٹ لاک / Biometric Lock' : 'Biometric Lock';

  // ─── Expense Categories ───
  static String get rent => _isUrdu ? 'کرایہ / Rent' : 'Rent';
  static String get salary => _isUrdu ? 'تنخواہ / Salary' : 'Salary';
  static String get electricity => _isUrdu ? 'بجلی / Electricity' : 'Electricity';
  static String get other => _isUrdu ? 'دیگر / Other' : 'Other';
  static String get addExpense => _isUrdu ? 'اخراجات شامل کریں / Add Expense' : 'Add Expense';
}
