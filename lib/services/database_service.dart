import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'local_db_service.dart';
import 'sync_queue.dart';
import '../utils/constants.dart';

/// Supabase-backed database service. All CRUD operations hit the live
/// Supabase PostgreSQL backend via REST. No local SQLite used.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  SupabaseClient get _db => Supabase.instance.client;
  String? get _userIdVal => _db.auth.currentUser?.id;

  String? _cachedShopId;
  Future<String?> getShopId() => _getShopId();
  Future<String?> _getShopId() async {
    if (_cachedShopId != null) return _cachedShopId;
    final uid = _userIdVal;
    if (uid == null) return null;
    
    try {
      final res = await _db.from('shop_members').select('shop_id').eq('user_id', uid).maybeSingle();
      if (res != null) {
        _cachedShopId = res['shop_id'] as String;
      } else {
        // Auto-create shop for users
        final shopRes = await _db.from('shops').select('id').eq('owner_id', uid).maybeSingle();
        if (shopRes != null) {
          _cachedShopId = shopRes['id'] as String;
          await _db.from('shop_members').insert({'shop_id': _cachedShopId, 'user_id': uid, 'role': 'owner'});
        } else {
          final newShop = await _db.from('shops').insert({'owner_id': uid}).select('id').single();
          _cachedShopId = newShop['id'] as String;
          await _db.from('shop_members').insert({'shop_id': _cachedShopId, 'user_id': uid, 'role': 'owner'});
          await _db.from('shop_settings').insert({'shop_id': _cachedShopId});
        }
      }
    } catch (e) {
      print('Error auto-creating shop: $e');
    }
    return _cachedShopId;
  }

  // ═══════════════════════════════════════════════════════════
  //  PRODUCTS CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertProduct(Product product) async {
    final map = product.toMap();
    final barcodeVal = map['barcode']?.toString().trim();
    
    await _db.from('products').insert({
      'id': map['id'],
      'shop_id': (await _getShopId()),
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
    }).eq('id', product.id).eq('shop_id', (await _getShopId())!);
  }

  Future<void> deleteProduct(String id) async {
    // Soft delete: could also just delete the row
    await _db.from('products').delete().eq('id', id);
  }

  Future<List<Product>> getActiveProducts() async {
    try {
      final localDb = await LocalDbService.instance.database;
      final localData = await localDb.query(
        'local_products',
        where: 'shop_id = ? AND is_active = 1',
        whereArgs: [(await _getShopId())!],
        orderBy: 'name ASC',
      );
      if (localData.isNotEmpty) {
        return localData.map((m) => Product.fromMap({
          'id': m['id'],
          'name_urdu': m['name_urdu'] ?? m['name'],
          'name_english': m['name'],
          'category': m['category'] ?? 'عام', 
          'purchase_price': m['purchase_price'] ?? 0,
          'sale_price': m['sale_price'] ?? 0,
          'stock_quantity': m['stock_quantity'] ?? 0,
          'barcode': m['barcode'],
        })).toList();
      }
    } catch (_) {}

    final data = await _db
        .from('products')
        .select()
        .eq('shop_id', (await _getShopId())!)
        .eq('is_active', true)
        .order('name', ascending: true);
    return (data as List).map((m) => _mapSupabaseToProduct(m)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final data = await _db
        .from('products')
        .select()
        .eq('shop_id', (await _getShopId())!)
        .or('name.ilike.%$query%,barcode.ilike.%$query%')
        .order('name', ascending: true);
    return (data as List).map((m) => _mapSupabaseToProduct(m)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final data = await _db
        .from('products')
        .select()
        .eq('shop_id', (await _getShopId())!)
        .eq('category', category)
        .order('name', ascending: true);
    return (data as List).map((m) => _mapSupabaseToProduct(m)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final data = await _db
        .from('products')
        .select()
        .eq('shop_id', (await _getShopId())!)
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
      'shop_id': (await _getShopId()),
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
        .eq('shop_id', (await _getShopId())!)
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
      'shop_id': (await _getShopId()),
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

  Future<void> deleteInstallment(String id) async {
    // Need to adjust customer balance back
    final tx = await _db.from('installments').select().eq('id', id).maybeSingle();
    if (tx != null) {
      final customerId = tx['customer_id'] as String;
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      // if positive it was a charge, if negative it was a payment
      final currentBalance = await getCustomerBalance(customerId);
      final newBalance = currentBalance - amount;
      await _db.from('customers').update({'balance': newBalance}).eq('id', customerId);
    }
    await _db.from('installments').delete().eq('id', id);
  }

  Future<List<CustomerTransaction>> getCustomerTransactions(String customerId) async {
    final salesR = await _db.from('sales').select().eq('customer_id', customerId);
    final paymentsR = await _db.from('installments').select().eq('customer_id', customerId);
    
    final List<CustomerTransaction> combined = [];
    
    for (final s in (salesR as List)) {
      final isUdhaar = s['payment_type'] == 'udhaar';
      final amount = (s['final_amount'] as num?)?.toDouble() ?? 0;
      combined.add(CustomerTransaction(
        id: s['id'],
        customerId: customerId,
        date: DateTime.parse(s['date'] ?? DateTime.now().toIso8601String()),
        type: isUdhaar ? 'CREDIT_SALE' : 'CASH_SALE',
        description: 'Bill #${s['bill_number'] ?? ''}',
        debitAmount: amount, // Billed amount
        saleId: s['id'],
        hiddenFromCustomer: s['hidden_from_customer'] ?? false,
      ));
    }
    
    for (final p in (paymentsR as List)) {
      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
      final type = p['type'] == 'payment' ? 'PAYMENT_RECEIVED' : 'CHARGE';
      combined.add(CustomerTransaction(
        id: p['id'],
        customerId: customerId,
        date: DateTime.parse(p['date'] ?? DateTime.now().toIso8601String()),
        type: type,
        description: p['description'] ?? '',
        creditAmount: type == 'PAYMENT_RECEIVED' ? amount : 0,
        debitAmount: type == 'CHARGE' ? amount : 0,
        hiddenFromCustomer: false,
      ));
    }
    
    combined.sort((a, b) => a.date.compareTo(b.date)); // Sort ascending for running balance
    
    double running = 0;
    final List<CustomerTransaction> balanced = [];
    for (final tx in combined) {
      running += (tx.debitAmount - tx.creditAmount);
      balanced.add(CustomerTransaction(
        id: tx.id,
        customerId: tx.customerId,
        date: tx.date,
        type: tx.type,
        description: tx.description,
        debitAmount: tx.debitAmount,
        creditAmount: tx.creditAmount,
        runningBalance: running,
        saleId: tx.saleId,
        hiddenFromCustomer: tx.hiddenFromCustomer,
      ));
    }
    
    return balanced.reversed.toList(); // Return descending for UI
  }

  Future<List<CustomerTransaction>> getCustomerTransactionsByDateRange(
      String customerId, DateTime start, DateTime end) async {
    final salesR = await _db.from('sales').select()
      .eq('customer_id', customerId)
      .gte('date', start.toIso8601String())
      .lte('date', end.toIso8601String());
      
    final paymentsR = await _db.from('installments').select()
      .eq('customer_id', customerId)
      .gte('date', start.toIso8601String())
      .lte('date', end.toIso8601String());
      
    final List<CustomerTransaction> combined = [];
    
    for (final s in (salesR as List)) {
      final isUdhaar = s['payment_type'] == 'udhaar';
      final amount = (s['final_amount'] as num?)?.toDouble() ?? 0;
      combined.add(CustomerTransaction(
        id: s['id'],
        customerId: customerId,
        date: DateTime.parse(s['date'] ?? DateTime.now().toIso8601String()),
        type: isUdhaar ? 'CREDIT_SALE' : 'CASH_SALE',
        description: 'Bill #${s['bill_number'] ?? ''}',
        debitAmount: amount,
        saleId: s['id'],
        hiddenFromCustomer: s['hidden_from_customer'] ?? false,
      ));
    }
    
    for (final p in (paymentsR as List)) {
      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
      final type = p['type'] == 'payment' ? 'PAYMENT_RECEIVED' : 'CHARGE';
      combined.add(CustomerTransaction(
        id: p['id'],
        customerId: customerId,
        date: DateTime.parse(p['date'] ?? DateTime.now().toIso8601String()),
        type: type,
        description: p['description'] ?? '',
        creditAmount: type == 'PAYMENT_RECEIVED' ? amount : 0,
        debitAmount: type == 'CHARGE' ? amount : 0,
        hiddenFromCustomer: false,
      ));
    }
    
    combined.sort((a, b) => a.date.compareTo(b.date)); // Sort ascending for running balance
    
    double running = 0;
    final List<CustomerTransaction> balanced = [];
    for (final tx in combined) {
      running += (tx.debitAmount - tx.creditAmount);
      balanced.add(CustomerTransaction(
        id: tx.id,
        customerId: tx.customerId,
        date: tx.date,
        type: tx.type,
        description: tx.description,
        debitAmount: tx.debitAmount,
        creditAmount: tx.creditAmount,
        runningBalance: running,
        saleId: tx.saleId,
        hiddenFromCustomer: tx.hiddenFromCustomer,
      ));
    }
    
    return balanced.reversed.toList();
  }
  
  Future<void> toggleBillVisibility(String saleId, bool isHidden) async {
    await _db.from('sales').update({'hidden_from_customer': isHidden}).eq('id', saleId);
  }

  Future<Map<String, dynamic>> getCustomerVisibility(String customerId) async {
    final data = await _db.from('customer_bill_visibility').select().eq('customer_id', customerId).maybeSingle();
    if (data == null) {
      return {'show_udhaar': true, 'show_paid_bills': true, 'show_balance': true}; // Defaults
    }
    return data;
  }

  Future<DateTime?> getCustomerLastActivity(String customerId) async {
    final customer = await _db.from('customers').select('phone').eq('id', customerId).maybeSingle();
    final phone = customer?['phone'];
    if (phone == null || phone.isEmpty) return null;
    
    final acc = await _db.from('customer_accounts').select('last_login').eq('phone', phone).maybeSingle();
    if (acc == null || acc['last_login'] == null) return null;
    
    return DateTime.parse(acc['last_login']);
  }

  Future<void> setCustomerVisibility(String customerId, Map<String, dynamic> settings) async {
    final shopId = (await _getShopId())!;
    final payload = {
      'shop_id': shopId,
      'customer_id': customerId,
      'show_udhaar': settings['show_udhaar'] ?? true,
      'show_paid_bills': settings['show_paid_bills'] ?? true,
      'show_balance': settings['show_balance'] ?? true,
    };
    
    // Attempt upsert
    final existing = await _db.from('customer_bill_visibility').select('id').eq('customer_id', customerId).maybeSingle();
    if (existing != null) {
      await _db.from('customer_bill_visibility').update(payload).eq('id', existing['id']);
    } else {
      await _db.from('customer_bill_visibility').insert(payload);
    }
  }

  Future<double> getCustomerBalance(String customerId) async {
    final data = await _db.from('customers').select('balance').eq('id', customerId).maybeSingle();
    return (data?['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalReceivable() async {
    final data = await _db.from('customers').select('balance').eq('shop_id', (await _getShopId())!);
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
        .eq('shop_id', (await _getShopId())!)
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
      'shop_id': (await _getShopId()),
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
        .eq('shop_id', (await _getShopId())!)
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
      'shop_id': (await _getShopId()),
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
        .eq('shop_id', (await _getShopId())!)
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
        .eq('shop_id', (await _getShopId())!)
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
    final shopId = (await _getShopId())!;
    final localDb = await LocalDbService.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Write to local_sales
    final salesPayload = {
      'id': saleMap['id'],
      'shop_id': shopId,
      'customer_id': saleMap['customer_id'],
      'date': saleMap['date'],
      'total_amount': saleMap['subtotal'] ?? saleMap['total'] ?? 0,
      'discount_amount': saleMap['discount'] ?? 0,
      'discount_percentage': saleMap['discount_percentage'] ?? 0,
      'final_amount': saleMap['total'] ?? 0,
      'amount_paid': saleMap['amount_paid'] ?? 0,
      'payment_type': saleMap['payment_type'] ?? 'CASH',
      'bill_number': saleMap['bill_number'],
    };

    await localDb.insert('local_sales', {
      'id': saleMap['id'],
      'local_id': 'BILL-$nowMs',
      'shop_id': shopId,
      'customer_id': saleMap['customer_id'] ?? '',
      'total_amount': salesPayload['final_amount'],
      'payment_type': salesPayload['payment_type'],
      'bill_number': saleMap['bill_number'] ?? '',
      'created_at': nowMs,
    });

    await SyncQueue.instance.add(
      operation: 'insert',
      tableName: 'sales',
      recordId: saleMap['id'],
      payload: salesPayload,
    );

    // 2. Insert sale items
    for (final item in items) {
      final itemMap = item.toMap();
      final itemPayload = {
        'id': itemMap['id'],
        'sale_id': saleMap['id'],
        'product_id': itemMap['product_id'],
        'quantity': itemMap['quantity'],
        'unit_price': itemMap['sale_price'] ?? 0,
        'purchase_price': itemMap['purchase_price'] ?? 0,
        'subtotal': (itemMap['quantity'] as num) * ((itemMap['sale_price'] as num?) ?? 0),
      };

      await localDb.insert('local_sale_items', {
        'id': itemMap['id'],
        'sale_id': saleMap['id'],
        'product_id': itemMap['product_id'],
        'quantity': itemMap['quantity'],
        'unit_price': itemMap['sale_price'] ?? 0,
        'purchase_price': itemMap['purchase_price'] ?? 0,
      });

      await SyncQueue.instance.add(
        operation: 'insert',
        tableName: 'sale_items',
        recordId: itemMap['id'],
        payload: itemPayload,
      );

      // Deduct stock locally
      await localDb.rawUpdate(
        'UPDATE local_products SET stock_quantity = stock_quantity - ? WHERE id = ?',
        [item.quantity.toInt(), item.productId]
      );
      
      // Update Supabase stock (optimistic overwrite for now)
      final pResult = await localDb.query('local_products', where: 'id = ?', whereArgs: [item.productId]);
      if (pResult.isNotEmpty) {
        final newStock = pResult.first['stock_quantity'] as int;
        await SyncQueue.instance.add(
          operation: 'update',
          tableName: 'products',
          recordId: item.productId,
          payload: {'stock': newStock, 'last_updated': DateTime.now().toIso8601String()},
        );
      }
    }

    // 3. Update customer balance if credit sale
    if (sale.customerId != null && sale.balanceDue > 0) {
      await localDb.rawUpdate(
        'UPDATE local_customers SET balance = balance + ? WHERE id = ?',
        [sale.balanceDue, sale.customerId]
      );
      
      final cResult = await localDb.query('local_customers', where: 'id = ?', whereArgs: [sale.customerId]);
      if (cResult.isNotEmpty) {
        final newBalance = (cResult.first['balance'] as num).toDouble();
        await SyncQueue.instance.add(
          operation: 'update',
          tableName: 'customers',
          recordId: sale.customerId!,
          payload: {'balance': newBalance, 'last_updated': DateTime.now().toIso8601String()},
        );
      }
      
      // Note: In Supabase we let get_customer_balance calculate it later, 
      // but for legacy frontend we update the explicit balance column.
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
        .eq('shop_id', (await _getShopId())!)
        .gte('date', '${dateStr}T00:00:00')
        .lte('date', '${dateStr}T23:59:59')
        .order('date', ascending: false);
    return (data as List).map((m) => _mapSupabaseToSale(m)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final data = await _db
        .from('sales')
        .select()
        .eq('shop_id', (await _getShopId())!)
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
        .eq('shop_id', (await _getShopId())!)
        .gte('date', '${today}T00:00:00')
        .lte('date', '${today}T23:59:59');
    double total = 0;
    for (final row in (data as List)) {
      total += (row['final_amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Future<double> getTodayProfit() async {
    final today = AppFormatters.dateISO(DateTime.now());
    
    // 1. Get today's sales revenue
    final sales = await getTodaySales();
    
    // 2. Get actual cost of goods sold (from sale_items × product cost_price)
    final costData = await _db
        .from('sale_items')
        .select('quantity, subtotal, sale_id, product_id')
        .filter('sale_id', 'in', '(SELECT id FROM sales WHERE shop_id = \'$(await _getShopId())\' AND date >= \'${today}T00:00:00\' AND date <= \'${today}T23:59:59\')');
    
    // Fallback: calculate cost from products table
    double totalCost = 0;
    for (final row in (costData as List)) {
      final productId = row['product_id'] as String?;
      final qty = (row['quantity'] as num?)?.toDouble() ?? 0;
      if (productId != null) {
        final product = await _db.from('products').select('cost_price').eq('id', productId).maybeSingle();
        if (product != null) {
          totalCost += qty * ((product['cost_price'] as num?)?.toDouble() ?? 0);
        }
      }
    }

    // 3. Subtract today's expenses to get Net Profit
    final expensesData = await _db
        .from('expenses')
        .select('amount')
        .eq('shop_id', (await _getShopId())!)
        .gte('date', '${today}T00:00:00')
        .lte('date', '${today}T23:59:59');
        
    double totalExpenses = 0;
    for (final row in (expensesData as List)) {
      totalExpenses += (row['amount'] as num?)?.toDouble() ?? 0;
    }

    return sales - totalCost - totalExpenses;
  }

  /// Get sales totals for a date range
  Future<double> getSalesTotalByDateRange(DateTime start, DateTime end) async {
    final data = await _db
        .from('sales')
        .select('final_amount')
        .eq('shop_id', (await _getShopId())!)
        .gte('date', start.toIso8601String())
        .lte('date', '${AppFormatters.dateISO(end)}T23:59:59');
    double total = 0;
    for (final row in (data as List)) {
      total += (row['final_amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Get cost of goods sold for a date range
  Future<double> getCostByDateRange(DateTime start, DateTime end) async {
    final salesData = await _db
        .from('sales')
        .select('id')
        .eq('shop_id', (await _getShopId())!)
        .gte('date', start.toIso8601String())
        .lte('date', '${AppFormatters.dateISO(end)}T23:59:59');
    
    double totalCost = 0;
    for (final sale in (salesData as List)) {
      final saleId = sale['id'] as String;
      final items = await _db.from('sale_items').select('quantity, product_id').eq('sale_id', saleId);
      for (final item in (items as List)) {
        final productId = item['product_id'] as String?;
        final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
        if (productId != null) {
          final product = await _db.from('products').select('cost_price').eq('id', productId).maybeSingle();
          if (product != null) {
            totalCost += qty * ((product['cost_price'] as num?)?.toDouble() ?? 0);
          }
        }
      }
    }
    return totalCost;
  }

  /// Get expenses total for a date range
  Future<double> getExpenseTotalByDateRange(DateTime start, DateTime end) async {
    final data = await _db
        .from('expenses')
        .select('amount')
        .eq('shop_id', (await _getShopId())!)
        .gte('date', start.toIso8601String())
        .lte('date', '${AppFormatters.dateISO(end)}T23:59:59');
    double total = 0;
    for (final row in (data as List)) {
      total += (row['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  /// Get expenses grouped by category for a date range
  Future<List<Map<String, dynamic>>> getExpensesByCategory(DateTime start, DateTime end) async {
    final data = await _db
        .from('expenses')
        .select()
        .eq('shop_id', (await _getShopId())!)
        .gte('date', start.toIso8601String())
        .lte('date', '${AppFormatters.dateISO(end)}T23:59:59');
    
    final Map<String, double> categoryTotals = {};
    for (final row in (data as List)) {
      final cat = (row['category'] as String?) ?? 'دیگر';
      final amt = (row['amount'] as num?)?.toDouble() ?? 0;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
    }
    return categoryTotals.entries.map((e) => {'category': e.key, 'total': e.value}).toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
  }

  /// Get daily sales breakdown for chart
  Future<List<Map<String, dynamic>>> getDailySalesBreakdown(DateTime start, DateTime end) async {
    final salesData = await _db
        .from('sales')
        .select('date, final_amount')
        .eq('shop_id', (await _getShopId())!)
        .gte('date', start.toIso8601String())
        .lte('date', '${AppFormatters.dateISO(end)}T23:59:59')
        .order('date', ascending: true);

    final expensesData = await _db
        .from('expenses')
        .select('date, amount')
        .eq('shop_id', (await _getShopId())!)
        .gte('date', start.toIso8601String())
        .lte('date', '${AppFormatters.dateISO(end)}T23:59:59');

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

    // Build list for all days in range
    final List<Map<String, dynamic>> result = [];
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDay)) {
      final dayStr = AppFormatters.dateISO(current);
      result.add({
        'day': dayStr,
        'total_sales': salesByDay[dayStr] ?? 0.0,
        'total_expenses': expensesByDay[dayStr] ?? 0.0,
      });
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getWeeklySalesProfit() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return getDailySalesBreakdown(sevenDaysAgo, DateTime.now());
  }

  /// Get count of sales for a date range
  Future<int> getSalesCountByDateRange(DateTime start, DateTime end) async {
    final data = await _db
        .from('sales')
        .select('id')
        .eq('shop_id', (await _getShopId())!)
        .gte('date', start.toIso8601String())
        .lte('date', '${AppFormatters.dateISO(end)}T23:59:59');
    return (data as List).length;
  }

  /// Get top selling products for a date range
  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime start, DateTime end, {int limit = 5}) async {
    final salesData = await _db
        .from('sales')
        .select('id')
        .eq('shop_id', (await _getShopId())!)
        .gte('date', start.toIso8601String())
        .lte('date', '${AppFormatters.dateISO(end)}T23:59:59');
    
    final Map<String, double> productSales = {};
    final Map<String, double> productQty = {};
    for (final sale in (salesData as List)) {
      final saleId = sale['id'] as String;
      final items = await _db.from('sale_items').select('product_id, quantity, subtotal').eq('sale_id', saleId);
      for (final item in (items as List)) {
        final pid = item['product_id'] as String;
        productSales[pid] = (productSales[pid] ?? 0) + ((item['subtotal'] as num?)?.toDouble() ?? 0);
        productQty[pid] = (productQty[pid] ?? 0) + ((item['quantity'] as num?)?.toDouble() ?? 0);
      }
    }
    
    final sorted = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sorted.take(limit);
    
    final List<Map<String, dynamic>> result = [];
    for (final entry in topEntries) {
      final product = await _db.from('products').select('name').eq('id', entry.key).maybeSingle();
      result.add({
        'product_id': entry.key,
        'name': product?['name'] ?? 'Unknown',
        'total_sold': productQty[entry.key] ?? 0,
        'total_revenue': entry.value,
      });
    }
    return result;
  }

  /// Get stock valuation summary
  Future<Map<String, dynamic>> getStockValuation() async {
    final data = await _db.from('products').select('stock, cost_price, sale_price').eq('shop_id', (await _getShopId())!);
    int totalItems = 0;
    double costValue = 0;
    double saleValue = 0;
    for (final row in (data as List)) {
      final stock = (row['stock'] as num?)?.toDouble() ?? 0;
      final cost = (row['cost_price'] as num?)?.toDouble() ?? 0;
      final sale = (row['sale_price'] as num?)?.toDouble() ?? 0;
      totalItems += stock.toInt();
      costValue += stock * cost;
      saleValue += stock * sale;
    }
    return {
      'total_products': (data as List).length,
      'total_units': totalItems,
      'cost_value': costValue,
      'sale_value': saleValue,
      'potential_profit': saleValue - costValue,
    };
  }

  Future<double> getCashInHand() async {
    // 1. Sum up all CASH payments received from sales
    final salesData = await _db
        .from('sales')
        .select('amount_paid')
        .eq('shop_id', (await _getShopId())!)
        .eq('payment_type', 'CASH');
        
    double totalCashIn = 0;
    for (final row in (salesData as List)) {
      totalCashIn += (row['amount_paid'] as num?)?.toDouble() ?? 0;
    }

    // 2. Sum up all expenses
    final expensesData = await _db
        .from('expenses')
        .select('amount')
        .eq('shop_id', (await _getShopId())!);
        
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
        .eq('shop_id', (await _getShopId())!)
        .order('date', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> insertExpenseRaw(Map<String, dynamic> expense) async {
    expense['shop_id'] = (await _getShopId());
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
    final shopId = (await _getShopId())!;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    
    final payload = {
      'id': map['id'],
      'shop_id': shopId,
      'title': map['title'],
      'amount': map['amount'] ?? 0,
      'category': map['category'] ?? 'General',
      'date': map['date'],
    };

    final localDb = await LocalDbService.instance.database;
    await localDb.insert('local_expenses', {
      'id': map['id'],
      'local_id': 'EXP-$nowMs',
      'shop_id': shopId,
      'title': payload['title'],
      'amount': payload['amount'],
      'category': payload['category'],
      'expense_date': payload['date'],
      'created_at': nowMs,
    });

    await SyncQueue.instance.add(
      operation: 'insert',
      tableName: 'expenses',
      recordId: map['id'],
      payload: payload,
    );
  }

  Future<void> deleteExpense(String id) async {
    await _db.from('expenses').delete().eq('id', id);
  }

  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final dateStr = AppFormatters.dateISO(date);
    final data = await _db
        .from('expenses')
        .select()
        .eq('shop_id', (await _getShopId())!)
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
        .eq('shop_id', (await _getShopId())!)
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
        .eq('shop_id', (await _getShopId())!)
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
      'products': await _db.from('products').select().eq('shop_id', (await _getShopId())!),
      'customers': await _db.from('customers').select().eq('shop_id', (await _getShopId())!),
      'sales': await _db.from('sales').select().eq('shop_id', (await _getShopId())!),
      'expenses': await _db.from('expenses').select().eq('shop_id', (await _getShopId())!),
      'installments': await _db.from('installments').select().eq('shop_id', (await _getShopId())!),
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
      'shop_id': (await _getShopId()),
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
