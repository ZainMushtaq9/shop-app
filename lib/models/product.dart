import 'package:uuid/uuid.dart';

/// Product model matching the PRODUCTS TABLE schema from requirements.
class Product {
  final String id;
  final String nameUrdu;
  final String nameEnglish;
  final String category;
  final double purchasePrice;
  final double salePrice;
  int stockQuantity;
  final int minStockAlert;
  final String? barcode;
  final String? photoPath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? sheetsRowId;

  Product({
    String? id,
    required this.nameUrdu,
    this.nameEnglish = '',
    this.category = 'عام',
    required this.purchasePrice,
    required this.salePrice,
    this.stockQuantity = 0,
    this.minStockAlert = 5,
    this.barcode,
    this.photoPath,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sheetsRowId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Profit per unit
  double get unitProfit => salePrice - purchasePrice;

  /// Profit margin percentage
  double get profitMargin =>
      purchasePrice > 0 ? ((salePrice - purchasePrice) / purchasePrice) * 100 : 0;

  /// Whether stock is below alert threshold
  bool get isLowStock => stockQuantity <= minStockAlert;

  /// Display name (Urdu first, fallback to English)
  String get displayName => nameUrdu.isNotEmpty ? nameUrdu : nameEnglish;

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_urdu': nameUrdu,
      'name_english': nameEnglish,
      'category': category,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'stock_quantity': stockQuantity,
      'min_stock_alert': minStockAlert,
      'barcode': barcode,
      'photo_path': photoPath,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sheets_row_id': sheetsRowId,
    };
  }

  /// Create Product from SQLite Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      nameUrdu: map['name_urdu'] as String? ?? '',
      nameEnglish: map['name_english'] as String? ?? '',
      category: map['category'] as String? ?? 'عام',
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: map['stock_quantity'] as int? ?? 0,
      minStockAlert: map['min_stock_alert'] as int? ?? 5,
      barcode: map['barcode'] as String?,
      photoPath: map['photo_path'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      sheetsRowId: map['sheets_row_id'] as int?,
    );
  }

  /// Create a copy with updated fields
  Product copyWith({
    String? nameUrdu,
    String? nameEnglish,
    String? category,
    double? purchasePrice,
    double? salePrice,
    int? stockQuantity,
    int? minStockAlert,
    String? barcode,
    String? photoPath,
    bool? isActive,
    int? sheetsRowId,
  }) {
    return Product(
      id: id,
      nameUrdu: nameUrdu ?? this.nameUrdu,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      barcode: barcode ?? this.barcode,
      photoPath: photoPath ?? this.photoPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      sheetsRowId: sheetsRowId ?? this.sheetsRowId,
    );
  }
}
