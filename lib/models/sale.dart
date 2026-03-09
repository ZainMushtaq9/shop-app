import 'package:uuid/uuid.dart';

/// Sale header model matching the SALES TABLE schema.
class Sale {
  final String id;
  final DateTime date;
  final String? customerId;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double profit;
  final String paymentType; // CASH, CREDIT, PARTIAL
  final double amountPaid;
  final double balanceDue;
  final String? billPdfPath;
  final DateTime createdAt;

  Sale({
    String? id,
    DateTime? date,
    this.customerId,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.total,
    required this.profit,
    required this.paymentType,
    required this.amountPaid,
    this.balanceDue = 0.0,
    this.billPdfPath,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Is this sale fully paid?
  bool get isFullyPaid => balanceDue <= 0;

  /// Is this a credit sale?
  bool get isCredit => paymentType == 'CREDIT' || paymentType == 'PARTIAL';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'customer_id': customerId,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'profit': profit,
      'payment_type': paymentType,
      'amount_paid': amountPaid,
      'balance_due': balanceDue,
      'bill_pdf_path': billPdfPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      customerId: map['customer_id'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      paymentType: map['payment_type'] as String? ?? 'CASH',
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
      billPdfPath: map['bill_pdf_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Individual item in a sale, matching SALE ITEMS TABLE schema.
class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName; // Snapshot at time of sale
  final int quantity;
  final double purchasePrice; // Snapshot
  final double salePrice;    // Snapshot
  final double profit;

  SaleItem({
    String? id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    double? profit,
  })  : id = id ?? const Uuid().v4(),
        profit = profit ?? (salePrice - purchasePrice) * quantity;

  /// Total value of this line item
  double get totalValue => salePrice * quantity;

  /// Total cost of this line item
  double get totalCost => purchasePrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'profit': profit,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as String,
      saleId: map['sale_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
