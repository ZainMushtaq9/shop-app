import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../services/local_db_service.dart';

class WhatsAppQueueScreen extends StatefulWidget {
  const WhatsAppQueueScreen({super.key});

  @override
  State<WhatsAppQueueScreen> createState() => _WhatsAppQueueScreenState();
}

class _WhatsAppQueueScreenState extends State<WhatsAppQueueScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final msgs = await LocalDbService.instance.getPendingWhatsAppMessages();
    setState(() {
      _messages = msgs;
      _isLoading = false;
    });
  }

  Future<void> _send(Map<String, dynamic> msg) async {
    final phone = msg['phone'];
    final text = msg['message'];
    final url = Uri.parse('https://wa.me/$phone?text=\${Uri.encodeComponent(text)}');
    
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await LocalDbService.instance.markWhatsAppMessageSent(msg['id']);
        _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isUrdu ? 'آف لائن واٹس ایپ قطار' : 'Offline WhatsApp Queue'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _messages.isEmpty 
          ? Center(child: Text(AppStrings.isUrdu ? 'قطار خالی ہے' : 'Queue is empty', style: AppTextStyles.urduBody))
          : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final date = DateTime.fromMillisecondsSinceEpoch(msg['created_at']);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.message, color: AppColors.primary),
                    title: Text(msg['phone'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(msg['message'], maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          '\${date.day}/\${date.month}/\${date.year}', 
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: () => _send(msg),
                      child: Text(AppStrings.isUrdu ? 'بھیجیں' : 'Send'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
