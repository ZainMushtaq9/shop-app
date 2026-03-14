import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_auth_service.dart';

final customerShopsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final authService = ref.read(customerAuthServiceProvider);
  final phone = authService.currentPhone;
  
  if (phone == null) return [];
  
  // Format phone to match view if needed
  final formattedPhone = phone.startsWith('+') ? phone : '+$phone';
  
  final data = await supabase
      .from('customer_shop_links')
      .select()
      .eq('phone', formattedPhone)
      .order('shop_name', ascending: true);
      
  return List<Map<String, dynamic>>.from(data);
});

final customerTransactionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, shopId) async {
  final supabase = Supabase.instance.client;
  
  // Realtime
  final channel = supabase.channel('portal_tx_$shopId');
  channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      callback: (payload) {
        ref.invalidateSelf();
      }).subscribe();
      
  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  final authService = ref.read(customerAuthServiceProvider);
  final phone = authService.currentPhone;
  
  if (phone == null) return [];
  
  final formattedPhone = phone.startsWith('+') ? phone : '+$phone';
  
  // Need to get the customer id for this shop
  final csl = await supabase.from('customer_shop_links')
    .select('shop_customer_id')
    .eq('phone', formattedPhone)
    .eq('shop_id', shopId)
    .maybeSingle();
    
  if (csl == null) return [];
  final customerId = csl['shop_customer_id'];

  // Fetch sales (that are not hidden)
  final salesR = await supabase.from('sales')
      .select('id, date, final_amount, total_amount, payment_type, bill_number, hidden_from_customer')
      .eq('customer_id', customerId)
      .eq('hidden_from_customer', false);

  // Fetch payments
  final paymentsR = await supabase.from('installments')
      .select('id, date, amount, type, description')
      .eq('customer_id', customerId);
      
  // Combine & sort
  final List<Map<String, dynamic>> combined = [];
  
  for (final s in (salesR as List)) {
    combined.add({
      'id': s['id'],
      'type': 'sale',
      'date': s['date'],
      'amount': s['final_amount'] ?? s['total_amount'],
      'payment_type': s['payment_type'],
      'bill_number': s['bill_number'],
    });
  }
  
  for (final p in (paymentsR as List)) {
    combined.add({
      'id': p['id'],
      'type': p['type'] == 'payment' ? 'payment' : 'charge',
      'date': p['date'],
      'amount': p['amount'],
      'description': p['description'],
    });
  }
  
  combined.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
  return combined;
});

final customerSaleItemsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, saleId) async {
  final supabase = Supabase.instance.client;
  
  // Realtime
  final channel = supabase.channel('portal_sale_$saleId');
  channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'sale_items',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'sale_id', value: saleId),
      callback: (payload) {
        ref.invalidateSelf();
      }).subscribe();
      
  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  final data = await supabase
      .from('sale_items')
      .select('product_name, quantity, unit_price, subtotal, product_id, products(name_ur, name_en)')
      .eq('sale_id', saleId);
      
  return List<Map<String, dynamic>>.from(data);
});

Future<void> markBillAsRead(String saleId) async {
  final supabase = Supabase.instance.client;
  if (supabase.auth.currentUser == null) return;
  
  // Uses ON CONFLICT logic in Supabase via UPSERT, or just inserts and ignores duplicates if we did it via try-catch
  try {
    await supabase.from('customer_bill_reads').insert({
      'customer_account_id': supabase.auth.currentUser!.id,
      'sale_id': saleId,
    });
  } catch (e) {
    // Already read, ignore constraint error
  }
}

final customerNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final authService = ref.read(customerAuthServiceProvider);
  final phone = authService.currentPhone;
  
  if (phone == null) return [];
  
  final formattedPhone = phone.startsWith('+') ? phone : '+$phone';
  final acc = await supabase.from('customer_accounts').select('id').eq('phone', formattedPhone).maybeSingle();
  if (acc == null) return [];
  final accId = acc['id'];

  // Realtime
  final channel = supabase.channel('portal_notifs_$accId');
  channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'customer_notifications',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'customer_account_id', value: accId),
      callback: (payload) {
        ref.invalidateSelf();
      }).subscribe();
      
  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  final data = await supabase
      .from('customer_notifications')
      .select('id, type, title, body, is_read, created_at, reference_id, shop_id')
      .eq('customer_account_id', accId)
      .order('created_at', ascending: false);
      
  return List<Map<String, dynamic>>.from(data);
});

Future<void> markNotificationAsRead(String notifId) async {
  final supabase = Supabase.instance.client;
  if (supabase.auth.currentUser == null) return;
  await supabase.from('customer_notifications').update({'is_read': true}).eq('id', notifId);
}
