import 'package:uuid/uuid.dart';

/// Expense model matching the EXPENSES TABLE schema.
class Expense {
  final String id;
  final DateTime date;
  final String category;
  final String description;
  final double amount;
  final DateTime createdAt;

  Expense({
    String? id,
    DateTime? date,
    required this.category,
    required this.description,
    required this.amount,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String? ?? 'دیگر',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Sync queue entry for offline changes, matching SYNC QUEUE TABLE schema.
class SyncQueueEntry {
  final String id;
  final String action; // INSERT, UPDATE, DELETE
  final String tableName;
  final String recordId;
  final String dataJson;
  final DateTime createdAt;
  final String status; // PENDING, SYNCED, FAILED

  SyncQueueEntry({
    String? id,
    required this.action,
    required this.tableName,
    required this.recordId,
    required this.dataJson,
    DateTime? createdAt,
    this.status = 'PENDING',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'data_json': dataJson,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory SyncQueueEntry.fromMap(Map<String, dynamic> map) {
    return SyncQueueEntry(
      id: map['id'] as String,
      action: map['action'] as String,
      tableName: map['table_name'] as String,
      recordId: map['record_id'] as String,
      dataJson: map['data_json'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: map['status'] as String? ?? 'PENDING',
    );
  }
}
