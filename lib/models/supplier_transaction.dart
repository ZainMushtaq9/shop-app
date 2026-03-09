import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Supplier transaction model for tracking purchases and payments.
/// Supports all 5 transaction types from Section 05 of requirements.
class SupplierTransaction {
  final String id;
  final String supplierId;
  final DateTime date;
  final String type; // CREDIT_PURCHASE, CASH_PURCHASE, PAYMENT_MADE, RETURN_TO_SUPPLIER, ADVANCE_PAID
  final String description;
  final double debitAmount;    // DR — goods received (shopkeeper owes more)
  final double creditAmount;   // CR — payment made (shopkeeper owes less)
  final double runningBalance; // Shopkeeper's outstanding balance to supplier
  final List<Map<String, dynamic>>? items; // Items in this purchase
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;

  SupplierTransaction({
    String? id,
    required this.supplierId,
    DateTime? date,
    required this.type,
    required this.description,
    this.debitAmount = 0.0,
    this.creditAmount = 0.0,
    this.runningBalance = 0.0,
    this.items,
    this.paymentMethod,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Net effect on balance (+ve increases what shopkeeper owes)
  double get netEffect => debitAmount - creditAmount;

  bool get isDebit => debitAmount > 0;
  bool get isCredit => creditAmount > 0;

  /// Urdu description for the transaction type
  String get typeUrdu {
    switch (type) {
      case 'CREDIT_PURCHASE':
        return 'ادھار خریداری';
      case 'CASH_PURCHASE':
        return 'نقد خریداری';
      case 'PAYMENT_MADE':
        return 'ادائیگی کی';
      case 'RETURN_TO_SUPPLIER':
        return 'مال واپسی';
      case 'ADVANCE_PAID':
        return 'پیشگی';
      default:
        return type;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'debit_amount': debitAmount,
      'credit_amount': creditAmount,
      'running_balance': runningBalance,
      'items_json': items != null ? jsonEncode(items) : null,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SupplierTransaction.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>>? parsedItems;
    if (map['items_json'] != null) {
      final decoded = jsonDecode(map['items_json'] as String);
      parsedItems = (decoded as List).cast<Map<String, dynamic>>();
    }

    return SupplierTransaction(
      id: map['id'] as String,
      supplierId: map['supplier_id'] as String,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      description: map['description'] as String? ?? '',
      debitAmount: (map['debit_amount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (map['credit_amount'] as num?)?.toDouble() ?? 0.0,
      runningBalance: (map['running_balance'] as num?)?.toDouble() ?? 0.0,
      items: parsedItems,
      paymentMethod: map['payment_method'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
