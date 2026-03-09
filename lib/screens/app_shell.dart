import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'pos/pos_screen.dart';
import 'products/product_list_screen.dart';
import 'customers/customer_list_screen.dart';
import 'reports/reports_screen.dart';
import 'suppliers/supplier_list_screen.dart';
import 'money_flow/money_flow_screen.dart';
import 'expenses/expense_list_screen.dart';
import 'settings/settings_screen.dart';

/// Main app shell with bottom navigation (5 tabs) and drawer menu.
/// Follows the GUI Design Guide from Section 09 of requirements.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    // Main content screens for bottom nav tabs
    final screens = [
      const DashboardScreen(),
      const PosScreen(),
      const ProductListScreen(),
      const CustomerListScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(context, ref, currentTab),
      drawer: _buildDrawer(context, ref),
    );
  }

  /// Bottom Navigation Bar — 5 tabs with Urdu labels and icons
  Widget _buildBottomNav(BuildContext context, WidgetRef ref, int currentTab) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded, size: 28),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart_rounded, size: 28),
            label: AppStrings.sale,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_rounded, size: 28),
            label: AppStrings.stock,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_rounded, size: 28),
            label: AppStrings.customers,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_rounded, size: 28),
            label: AppStrings.reports,
          ),
        ],
      ),
    );
  }

  /// Drawer menu for secondary screens — Suppliers, Sheets, Money Flow, etc.
  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.store, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.appName,
                  style: AppTextStyles.urduTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'v2.0',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.local_shipping_rounded,
                  label: AppStrings.suppliers,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SupplierListScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: AppStrings.moneyFlow,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MoneyFlowScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_rounded,
                  label: AppStrings.expenses,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExpenseListScreen()),
                    );
                  },
                ),
                const Divider(),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: AppStrings.settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: AppStrings.help,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single drawer menu item with icon + Urdu/English label
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: AppDimens.iconLG, color: AppColors.primary),
      title: Text(
        label,
        style: AppTextStyles.urduBody,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      minLeadingWidth: 32,
      onTap: onTap,
    );
  }
}
