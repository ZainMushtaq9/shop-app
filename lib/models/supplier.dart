import 'package:uuid/uuid.dart';

/// Supplier model matching the SUPPLIERS TABLE schema.
class Supplier {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? companyName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    String? id,
    required this.name,
    this.phone = '',
    this.address,
    this.companyName,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'company_name': companyName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String?,
      companyName: map['company_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Supplier copyWith({
    String? name,
    String? phone,
    String? address,
    String? companyName,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      companyName: companyName ?? this.companyName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
