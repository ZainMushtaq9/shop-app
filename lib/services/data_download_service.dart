import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_db_service.dart';

class DataDownloadService {
  static final DataDownloadService instance = DataDownloadService._internal();
  DataDownloadService._internal();
  
  final _supabase = Supabase.instance.client;

  Future<void> downloadEssentialData(String shopId) async {
    await Future.wait([
      _downloadProducts(shopId),
      _downloadCustomers(shopId),
    ]);
    
    // Save last download timestamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_download_$shopId', DateTime.now().toIso8601String());
  }

  Future<void> _downloadProducts(String shopId) async {
    try {
      final data = await _supabase
          .from('products')
          .select('id,name_en,name_ur,sale_price,cost_price,stock,barcode,category,is_active,last_updated')
          .eq('shop_id', shopId)
          .eq('is_active', true);
      
      final db = await LocalDbService.instance.database;
      final batch = db.batch();
      
      for (final p in data) {
        batch.insert('local_products', {
          'id': p['id'],
          'shop_id': shopId,
          'name': p['name_en'] ?? '',
          'name_urdu': p['name_ur'],
          'sale_price': p['sale_price'],
          'purchase_price': p['cost_price'],
          'stock_quantity': p['stock'],
          'barcode': p['barcode'],
          'category': p['category'] ?? 'عام',
          'is_active': p['is_active'] == true ? 1 : 0,
          'synced_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch(e) {
      print("Error downloading products: $e");
    }
  }

  Future<void> _downloadCustomers(String shopId) async {
    try {
      final data = await _supabase
          .from('customers')
          .select('id,name,phone,balance,last_updated')
          .eq('shop_id', shopId);
          
      final db = await LocalDbService.instance.database;
      final batch = db.batch();
      
      for (final c in data) {
        batch.insert('local_customers', {
          'id': c['id'],
          'shop_id': shopId,
          'name': c['name'] ?? '',
          'phone': c['phone'],
          'balance': c['balance'],
          'synced_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch(e) {
      print("Error downloading customers: $e");
    }
  }
}
