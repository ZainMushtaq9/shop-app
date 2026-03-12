import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/database_service.dart';

// ═══════════════════════════════════════════════════════════
//  DATABASE PROVIDER
// ═══════════════════════════════════════════════════════════

final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// ═══════════════════════════════════════════════════════════
//  PRODUCTS PROVIDERS
// ═══════════════════════════════════════════════════════════

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getActiveProducts();
});

final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getLowStockProducts();
});

final productSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  final db = ref.read(databaseProvider);
  if (query.isEmpty) return await db.getActiveProducts();
  return await db.searchProducts(query);
});

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) async {
  final db = ref.read(databaseProvider);
  return await db.getProductsByCategory(category);
});

// ═══════════════════════════════════════════════════════════
//  CUSTOMERS PROVIDERS
// ═══════════════════════════════════════════════════════════

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getAllCustomers();
});

final customersWithBalanceProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getCustomersWithBalance();
});

final customerBalanceProvider =
    FutureProvider.family<double, String>((ref, customerId) async {
  final db = ref.read(databaseProvider);
  return await db.getCustomerBalance(customerId);
});

final customerTransactionsProvider =
    FutureProvider.family<List<CustomerTransaction>, String>(
        (ref, customerId) async {
  final db = ref.read(databaseProvider);
  return await db.getCustomerTransactions(customerId);
});

// ═══════════════════════════════════════════════════════════
//  SUPPLIERS PROVIDERS
// ═══════════════════════════════════════════════════════════

final suppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getAllSuppliers();
});

final suppliersWithBalanceProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getSuppliersWithBalance();
});

final supplierBalanceProvider =
    FutureProvider.family<double, String>((ref, supplierId) async {
  final db = ref.read(databaseProvider);
  return await db.getSupplierBalance(supplierId);
});

final supplierTransactionsProvider =
    FutureProvider.family<List<SupplierTransaction>, String>(
        (ref, supplierId) async {
  final db = ref.read(databaseProvider);
  return await db.getSupplierTransactions(supplierId);
});

// ═══════════════════════════════════════════════════════════
//  DASHBOARD PROVIDERS
// ═══════════════════════════════════════════════════════════

final todaySalesProvider = FutureProvider<double>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getTodaySales();
});

final todayProfitProvider = FutureProvider<double>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getTodayProfit();
});

final totalReceivableProvider = FutureProvider<double>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getTotalReceivable();
});

final totalPayableProvider = FutureProvider<double>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getTotalPayable();
});

final weeklySalesProfitProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getWeeklySalesProfit();
});

final todayExpensesProvider = FutureProvider<double>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getTodayExpenses();
});

// ═══════════════════════════════════════════════════════════
//  SALES PROVIDERS
// ═══════════════════════════════════════════════════════════

final todaySalesListProvider = FutureProvider<List<Sale>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getSalesByDate(DateTime.now());
});

final saleItemsProvider =
    FutureProvider.family<List<SaleItem>, String>((ref, saleId) async {
  final db = ref.read(databaseProvider);
  return await db.getSaleItems(saleId);
});

// ═══════════════════════════════════════════════════════════
//  SYNC PROVIDERS
// ═══════════════════════════════════════════════════════════

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getPendingSyncCount();
});

// ═══════════════════════════════════════════════════════════
//  UI STATE PROVIDERS
// ═══════════════════════════════════════════════════════════

/// Current bottom navigation tab index
final currentTabProvider = StateProvider<int>((ref) => 0);

/// Language toggle
final isUrduProvider = StateProvider<bool>((ref) => true);

/// Selected product category filter
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Search query for products
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// Theme mode toggle (light / dark / system)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
