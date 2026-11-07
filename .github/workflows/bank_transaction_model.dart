import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { deposit, withdrawal, cashIn, cashOut }

class BankTransactionModel {
  final String id;
  final String groupId;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;
  final String recordedBy;
  final DateTime createdAt;

  BankTransactionModel({
    required this.id,
    required this.groupId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.recordedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BankTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return BankTransactionModel(
      id: docId,
      groupId: map['groupId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.deposit,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      recordedBy: map['recordedBy'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory BankTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BankTransactionModel.fromMap(data, doc.id);
  }
}
