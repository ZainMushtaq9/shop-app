import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';

/// SQLite database service with all table schemas and CRUD operations.
/// Handles local storage for offline-first architecture.
class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Get or initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize SQLite database with all tables
  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// Create all tables matching Section 10 schema
  Future<void> _createTables(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableProducts} (
        id TEXT PRIMARY KEY,
        name_urdu TEXT NOT NULL,
        name_english TEXT DEFAULT '',
        category TEXT DEFAULT 'عام',
        purchase_price REAL NOT NULL DEFAULT 0,
        sale_price REAL NOT NULL DEFAULT 0,
        stock_quantity INTEGER DEFAULT 0,
        min_stock_alert INTEGER DEFAULT 5,
        barcode TEXT,
        photo_path TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sheets_row_id INTEGER
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCustomers} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT DEFAULT '',
        address TEXT,
        photo_path TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Customer transactions table (Bahi Khata)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCustomerTransactions} (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        debit_amount REAL DEFAULT 0,
        credit_amount REAL DEFAULT 0,
        running_balance REAL DEFAULT 0,
        sale_id TEXT,
        payment_method TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES ${AppConstants.tableCustomers}(id)
      )
    ''');

    // Suppliers table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSuppliers} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT DEFAULT '',
        address TEXT,
        company_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Supplier transactions table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSupplierTransactions} (
        id TEXT PRIMARY KEY,
        supplier_id TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        debit_amount REAL DEFAULT 0,
        credit_amount REAL DEFAULT 0,
        running_balance REAL DEFAULT 0,
        items_json TEXT,
        payment_method TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES ${AppConstants.tableSuppliers}(id)
      )
    ''');

    // Sales table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSales} (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        customer_id TEXT,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        profit REAL DEFAULT 0,
        payment_type TEXT NOT NULL DEFAULT 'CASH',
        amount_paid REAL DEFAULT 0,
        balance_due REAL DEFAULT 0,
        bill_pdf_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES ${AppConstants.tableCustomers}(id)
      )
    ''');

    // Sale items table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSaleItems} (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL DEFAULT '',
        quantity INTEGER NOT NULL DEFAULT 0,
        purchase_price REAL DEFAULT 0,
        sale_price REAL DEFAULT 0,
        profit REAL DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES ${AppConstants.tableSales}(id),
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.tableProducts}(id)
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableExpenses} (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'دیگر',
        description TEXT NOT NULL DEFAULT '',
        amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSyncQueue} (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT DEFAULT 'PENDING'
      )
    ''');

    // Create indexes for performance
    await db.execute(
        'CREATE INDEX idx_customer_tx_customer ON ${AppConstants.tableCustomerTransactions}(customer_id)');
    await db.execute(
        'CREATE INDEX idx_customer_tx_date ON ${AppConstants.tableCustomerTransactions}(date)');
    await db.execute(
        'CREATE INDEX idx_supplier_tx_supplier ON ${AppConstants.tableSupplierTransactions}(supplier_id)');
    await db.execute(
        'CREATE INDEX idx_supplier_tx_date ON ${AppConstants.tableSupplierTransactions}(date)');
    await db.execute(
        'CREATE INDEX idx_sales_date ON ${AppConstants.tableSales}(date)');
    await db.execute(
        'CREATE INDEX idx_sale_items_sale ON ${AppConstants.tableSaleItems}(sale_id)');
    await db.execute(
        'CREATE INDEX idx_products_active ON ${AppConstants.tableProducts}(is_active)');
    await db.execute(
        'CREATE INDEX idx_expenses_date ON ${AppConstants.tableExpenses}(date)');
    await db.execute(
        'CREATE INDEX idx_sync_status ON ${AppConstants.tableSyncQueue}(status)');
  }

  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // ═══════════════════════════════════════════════════════════
  //  PRODUCTS CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(AppConstants.tableProducts, product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      AppConstants.tableProducts,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    // Soft delete — set is_active to 0
    await db.update(
      AppConstants.tableProducts,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getActiveProducts() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'is_active = 1',
      orderBy: 'name_urdu ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'is_active = 1 AND (name_urdu LIKE ? OR name_english LIKE ? OR barcode LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'is_active = 1 AND category = ?',
      whereArgs: [category],
      orderBy: 'name_urdu ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'is_active = 1 AND stock_quantity <= min_stock_alert',
      orderBy: 'stock_quantity ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<void> updateStock(String productId, int quantityChange) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE ${AppConstants.tableProducts}
      SET stock_quantity = stock_quantity + ?,
          updated_at = ?
      WHERE id = ?
    ''', [quantityChange, DateTime.now().toIso8601String(), productId]);
  }

  // ═══════════════════════════════════════════════════════════
  //  CUSTOMERS CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert(AppConstants.tableCustomers, customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      AppConstants.tableCustomers,
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete(AppConstants.tableCustomers, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableCustomers, orderBy: 'name ASC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableCustomers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  // ═══════════════════════════════════════════════════════════
  //  CUSTOMER TRANSACTIONS (Buyer Ledger)
  // ═══════════════════════════════════════════════════════════

  Future<void> insertCustomerTransaction(CustomerTransaction tx) async {
    final db = await database;
    await db.insert(AppConstants.tableCustomerTransactions, tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CustomerTransaction>> getCustomerTransactions(String customerId) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableCustomerTransactions,
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => CustomerTransaction.fromMap(m)).toList();
  }

  Future<List<CustomerTransaction>> getCustomerTransactionsByDateRange(
      String customerId, DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableCustomerTransactions,
      where: 'customer_id = ? AND date >= ? AND date <= ?',
      whereArgs: [customerId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC, created_at ASC',
    );
    return maps.map((m) => CustomerTransaction.fromMap(m)).toList();
  }

  /// Get the current balance for a customer (sum of debits - sum of credits)
  Future<double> getCustomerBalance(String customerId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(debit_amount), 0) - COALESCE(SUM(credit_amount), 0) as balance
      FROM ${AppConstants.tableCustomerTransactions}
      WHERE customer_id = ?
    ''', [customerId]);
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total receivable from all customers
  Future<double> getTotalReceivable() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(debit_amount), 0) - COALESCE(SUM(credit_amount), 0) as total
      FROM ${AppConstants.tableCustomerTransactions}
    ''');
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    return total > 0 ? total : 0.0;
  }

  /// Get customers with outstanding balance, sorted by highest first
  Future<List<Map<String, dynamic>>> getCustomersWithBalance() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*,
        COALESCE(SUM(ct.debit_amount), 0) - COALESCE(SUM(ct.credit_amount), 0) as balance,
        MAX(ct.date) as last_transaction_date
      FROM ${AppConstants.tableCustomers} c
      LEFT JOIN ${AppConstants.tableCustomerTransactions} ct ON c.id = ct.customer_id
      GROUP BY c.id
      ORDER BY balance DESC
    ''');
  }

  // ═══════════════════════════════════════════════════════════
  //  SUPPLIERS CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertSupplier(Supplier supplier) async {
    final db = await database;
    await db.insert(AppConstants.tableSuppliers, supplier.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final db = await database;
    await db.update(
      AppConstants.tableSuppliers,
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<void> deleteSupplier(String id) async {
    final db = await database;
    await db.delete(AppConstants.tableSuppliers, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableSuppliers, orderBy: 'name ASC');
    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<Supplier?> getSupplierById(String id) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableSuppliers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Supplier.fromMap(maps.first);
  }

  // ═══════════════════════════════════════════════════════════
  //  SUPPLIER TRANSACTIONS (Supplier Ledger)
  // ═══════════════════════════════════════════════════════════

  Future<void> insertSupplierTransaction(SupplierTransaction tx) async {
    final db = await database;
    await db.insert(AppConstants.tableSupplierTransactions, tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SupplierTransaction>> getSupplierTransactions(String supplierId) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableSupplierTransactions,
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => SupplierTransaction.fromMap(m)).toList();
  }

  /// Get the current balance owed to a supplier
  Future<double> getSupplierBalance(String supplierId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(debit_amount), 0) - COALESCE(SUM(credit_amount), 0) as balance
      FROM ${AppConstants.tableSupplierTransactions}
      WHERE supplier_id = ?
    ''', [supplierId]);
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total payable to all suppliers
  Future<double> getTotalPayable() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(debit_amount), 0) - COALESCE(SUM(credit_amount), 0) as total
      FROM ${AppConstants.tableSupplierTransactions}
    ''');
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    return total > 0 ? total : 0.0;
  }

  /// Get suppliers with outstanding balance, sorted by highest first
  Future<List<Map<String, dynamic>>> getSuppliersWithBalance() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.*,
        COALESCE(SUM(st.debit_amount), 0) - COALESCE(SUM(st.credit_amount), 0) as balance,
        MAX(st.date) as last_transaction_date
      FROM ${AppConstants.tableSuppliers} s
      LEFT JOIN ${AppConstants.tableSupplierTransactions} st ON s.id = st.supplier_id
      GROUP BY s.id
      ORDER BY balance DESC
    ''');
  }

  // ═══════════════════════════════════════════════════════════
  //  SALES CRUD
  // ═══════════════════════════════════════════════════════════

  /// Insert a complete sale (header + items) in a single transaction
  Future<void> insertSale(Sale sale, List<SaleItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert sale header
      await txn.insert(AppConstants.tableSales, sale.toMap());

      // Insert all sale items
      for (final item in items) {
        await txn.insert(AppConstants.tableSaleItems, item.toMap());

        // Decrease stock for each product
        await txn.rawUpdate('''
          UPDATE ${AppConstants.tableProducts}
          SET stock_quantity = stock_quantity - ?,
              updated_at = ?
          WHERE id = ?
        ''', [item.quantity, DateTime.now().toIso8601String(), item.productId]);
      }

      // If credit sale or partial, create a customer transaction
      if (sale.customerId != null && sale.balanceDue > 0) {
        final balance = await _getCustomerBalanceInTxn(txn, sale.customerId!);

        final customerTx = CustomerTransaction(
          customerId: sale.customerId!,
          date: sale.date,
          type: sale.paymentType == 'CREDIT'
              ? AppConstants.txCreditSale
              : AppConstants.txPartialPayment,
          description: sale.paymentType == 'CREDIT' ? 'ادھار فروخت' : 'جزوی ادائیگی',
          debitAmount: sale.total,
          creditAmount: sale.amountPaid,
          runningBalance: balance + sale.total - sale.amountPaid,
          saleId: sale.id,
          paymentMethod: sale.paymentType,
        );
        await txn.insert(AppConstants.tableCustomerTransactions, customerTx.toMap());
      }
    });
  }

  Future<double> _getCustomerBalanceInTxn(Transaction txn, String customerId) async {
    final result = await txn.rawQuery('''
      SELECT COALESCE(SUM(debit_amount), 0) - COALESCE(SUM(credit_amount), 0) as balance
      FROM ${AppConstants.tableCustomerTransactions}
      WHERE customer_id = ?
    ''', [customerId]);
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Sale>> getSalesByDate(DateTime date) async {
    final db = await database;
    final dateStr = AppFormatters.dateISO(date);
    final maps = await db.query(
      AppConstants.tableSales,
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableSales,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableSaleItems,
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((m) => SaleItem.fromMap(m)).toList();
  }

  /// Get today's total sales amount
  Future<double> getTodaySales() async {
    final db = await database;
    final today = AppFormatters.dateISO(DateTime.now());
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total_sales
      FROM ${AppConstants.tableSales}
      WHERE date LIKE ?
    ''', ['$today%']);
    return (result.first['total_sales'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get today's total profit
  Future<double> getTodayProfit() async {
    final db = await database;
    final today = AppFormatters.dateISO(DateTime.now());
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(profit), 0) as total_profit
      FROM ${AppConstants.tableSales}
      WHERE date LIKE ?
    ''', ['$today%']);
    return (result.first['total_profit'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get last 7 days sales and profit for dashboard chart
  Future<List<Map<String, dynamic>>> getWeeklySalesProfit() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        substr(date, 1, 10) as day,
        COALESCE(SUM(total), 0) as total_sales,
        COALESCE(SUM(profit), 0) as total_profit
      FROM ${AppConstants.tableSales}
      WHERE date >= date('now', '-7 days')
      GROUP BY substr(date, 1, 10)
      ORDER BY day ASC
    ''');
  }

  // ═══════════════════════════════════════════════════════════
  //  EXPENSES CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert(AppConstants.tableExpenses, expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete(AppConstants.tableExpenses, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final db = await database;
    final dateStr = AppFormatters.dateISO(date);
    final maps = await db.query(
      AppConstants.tableExpenses,
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<double> getTodayExpenses() async {
    final db = await database;
    final today = AppFormatters.dateISO(DateTime.now());
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM ${AppConstants.tableExpenses}
      WHERE date LIKE ?
    ''', ['$today%']);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getMonthlyExpenses(int year, int month) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM ${AppConstants.tableExpenses}
      WHERE date LIKE ?
    ''', ['$year-$monthStr%']);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ═══════════════════════════════════════════════════════════
  //  SYNC QUEUE
  // ═══════════════════════════════════════════════════════════

  Future<void> addToSyncQueue(SyncQueueEntry entry) async {
    final db = await database;
    await db.insert(AppConstants.tableSyncQueue, entry.toMap());
  }

  Future<List<SyncQueueEntry>> getPendingSyncEntries() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableSyncQueue,
      where: 'status = ?',
      whereArgs: [AppConstants.syncPending],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SyncQueueEntry.fromMap(m)).toList();
  }

  Future<void> markSynced(String id) async {
    final db = await database;
    await db.update(
      AppConstants.tableSyncQueue,
      {'status': AppConstants.syncSynced},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${AppConstants.tableSyncQueue}
      WHERE status = ?
    ''', [AppConstants.syncPending]);
    return (result.first['count'] as int?) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════
  //  BACKUP / EXPORT
  // ═══════════════════════════════════════════════════════════

  /// Export all data as a Map for JSON backup
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    return {
      'products': await db.query(AppConstants.tableProducts),
      'customers': await db.query(AppConstants.tableCustomers),
      'customer_transactions': await db.query(AppConstants.tableCustomerTransactions),
      'suppliers': await db.query(AppConstants.tableSuppliers),
      'supplier_transactions': await db.query(AppConstants.tableSupplierTransactions),
      'sales': await db.query(AppConstants.tableSales),
      'sale_items': await db.query(AppConstants.tableSaleItems),
      'expenses': await db.query(AppConstants.tableExpenses),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Import data from a backup map — replaces all existing data
  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear all tables
      for (final table in [
        AppConstants.tableSaleItems,
        AppConstants.tableSales,
        AppConstants.tableCustomerTransactions,
        AppConstants.tableSupplierTransactions,
        AppConstants.tableExpenses,
        AppConstants.tableProducts,
        AppConstants.tableCustomers,
        AppConstants.tableSuppliers,
        AppConstants.tableSyncQueue,
      ]) {
        await txn.delete(table);
      }

      // Insert all data
      final tables = {
        'products': AppConstants.tableProducts,
        'customers': AppConstants.tableCustomers,
        'customer_transactions': AppConstants.tableCustomerTransactions,
        'suppliers': AppConstants.tableSuppliers,
        'supplier_transactions': AppConstants.tableSupplierTransactions,
        'sales': AppConstants.tableSales,
        'sale_items': AppConstants.tableSaleItems,
        'expenses': AppConstants.tableExpenses,
      };

      for (final entry in tables.entries) {
        final rows = data[entry.key] as List<dynamic>?;
        if (rows != null) {
          for (final row in rows) {
            await txn.insert(entry.value, Map<String, dynamic>.from(row as Map));
          }
        }
      }
    });
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
