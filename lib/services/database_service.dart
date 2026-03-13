import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../utils/constants.dart';

/// Supabase-backed database service. All CRUD operations hit the live
/// Supabase PostgreSQL backend via REST. No local SQLite used.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  SupabaseClient get _db => Supabase.instance.client;
  String? get _userId => _db.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════
  //  PRODUCTS CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertProduct(Product product) async {
    final map = product.toMap();
    final barcodeVal = map['barcode']?.toString().trim();
    
    await _db.from('products').insert({
      'id': map['id'],
      'user_id': _userId,
      'name': map['name_urdu'] ?? map['name_english'] ?? '',
      'category': map['category'] ?? 'عام',
      'cost_price': map['purchase_price'] ?? 0,
      'sale_price': map['sale_price'] ?? 0,
      'stock': map['stock_quantity'] ?? 0,
      'barcode': (barcodeVal == null || barcodeVal.isEmpty) ? null : barcodeVal,
      'last_updated': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateProduct(Product product) async {
    final map = product.toMap();
    final barcodeVal = map['barcode']?.toString().trim();
    
    await _db.from('products').update({
      'name': map['name_urdu'] ?? map['name_english'] ?? '',
      'category': map['category'] ?? 'عام',
      'cost_price': map['purchase_price'] ?? 0,
      'sale_price': map['sale_price'] ?? 0,
      'stock': map['stock_quantity'] ?? 0,
      'barcode': (barcodeVal == null || barcodeVal.isEmpty) ? null : barcodeVal,
      'last_updated': DateTime.now().toIso8601String(),
    }).eq('id', product.id).eq('user_id', _userId!);
  }

  Future<void> deleteProduct(String id) async {
    // Soft delete: could also just delete the row
    await _db.from('products').delete().eq('id', id);
  }

  Future<List<Product>> getActiveProducts() async {
    final data = await _db
        .from('products')
        .select()
        .eq('user_id', _userId!)
        .order('name', ascending: true);
    return (data as List).map((m) => _mapSupabaseToProduct(m)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final data = await _db
        .from('products')
        .select()
        .eq('user_id', _userId!)
        .or('name.ilike.%$query%,barcode.ilike.%$query%')
        .order('name', ascending: true);
    return (data as List).map((m) => _mapSupabaseToProduct(m)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final data = await _db
        .from('products')
        .select()
        .eq('user_id', _userId!)
        .eq('category', category)
        .order('name', ascending: true);
    return (data as List).map((m) => _mapSupabaseToProduct(m)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final data = await _db
        .from('products')
        .select()
        .eq('user_id', _userId!)
        .lte('stock', 5)
        .order('stock', ascending: true);
    return (data as List).map((m) => _mapSupabaseToProduct(m)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final data = await _db.from('products').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return _mapSupabaseToProduct(data);
  }

  Future<void> updateStock(String productId, int quantityChange) async {
    // Fetch current stock, update
    final current = await _db.from('products').select('stock').eq('id', productId).single();
    final newStock = ((current['stock'] as num?)?.toInt() ?? 0) + quantityChange;
    await _db.from('products').update({'stock': newStock, 'last_updated': DateTime.now().toIso8601String()}).eq('id', productId);
  }

  /// Map Supabase row to local Product model
  Product _mapSupabaseToProduct(Map<String, dynamic> m) {
    return Product.fromMap({
      'id': m['id'],
      'name_urdu': m['name'] ?? '',
      'name_english': m['name'] ?? '',
      'category': m['category'] ?? 'عام',
      'purchase_price': m['cost_price'] ?? 0,
      'sale_price': m['sale_price'] ?? 0,
      'stock_quantity': m['stock'] ?? 0,
      'min_stock_alert': 5,
      'barcode': m['barcode'] ?? '',
      'photo_path': '',
      'is_active': 1,
      'created_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
      'updated_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  CUSTOMERS CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertCustomer(Customer customer) async {
    final map = customer.toMap();
    await _db.from('customers').insert({
      'id': map['id'],
      'shopkeeper_id': _userId,
      'name': map['name'],
      'phone': map['phone'] ?? '',
      'balance': 0.0,
    });
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.from('customers').update({
      'name': customer.name,
      'phone': customer.phone,
    }).eq('id', customer.id);
  }

  Future<void> deleteCustomer(String id) async {
    await _db.from('customers').delete().eq('id', id);
  }

  Future<List<Customer>> getAllCustomers() async {
    final data = await _db
        .from('customers')
        .select()
        .eq('shopkeeper_id', _userId!)
        .order('name', ascending: true);
    return (data as List).map((m) => Customer.fromMap({
      'id': m['id'],
      'name': m['name'] ?? '',
      'phone': m['phone'] ?? '',
      'address': '',
      'photo_path': '',
      'notes': '',
      'created_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
      'updated_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
    })).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final m = await _db.from('customers').select().eq('id', id).maybeSingle();
    if (m == null) return null;
    return Customer.fromMap({
      'id': m['id'],
      'name': m['name'] ?? '',
      'phone': m['phone'] ?? '',
      'address': '',
      'photo_path': '',
      'notes': '',
      'created_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
      'updated_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  CUSTOMER TRANSACTIONS (Buyer Ledger)
  //  Using Supabase RPC or client-side calculation
  // ═══════════════════════════════════════════════════════════

  Future<void> insertCustomerTransaction(CustomerTransaction tx) async {
    final map = tx.toMap();
    // We store transactions in the installments table as a general ledger
    await _db.from('installments').insert({
      'id': map['id'],
      'shopkeeper_id': _userId,
      'customer_id': map['customer_id'],
      'date': map['date'],
      'amount': (map['debit_amount'] ?? 0) - (map['credit_amount'] ?? 0),
      'description': map['description'] ?? '',
    });
    // Also update the customer's balance
    final currentBalance = await getCustomerBalance(tx.customerId);
    final newBalance = currentBalance + (tx.debitAmount - tx.creditAmount);
    await _db.from('customers').update({'balance': newBalance}).eq('id', tx.customerId);
  }

  Future<List<CustomerTransaction>> getCustomerTransactions(String customerId) async {
    final data = await _db
        .from('installments')
        .select()
        .eq('customer_id', customerId)
        .order('date', ascending: false);
    return (data as List).map((m) {
      final amount = (m['amount'] as num?)?.toDouble() ?? 0;
      return CustomerTransaction.fromMap({
        'id': m['id'],
        'customer_id': m['customer_id'],
        'date': m['date'] ?? DateTime.now().toIso8601String(),
        'type': amount >= 0 ? 'DEBIT' : 'CREDIT',
        'description': m['description'] ?? '',
        'debit_amount': amount >= 0 ? amount : 0,
        'credit_amount': amount < 0 ? amount.abs() : 0,
        'running_balance': 0,
        'sale_id': '',
        'payment_method': '',
        'notes': '',
        'created_at': m['date'] ?? DateTime.now().toIso8601String(),
      });
    }).toList();
  }

  Future<List<CustomerTransaction>> getCustomerTransactionsByDateRange(
      String customerId, DateTime start, DateTime end) async {
    final data = await _db
        .from('installments')
        .select()
        .eq('customer_id', customerId)
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String())
        .order('date', ascending: true);
    return (data as List).map((m) {
      final amount = (m['amount'] as num?)?.toDouble() ?? 0;
      return CustomerTransaction.fromMap({
        'id': m['id'],
        'customer_id': m['customer_id'],
        'date': m['date'] ?? DateTime.now().toIso8601String(),
        'type': amount >= 0 ? 'DEBIT' : 'CREDIT',
        'description': m['description'] ?? '',
        'debit_amount': amount >= 0 ? amount : 0,
        'credit_amount': amount < 0 ? amount.abs() : 0,
        'running_balance': 0,
        'sale_id': '',
        'payment_method': '',
        'notes': '',
        'created_at': m['date'] ?? DateTime.now().toIso8601String(),
      });
    }).toList();
  }

  Future<double> getCustomerBalance(String customerId) async {
    final data = await _db.from('customers').select('balance').eq('id', customerId).maybeSingle();
    return (data?['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalReceivable() async {
    final data = await _db.from('customers').select('balance').eq('shopkeeper_id', _userId!);
    double total = 0;
    for (final row in (data as List)) {
      final b = (row['balance'] as num?)?.toDouble() ?? 0;
      if (b > 0) total += b;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getCustomersWithBalance() async {
    final data = await _db
        .from('customers')
        .select()
        .eq('shopkeeper_id', _userId!)
        .order('balance', ascending: false);
    return (data as List).map((m) => {
      'id': m['id'],
      'name': m['name'] ?? '',
      'phone': m['phone'] ?? '',
      'address': '',
      'photo_path': '',
      'notes': '',
      'created_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
      'updated_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
      'balance': (m['balance'] as num?)?.toDouble() ?? 0.0,
      'last_transaction_date': m['last_updated'],
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════
  //  SUPPLIERS CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertSupplier(Supplier supplier) async {
    final map = supplier.toMap();
    await _db.from('customers').insert({
      'id': map['id'],
      'shopkeeper_id': _userId,
      'name': 'SUPPLIER:${map['name']}',
      'phone': map['phone'] ?? '',
      'balance': 0.0,
    });
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _db.from('customers').update({
      'name': 'SUPPLIER:${supplier.name}',
      'phone': supplier.phone,
    }).eq('id', supplier.id);
  }

  Future<void> deleteSupplier(String id) async {
    await _db.from('customers').delete().eq('id', id);
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final data = await _db
        .from('customers')
        .select()
        .eq('shopkeeper_id', _userId!)
        .like('name', 'SUPPLIER:%')
        .order('name', ascending: true);
    return (data as List).map((m) => Supplier.fromMap({
      'id': m['id'],
      'name': (m['name'] as String).replaceFirst('SUPPLIER:', ''),
      'phone': m['phone'] ?? '',
      'address': '',
      'company_name': '',
      'created_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
      'updated_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
    })).toList();
  }

  Future<Supplier?> getSupplierById(String id) async {
    final m = await _db.from('customers').select().eq('id', id).maybeSingle();
    if (m == null) return null;
    return Supplier.fromMap({
      'id': m['id'],
      'name': (m['name'] as String).replaceFirst('SUPPLIER:', ''),
      'phone': m['phone'] ?? '',
      'address': '',
      'company_name': '',
      'created_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
      'updated_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  SUPPLIER TRANSACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> insertSupplierTransaction(SupplierTransaction tx) async {
    final map = tx.toMap();
    await _db.from('installments').insert({
      'id': map['id'],
      'shopkeeper_id': _userId,
      'customer_id': map['supplier_id'],
      'date': map['date'],
      'amount': (map['debit_amount'] ?? 0) - (map['credit_amount'] ?? 0),
      'description': map['description'] ?? '',
    });
    final currentBalance = await getSupplierBalance(tx.supplierId);
    final newBalance = currentBalance + (tx.debitAmount - tx.creditAmount);
    await _db.from('customers').update({'balance': newBalance}).eq('id', tx.supplierId);
  }

  Future<List<SupplierTransaction>> getSupplierTransactions(String supplierId) async {
    final data = await _db
        .from('installments')
        .select()
        .eq('customer_id', supplierId)
        .order('date', ascending: false);
    return (data as List).map((m) {
      final amount = (m['amount'] as num?)?.toDouble() ?? 0;
      return SupplierTransaction.fromMap({
        'id': m['id'],
        'supplier_id': m['customer_id'],
        'date': m['date'] ?? DateTime.now().toIso8601String(),
        'type': amount >= 0 ? 'DEBIT' : 'CREDIT',
        'description': m['description'] ?? '',
        'debit_amount': amount >= 0 ? amount : 0,
        'credit_amount': amount < 0 ? amount.abs() : 0,
        'running_balance': 0,
        'items_json': '',
        'payment_method': '',
        'notes': '',
        'created_at': m['date'] ?? DateTime.now().toIso8601String(),
      });
    }).toList();
  }

  Future<double> getSupplierBalance(String supplierId) async {
    final data = await _db.from('customers').select('balance').eq('id', supplierId).maybeSingle();
    return (data?['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalPayable() async {
    final data = await _db.from('customers')
        .select('balance')
        .eq('shopkeeper_id', _userId!)
        .like('name', 'SUPPLIER:%');
    double total = 0;
    for (final row in (data as List)) {
      final b = (row['balance'] as num?)?.toDouble() ?? 0;
      if (b > 0) total += b;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getSuppliersWithBalance() async {
    final data = await _db
        .from('customers')
        .select()
        .eq('shopkeeper_id', _userId!)
        .like('name', 'SUPPLIER:%')
        .order('balance', ascending: false);
    return (data as List).map((m) => {
      'id': m['id'],
      'name': (m['name'] as String).replaceFirst('SUPPLIER:', ''),
      'phone': m['phone'] ?? '',
      'address': '',
      'company_name': '',
      'created_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
      'updated_at': m['last_updated'] ?? DateTime.now().toIso8601String(),
      'balance': (m['balance'] as num?)?.toDouble() ?? 0.0,
      'last_transaction_date': m['last_updated'],
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════
  //  SALES CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertSale(Sale sale, List<SaleItem> items) async {
    final saleMap = sale.toMap();
    // Insert sale header
    await _db.from('sales').insert({
      'id': saleMap['id'],
      'shopkeeper_id': _userId,
      'customer_id': saleMap['customer_id'],
      'date': saleMap['date'],
      'total_amount': saleMap['subtotal'] ?? saleMap['total'] ?? 0,
      'discount_amount': saleMap['discount'] ?? 0,
      'discount_percentage': saleMap['discount_percentage'] ?? 0,
      'final_amount': saleMap['total'] ?? 0,
      'amount_paid': saleMap['amount_paid'] ?? 0,
    });

    // Insert sale items
    for (final item in items) {
      final itemMap = item.toMap();
      await _db.from('sale_items').insert({
        'id': itemMap['id'],
        'sale_id': saleMap['id'],
        'product_id': itemMap['product_id'],
        'quantity': itemMap['quantity'],
        'unit_price': itemMap['sale_price'] ?? 0,
        'subtotal': (itemMap['quantity'] as num) * ((itemMap['sale_price'] as num?) ?? 0),
      });
      // Decrease stock
      await updateStock(item.productId, -(item.quantity.toInt()));
    }

    // If credit sale, update customer balance
    if (sale.customerId != null && sale.balanceDue > 0) {
      final currentBalance = await getCustomerBalance(sale.customerId!);
      final newBalance = currentBalance + sale.balanceDue;
      await _db.from('customers').update({'balance': newBalance}).eq('id', sale.customerId!);
    }
  }

  Future<void> deleteSale(String saleId) async {
    // 1. Get sale header to check customer balance
    final saleData = await _db.from('sales').select().eq('id', saleId).maybeSingle();
    if (saleData != null) {
      final customerId = saleData['customer_id'] as String?;
      final total = (saleData['final_amount'] as num?)?.toDouble() ?? 0;
      final paid = (saleData['amount_paid'] as num?)?.toDouble() ?? 0;
      final balanceDue = total - paid;
      
      if (customerId != null && balanceDue > 0) {
        final currentBalance = await getCustomerBalance(customerId);
        final newBalance = currentBalance - balanceDue;
        await _db.from('customers').update({'balance': newBalance}).eq('id', customerId);
      }
    }

    // 2. Get sale items to restore stock
    final itemData = await _db.from('sale_items').select().eq('sale_id', saleId);
    for (final item in (itemData as List)) {
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
      final productId = item['product_id'] as String;
      await updateStock(productId, qty.toInt());
    }
    
    // 3. Delete items and header
    await _db.from('sale_items').delete().eq('sale_id', saleId);
    await _db.from('sales').delete().eq('id', saleId);
  }

  Future<void> updateSale(Sale sale, List<SaleItem> newItems) async {
    // Delete old sale and reinsert
    await deleteSale(sale.id);
    await insertSale(sale, newItems);
  }

  Future<List<Sale>> getSalesByDate(DateTime date) async {
    final dateStr = AppFormatters.dateISO(date);
    final data = await _db
        .from('sales')
        .select()
        .eq('shopkeeper_id', _userId!)
        .gte('date', '${dateStr}T00:00:00')
        .lte('date', '${dateStr}T23:59:59')
        .order('date', ascending: false);
    return (data as List).map((m) => _mapSupabaseToSale(m)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final data = await _db
        .from('sales')
        .select()
        .eq('shopkeeper_id', _userId!)
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String())
        .order('date', ascending: false);
    return (data as List).map((m) => _mapSupabaseToSale(m)).toList();
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final data = await _db.from('sale_items').select().eq('sale_id', saleId);
    return (data as List).map((m) => SaleItem.fromMap({
      'id': m['id'],
      'sale_id': m['sale_id'],
      'product_id': m['product_id'] ?? '',
      'product_name': '',
      'quantity': m['quantity'] ?? 0,
      'purchase_price': 0,
      'sale_price': m['unit_price'] ?? 0,
      'profit': 0,
    })).toList();
  }

  Future<double> getTodaySales() async {
    final today = AppFormatters.dateISO(DateTime.now());
    final data = await _db
        .from('sales')
        .select('final_amount')
        .eq('shopkeeper_id', _userId!)
        .gte('date', '${today}T00:00:00')
        .lte('date', '${today}T23:59:59');
    double total = 0;
    for (final row in (data as List)) {
      total += (row['final_amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Future<double> getTodayProfit() async {
    // 1. Estimate gross profit (using a flat 15% margin for now as placeholder)
    final sales = await getTodaySales();
    final grossProfit = sales * 0.15; 

    // 2. Subtract today's expenses to get Net Profit
    final today = AppFormatters.dateISO(DateTime.now());
    final expensesData = await _db
        .from('expenses')
        .select('amount')
        .eq('shopkeeper_id', _userId!)
        .gte('date', '${today}T00:00:00')
        .lte('date', '${today}T23:59:59');
        
    double totalExpenses = 0;
    for (final row in (expensesData as List)) {
      totalExpenses += (row['amount'] as num?)?.toDouble() ?? 0;
    }

    return grossProfit - totalExpenses;
  }

  Future<List<Map<String, dynamic>>> getWeeklySalesProfit() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    // Fetch Sales
    final salesData = await _db
        .from('sales')
        .select('date, final_amount')
        .eq('shopkeeper_id', _userId!)
        .gte('date', sevenDaysAgo.toIso8601String())
        .order('date', ascending: true);

    // Fetch Expenses
    final expensesData = await _db
        .from('expenses')
        .select('date, amount')
        .eq('shopkeeper_id', _userId!)
        .gte('date', sevenDaysAgo.toIso8601String());

    final Map<String, double> salesByDay = {};
    for (final row in (salesData as List)) {
      final day = (row['date'] as String).substring(0, 10);
      salesByDay[day] = (salesByDay[day] ?? 0) + ((row['final_amount'] as num?)?.toDouble() ?? 0);
    }
    
    final Map<String, double> expensesByDay = {};
    for (final row in (expensesData as List)) {
      final day = (row['date'] as String).substring(0, 10);
      expensesByDay[day] = (expensesByDay[day] ?? 0) + ((row['amount'] as num?)?.toDouble() ?? 0);
    }

    return salesByDay.entries.map((e) {
      final day = e.key;
      final sales = e.value;
      final grossProfit = sales * 0.15; // placeholder 15% margin
      final expenses = expensesByDay[day] ?? 0;
      final netProfit = grossProfit - expenses;
      
      return {
        'day': day,
        'total_sales': sales,
        'total_profit': netProfit,
      };
    }).toList();
  }

  Future<double> getCashInHand() async {
    // 1. Sum up all CASH payments received from sales
    final salesData = await _db
        .from('sales')
        .select('amount_paid')
        .eq('shopkeeper_id', _userId!)
        .eq('payment_type', 'CASH');
        
    double totalCashIn = 0;
    for (final row in (salesData as List)) {
      totalCashIn += (row['amount_paid'] as num?)?.toDouble() ?? 0;
    }

    // 2. Sum up all expenses
    final expensesData = await _db
        .from('expenses')
        .select('amount')
        .eq('shopkeeper_id', _userId!);
        
    double totalExpenses = 0;
    for (final row in (expensesData as List)) {
      totalExpenses += (row['amount'] as num?)?.toDouble() ?? 0;
    }

    return totalCashIn - totalExpenses;
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final data = await _db
        .from('expenses')
        .select()
        .eq('shopkeeper_id', _userId!)
        .order('date', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> insertExpenseRaw(Map<String, dynamic> expense) async {
    expense['shopkeeper_id'] = _userId;
    await _db.from('expenses').insert(expense);
  }

  Sale _mapSupabaseToSale(Map<String, dynamic> m) {
    return Sale.fromMap({
      'id': m['id'],
      'date': m['date'] ?? DateTime.now().toIso8601String(),
      'customer_id': m['customer_id'],
      'subtotal': m['total_amount'] ?? 0,
      'discount': m['discount_amount'] ?? 0,
      'discount_percentage': m['discount_percentage'] ?? 0,
      'tax': 0,
      'total': m['final_amount'] ?? 0,
      'profit': 0,
      'payment_type': 'CASH',
      'amount_paid': m['amount_paid'] ?? 0,
      'balance_due': ((m['final_amount'] as num?)?.toDouble() ?? 0) - ((m['amount_paid'] as num?)?.toDouble() ?? 0),
      'bill_pdf_path': '',
      'created_at': m['date'] ?? DateTime.now().toIso8601String(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  EXPENSES CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertExpense(Expense expense) async {
    final map = expense.toMap();
    await _db.from('expenses').insert({
      'id': map['id'],
      'shopkeeper_id': _userId,
      'date': map['date'],
      'amount': map['amount'] ?? 0,
      'description': '${map['category'] ?? ''}: ${map['description'] ?? ''}',
    });
  }

  Future<void> deleteExpense(String id) async {
    await _db.from('expenses').delete().eq('id', id);
  }

  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final dateStr = AppFormatters.dateISO(date);
    final data = await _db
        .from('expenses')
        .select()
        .eq('shopkeeper_id', _userId!)
        .gte('date', '${dateStr}T00:00:00')
        .lte('date', '${dateStr}T23:59:59')
        .order('date', ascending: false);
    return (data as List).map((m) => Expense.fromMap({
      'id': m['id'],
      'date': m['date'] ?? DateTime.now().toIso8601String(),
      'category': 'دیگر',
      'description': m['description'] ?? '',
      'amount': m['amount'] ?? 0,
      'created_at': m['date'] ?? DateTime.now().toIso8601String(),
    })).toList();
  }

  Future<double> getTodayExpenses() async {
    final today = AppFormatters.dateISO(DateTime.now());
    final data = await _db
        .from('expenses')
        .select('amount')
        .eq('shopkeeper_id', _userId!)
        .gte('date', '${today}T00:00:00')
        .lte('date', '${today}T23:59:59');
    double total = 0;
    for (final row in (data as List)) {
      total += (row['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Future<double> getMonthlyExpenses(int year, int month) async {
    final monthStr = month.toString().padLeft(2, '0');
    final startDate = '$year-$monthStr-01T00:00:00';
    final endDate = '$year-$monthStr-31T23:59:59';
    final data = await _db
        .from('expenses')
        .select('amount')
        .eq('shopkeeper_id', _userId!)
        .gte('date', startDate)
        .lte('date', endDate);
    double total = 0;
    for (final row in (data as List)) {
      total += (row['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // ═══════════════════════════════════════════════════════════
  //  SYNC QUEUE (No longer needed with live Supabase, but keep stubs)
  // ═══════════════════════════════════════════════════════════

  Future<void> addToSyncQueue(SyncQueueEntry entry) async {
    // No-op: all writes go directly to Supabase now
  }

  Future<List<SyncQueueEntry>> getPendingSyncEntries() async {
    return []; // No sync queue needed
  }

  Future<void> markSynced(String id) async {}

  Future<int> getPendingSyncCount() async => 0;

  // ═══════════════════════════════════════════════════════════
  //  BACKUP / EXPORT (reads from Supabase)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'products': await _db.from('products').select().eq('user_id', _userId!),
      'customers': await _db.from('customers').select().eq('shopkeeper_id', _userId!),
      'sales': await _db.from('sales').select().eq('shopkeeper_id', _userId!),
      'expenses': await _db.from('expenses').select().eq('shopkeeper_id', _userId!),
      'installments': await _db.from('installments').select().eq('shopkeeper_id', _userId!),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    // Not implemented for Supabase migration; data lives on server
  }

  // ═══════════════════════════════════════════════════════════
  //  USERS (Auth) - Now handled by Supabase Auth, keep stubs
  // ═══════════════════════════════════════════════════════════

  Future<void> insertUser(Map<String, dynamic> userData) async {
    // Handled by Supabase Auth signUp
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    return null; // Handled by Supabase Auth
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    return null; // Handled by Supabase Auth
  }

  Future<bool> isPhoneRegistered(String phone) async => false;

  Future<void> updateUserPin(String phone, String newPin) async {
    // Handled by Supabase Auth password reset
  }

  // ═══════════════════════════════════════════════════════════
  //  INSTALLMENTS
  // ═══════════════════════════════════════════════════════════

  Future<void> insertInstallment(Map<String, dynamic> data) async {
    await _db.from('installments').insert({
      'id': data['id'],
      'shopkeeper_id': _userId,
      'customer_id': data['customer_id'],
      'date': data['date'],
      'amount': data['total_amount'] ?? data['amount'] ?? 0,
      'description': data['notes'] ?? '',
    });
  }

  Future<List<Map<String, dynamic>>> getInstallments(String customerId) async {
    final data = await _db
        .from('installments')
        .select()
        .eq('customer_id', customerId)
        .order('date', ascending: false);
    return (data as List).map((m) => {
      'id': m['id'],
      'customer_id': m['customer_id'],
      'total_amount': m['amount'] ?? 0,
      'paid_amount': m['amount'] ?? 0,
      'remaining': 0,
      'installment_number': 1,
      'date': m['date'] ?? DateTime.now().toIso8601String(),
      'status': 'CLEARED',
      'notes': m['description'] ?? '',
      'created_at': m['date'] ?? DateTime.now().toIso8601String(),
    }).toList();
  }

  Future<void> updateInstallmentPayment(String installmentId, double paidAmount, double remaining) async {
    await _db.from('installments').update({
      'amount': paidAmount,
      'description': remaining <= 0 ? 'CLEARED' : 'PENDING',
    }).eq('id', installmentId);
  }

  /// Close — no-op for Supabase
  Future<void> close() async {}
}
