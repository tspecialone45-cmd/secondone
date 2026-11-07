import 'package:cloud_firestore/cloud_firestore.dart';

class RepaymentModel {
  final String id;
  final String loanId;
  final String groupId;
  final String userId;
  final double principalPaid;
  final double interestPaid;
  final double totalPaid;
  final DateTime paidAt;
  final String recordedBy;
  final double remainingPrincipal;
  final String? notes;
  final DateTime createdAt;

  RepaymentModel({
    required this.id,
    required this.loanId,
    required this.groupId,
    required this.userId,
    required this.principalPaid,
    required this.interestPaid,
    double? totalPaid,
    DateTime? paidAt,
    required this.recordedBy,
    required this.remainingPrincipal,
    this.notes,
    DateTime? createdAt,
  })  : totalPaid = totalPaid ?? (principalPaid + interestPaid),
        paidAt = paidAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loanId': loanId,
      'groupId': groupId,
      'userId': userId,
      'principalPaid': principalPaid,
      'interestPaid': interestPaid,
      'totalPaid': totalPaid,
      'paidAt': Timestamp.fromDate(paidAt),
      'recordedBy': recordedBy,
      'remainingPrincipal': remainingPrincipal,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RepaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    return RepaymentModel(
      id: docId,
      loanId: map['loanId'] ?? '',
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      principalPaid: (map['principalPaid'] as num?)?.toDouble() ?? 0.0,
      interestPaid: (map['interestPaid'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0.0,
      paidAt: map['paidAt'] is Timestamp
          ? (map['paidAt'] as Timestamp).toDate()
          : DateTime.now(),
      recordedBy: map['recordedBy'] ?? '',
      remainingPrincipal: (map['remainingPrincipal'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory RepaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RepaymentModel.fromMap(data, doc.id);
  }
}
