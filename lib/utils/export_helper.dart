import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/local_db_service.dart';

class ExportHelper {
  static Future<void> exportLocalDataAsJson() async {
    try {
      final db = await LocalDbService.instance.database;
      final Map<String, dynamic> exportData = {};
      
      final tables = ['local_products', 'local_customers', 'local_sales', 'local_sale_items', 'local_expenses'];
      
      for (final table in tables) {
        exportData[table] = await db.query(table);
      }
      
      final jsonStr = jsonEncode(exportData);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('\${directory.path}/shop_backup_\${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Super Business Shop Backup');
    } catch (e) {
      print('Export error: \$e');
      rethrow;
    }
  }
}
