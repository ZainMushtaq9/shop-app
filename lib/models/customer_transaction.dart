import 'package:uuid/uuid.dart';

/// Customer transaction model for the Bahi Khata (بہی کھاتہ) digital ledger.
/// Supports all 6 transaction types from Section 04 of requirements.
class CustomerTransaction {
  final String id;
  final String customerId;
  final DateTime date;
  final String type; // CREDIT_SALE, CASH_SALE, PAYMENT_RECEIVED, RETURN, ADVANCE, PARTIAL_PAYMENT
  final String description;
  final double debitAmount;  // DR — amount added to what customer owes
  final double creditAmount; // CR — amount subtracted from what customer owes
  final double runningBalance;
  final String? saleId;      // FK to sales table (if linked to a bill)
  final String? paymentMethod; // CASH, BANK_TRANSFER, OTHER
  final String? notes;
  final DateTime createdAt;

  CustomerTransaction({
    String? id,
    required this.customerId,
    DateTime? date,
    required this.type,
    required this.description,
    this.debitAmount = 0.0,
    this.creditAmount = 0.0,
    this.runningBalance = 0.0,
    this.saleId,
    this.paymentMethod,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Net effect on balance (+ve increases what customer owes)
  double get netEffect => debitAmount - creditAmount;

  /// Whether this is a debit transaction (customer owes more)
  bool get isDebit => debitAmount > 0;

  /// Whether this is a credit transaction (customer owes less)
  bool get isCredit => creditAmount > 0;

  /// Urdu description for the transaction type
  String get typeUrdu {
    switch (type) {
      case 'CREDIT_SALE':
        return 'ادھار فروخت';
      case 'CASH_SALE':
        return 'نقد فروخت';
      case 'PAYMENT_RECEIVED':
        return 'ادائیگی موصول';
      case 'RETURN':
        return 'مال واپسی';
      case 'ADVANCE':
        return 'پیشگی ادائیگی';
      case 'PARTIAL_PAYMENT':
        return 'جزوی ادائیگی';
      default:
        return type;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'debit_amount': debitAmount,
      'credit_amount': creditAmount,
      'running_balance': runningBalance,
      'sale_id': saleId,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomerTransaction.fromMap(Map<String, dynamic> map) {
    return CustomerTransaction(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      description: map['description'] as String? ?? '',
      debitAmount: (map['debit_amount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (map['credit_amount'] as num?)?.toDouble() ?? 0.0,
      runningBalance: (map['running_balance'] as num?)?.toDouble() ?? 0.0,
      saleId: map['sale_id'] as String?,
      paymentMethod: map['payment_method'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
