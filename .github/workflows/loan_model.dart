import 'package:cloud_firestore/cloud_firestore.dart';

enum LoanStatus { pending, active, closed, overdue }

class LoanModel {
  final String id;
  final String groupId;
  final String userId;
  final String memberName;
  final double amount;
  final String purpose;
  final LoanStatus status;
  final double interestRate; // 1% per month default
  final DateTime? disbursedAt;
  final String? approvedBy;
  final int emiDay; // Day of month repayment is due
  final double totalRepaid;
  final double totalInterestPaid;
  final double outstandingPrincipal;
  final DateTime? nextDueDate;
  final DateTime createdAt;

  LoanModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.memberName,
    required this.amount,
    required this.purpose,
    this.status = LoanStatus.pending,
    this.interestRate = 1.0,
    this.disbursedAt,
    this.approvedBy,
    this.emiDay = 10,
    this.totalRepaid = 0.0,
    this.totalInterestPaid = 0.0,
    double? outstandingPrincipal,
    this.nextDueDate,
    DateTime? createdAt,
  })  : outstandingPrincipal = outstandingPrincipal ?? amount,
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'memberName': memberName,
      'amount': amount,
      'purpose': purpose,
      'status': status.name,
      'interestRate': interestRate,
      'disbursedAt': disbursedAt != null ? Timestamp.fromDate(disbursedAt!) : null,
      'approvedBy': approvedBy,
      'emiDay': emiDay,
      'totalRepaid': totalRepaid,
      'totalInterestPaid': totalInterestPaid,
      'outstandingPrincipal': outstandingPrincipal,
      'nextDueDate': nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map, String docId) {
    return LoanModel(
      id: docId,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      memberName: map['memberName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      purpose: map['purpose'] ?? '',
      status: LoanStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LoanStatus.pending,
      ),
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 1.0,
      disbursedAt: map['disbursedAt'] is Timestamp
          ? (map['disbursedAt'] as Timestamp).toDate()
          : null,
      approvedBy: map['approvedBy'],
      emiDay: map['emiDay'] ?? 10,
      totalRepaid: (map['totalRepaid'] as num?)?.toDouble() ?? 0.0,
      totalInterestPaid: (map['totalInterestPaid'] as num?)?.toDouble() ?? 0.0,
      outstandingPrincipal: (map['outstandingPrincipal'] as num?)?.toDouble() ?? 0.0,
      nextDueDate: map['nextDueDate'] is Timestamp
          ? (map['nextDueDate'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LoanModel.fromMap(data, doc.id);
  }

  LoanModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? memberName,
    double? amount,
    String? purpose,
    LoanStatus? status,
    double? interestRate,
    DateTime? disbursedAt,
    String? approvedBy,
    int? emiDay,
    double? totalRepaid,
    double? totalInterestPaid,
    double? outstandingPrincipal,
    DateTime? nextDueDate,
    DateTime? createdAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      memberName: memberName ?? this.memberName,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      interestRate: interestRate ?? this.interestRate,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      emiDay: emiDay ?? this.emiDay,
      totalRepaid: totalRepaid ?? this.totalRepaid,
      totalInterestPaid: totalInterestPaid ?? this.totalInterestPaid,
      outstandingPrincipal: outstandingPrincipal ?? this.outstandingPrincipal,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
