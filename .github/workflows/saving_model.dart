import 'package:cloud_firestore/cloud_firestore.dart';

class SavingModel {
  final String id;
  final String groupId;
  final String userId;
  final String memberName;
  final int month; // 1 - 12
  final int year;
  final double amount;
  final double lateFee;
  final double totalPaid;
  final DateTime paidAt;
  final String collectedBy;
  final DateTime createdAt;

  SavingModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.memberName,
    required this.month,
    required this.year,
    required this.amount,
    this.lateFee = 0.0,
    double? totalPaid,
    DateTime? paidAt,
    required this.collectedBy,
    DateTime? createdAt,
  })  : totalPaid = totalPaid ?? (amount + lateFee),
        paidAt = paidAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'memberName': memberName,
      'month': month,
      'year': year,
      'amount': amount,
      'lateFee': lateFee,
      'totalPaid': totalPaid,
      'paidAt': Timestamp.fromDate(paidAt),
      'collectedBy': collectedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SavingModel.fromMap(Map<String, dynamic> map, String docId) {
    return SavingModel(
      id: docId,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      memberName: map['memberName'] ?? '',
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
      amount: (map['amount'] as num?)?.toDouble() ?? 100.0,
      lateFee: (map['lateFee'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 100.0,
      paidAt: map['paidAt'] is Timestamp
          ? (map['paidAt'] as Timestamp).toDate()
          : DateTime.now(),
      collectedBy: map['collectedBy'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory SavingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SavingModel.fromMap(data, doc.id);
  }
}
