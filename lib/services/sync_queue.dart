import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_db_service.dart';
import 'connectivity_service.dart';

class SyncQueue {
  static final SyncQueue instance = SyncQueue._internal();
  SyncQueue._internal();

  final _supabase = Supabase.instance.client;

  Future<void> add({
    required String operation,  // 'insert','update','delete'
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await LocalDbService.instance.database;
    
    // Always write to local DB first
    await db.insert('sync_queue', {
      'operation': operation,
      'table_name': tableName,
      'record_id': recordId,
      'payload': jsonEncode(payload),
      'retry_count': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Try to sync immediately if online
    if (ConnectivityService.instance.isOnline) {
      await processQueue();
    }
  }

  Future<void> processQueue() async {
    final db = await LocalDbService.instance.database;
    
    final pending = await db.query(
      'sync_queue',
      where: 'synced_at IS NULL AND retry_count < 5',
      orderBy: 'created_at ASC',
      limit: 50,
    );

    for (final item in pending) {
      try {
        await _syncItem(item);
        // Mark as synced
        await db.update(
          'sync_queue',
          {'synced_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?', 
          whereArgs: [item['id']],
        );
      } catch (e) {
        // Increment retry count, save error
        await db.update(
          'sync_queue', 
          {
            'retry_count': (item['retry_count'] as int) + 1,
            'last_error': e.toString(),
          }, 
          where: 'id = ?', 
          whereArgs: [item['id']],
        );
      }
    }
  }

  Future<void> _syncItem(Map<String, dynamic> item) async {
    final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
    final table = item['table_name'] as String;
    final operation = item['operation'] as String;
    final recordId = item['record_id'] as String;
    
    switch (operation) {
      case 'insert':
        await _supabase.from(table).upsert(payload);
        break;
      case 'update':
        await _supabase.from(table).update(payload).eq('id', recordId);
        break;
      case 'delete':
        await _supabase.from(table).delete().eq('id', recordId);
        break;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final db = await LocalDbService.instance.database;
    return await db.query(
      'sync_queue',
      where: 'synced_at IS NULL',
      orderBy: 'created_at DESC',
    );
  }
}
