import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'customer_auth_service.dart';
import '../../widgets/global_app_bar.dart';
import 'portal_login_screen.dart';
import 'portal_providers.dart';
import 'portal_shop_detail_screen.dart';
import 'portal_notifications_screen.dart';

class PortalDashboardScreen extends ConsumerWidget {
  const PortalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urdu = AppStrings.isUrdu;
    final shopsAsync = ref.watch(customerShopsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(urdu ? 'میرا کھاتہ' : 'My Hisaab', style: AppTextStyles.urduTitle),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notifsAsync = ref.watch(customerNotificationsProvider);
              final unreadCount = notifsAsync.valueOrNull?.where((n) => n['is_read'] != true).length ?? 0;
              
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount.toString()),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PortalNotificationsScreen()));
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: urdu ? 'لاگ آؤٹ' : 'Logout',
            onPressed: () {
              ref.read(customerAuthServiceProvider).logout();
            },
          )
        ],
      ),
      body: shopsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            urdu ? 'خرابی: $err' : 'Error: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (shops) {
          if (shops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_mall_directory_rounded, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    urdu ? 'کوئی دکان نہیں ملی' : 'No shops found',
                    style: AppTextStyles.urduTitle.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    urdu 
                        ? 'آپ کا اس نمبر پر کسی دکان سے کھاتہ نہیں ہے' 
                        : 'Your number is not linked to any shop\'s khata',
                    style: AppTextStyles.urduBody.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.refresh(customerShopsProvider),
                    child: Text(urdu ? 'دوبارہ لوڈ کریں' : 'Refresh'),
                  )
                ],
              ),
            );
          }

          double totalOwed = 0;
          for (final s in shops) {
            final bal = (s['balance'] as num?)?.toDouble() ?? 0.0;
            if (bal > 0) totalOwed += bal;
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(customerShopsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Summary Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        urdu ? 'کل بقایا جات' : 'Total Amount Owed',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppFormatters.currency(totalOwed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  urdu ? 'منسلک دکانیں' : 'Connected Shops',
                  style: AppTextStyles.urduTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                
                // Shops List
                ...shops.map((shop) {
                  final shopName = urdu ? (shop['shop_name_urdu'] ?? shop['shop_name']) : shop['shop_name'];
                  final balance = (shop['balance'] as num?)?.toDouble() ?? 0.0;
                  final logoUrl = shop['shop_logo'] as String?;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
                        child: logoUrl == null 
                            ? Text(shopName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      title: Text(shopName ?? 'Shop', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(shop['shop_phone'] ?? '', style: TextStyle(color: Colors.grey[600])),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.currency(balance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: balance > 0 ? AppColors.moneyOwed : AppColors.moneyReceived,
                            ),
                          ),
                          Text(
                            balance > 0 ? (urdu ? 'باقی ہیں' : 'Total Owed') : (urdu ? 'صاف کھاتہ' : 'Clear'),
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PortalShopDetailScreen(
                              shopId: shop['shop_id'],
                              shopData: shop,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
