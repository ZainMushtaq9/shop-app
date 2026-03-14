import 'package:flutter/material.dart';
import '../../services/sync_queue.dart';
import '../../services/connectivity_service.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_app_bar.dart';
import 'package:intl/intl.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  List<Map<String, dynamic>> _pendingItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    final items = await SyncQueue.instance.getPendingItems();
    if (mounted) {
      setState(() {
        _pendingItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _forceSync() async {
    if (!ConnectivityService.instance.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.isUrdu ? 'انٹرنیٹ کنکشن درکار ہے' : 'Internet connection required')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    await SyncQueue.instance.processQueue();
    await _loadQueue();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.isUrdu ? 'ہم منگ سازی مکمل' : 'Sync completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: AppStrings.isUrdu ? 'ڈیٹا منتقلی کی کیفیت' : 'Sync Status',
        showDrawer: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: _pendingItems.isEmpty ? AppColors.moneyReceived.withOpacity(0.1) : AppColors.moneyOwed.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(
                        _pendingItems.isEmpty ? Icons.check_circle_rounded : Icons.sync_problem_rounded,
                        color: _pendingItems.isEmpty ? AppColors.moneyReceived : AppColors.moneyOwed,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pendingItems.isEmpty 
                                  ? (AppStrings.isUrdu ? 'سارا ڈیٹا محفوظ ہے' : 'All data is synced')
                                  : (AppStrings.isUrdu ? '${_pendingItems.length} آئٹمز منتقلی کے منتظر ہیں' : '${_pendingItems.length} items pending sync'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      if (_pendingItems.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _forceSync,
                          icon: const Icon(Icons.sync_rounded, size: 18),
                          label: Text(AppStrings.isUrdu ? 'منتقل کریں' : 'Sync Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _pendingItems.length,
                    itemBuilder: (context, index) {
                      final item = _pendingItems[index];
                      final op = item['operation'];
                      final table = item['table_name'];
                      final error = item['last_error'];
                      final time = DateTime.fromMillisecondsSinceEpoch(item['created_at']);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(
                            op == 'insert' ? Icons.add_rounded : (op == 'update' ? Icons.edit_rounded : Icons.delete_rounded),
                            color: AppColors.textMain,
                          ),
                        ),
                        title: Text('$op on $table', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('MMM dd, hh:mm a').format(time)),
                            if (error != null)
                              Text('Error: $error', style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                        trailing: item['retry_count'] > 0 
                            ? Text('Retries: ${item['retry_count']}', style: const TextStyle(color: Colors.orange))
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
