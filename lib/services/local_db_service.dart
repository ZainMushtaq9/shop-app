import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shop_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_products (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        name_urdu TEXT,
        sale_price REAL NOT NULL,
        purchase_price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL,
        barcode TEXT,
        category TEXT DEFAULT 'عام',
        is_active INTEGER DEFAULT 1,
        synced_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE local_customers (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        balance REAL DEFAULT 0,
        synced_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE local_sales (
        id TEXT PRIMARY KEY,
        local_id TEXT UNIQUE NOT NULL,
        shop_id TEXT NOT NULL,
        customer_id TEXT,
        total_amount REAL NOT NULL,
        payment_type TEXT NOT NULL,
        bill_number TEXT NOT NULL,
        status TEXT DEFAULT 'completed',
        sync_status TEXT DEFAULT 'pending',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        purchase_price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_expenses (
        id TEXT PRIMARY KEY,
        local_id TEXT UNIQUE NOT NULL,
        shop_id TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        synced_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE local_whatsapp_queue (
        id TEXT PRIMARY KEY,
        phone TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> enqueueWhatsAppMessage(String id, String phone, String message) async {
    final db = await database;
    await db.insert('local_whatsapp_queue', {
      'id': id,
      'phone': phone,
      'message': message,
      'status': 'pending',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingWhatsAppMessages() async {
    final db = await database;
    return await db.query('local_whatsapp_queue', where: 'status = ?', whereArgs: ['pending']);
  }

  Future<void> markWhatsAppMessageSent(String id) async {
    final db = await database;
    await db.update('local_whatsapp_queue', {'status': 'sent'}, where: 'id = ?', whereArgs: [id]);
  }
}
