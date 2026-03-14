import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'portal_providers.dart';

class PortalNotificationsScreen extends ConsumerWidget {
  const PortalNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(customerNotificationsProvider);
    final urdu = AppStrings.isUrdu;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(urdu ? 'نوٹیفیکیشنز' : 'Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 1,
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    urdu ? 'کوئی نوٹیفیکیشن نہیں' : 'No notifications',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isRead = n['is_read'] == true;
              final date = DateTime.parse(n['created_at']);
              
              return InkWell(
                onTap: () {
                  if (!isRead) {
                    markNotificationAsRead(n['id']);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          n['type'] == 'new_bill' ? Icons.receipt : Icons.payments,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['title'] ?? '',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n['body'] ?? '',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(date),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
