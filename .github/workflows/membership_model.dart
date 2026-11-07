import 'package:cloud_firestore/cloud_firestore.dart';

enum MembershipStatus { pending, approved, rejected }

class MembershipModel {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String userPhone;
  final MembershipStatus status;
  final String role;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? respondedBy;

  MembershipModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.status = MembershipStatus.pending,
    this.role = 'member',
    DateTime? requestedAt,
    this.respondedAt,
    this.respondedBy,
  }) : requestedAt = requestedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'status': status.name,
      'role': role,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'respondedBy': respondedBy,
    };
  }

  factory MembershipModel.fromMap(Map<String, dynamic> map, String docId) {
    return MembershipModel(
      id: docId,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      status: MembershipStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MembershipStatus.pending,
      ),
      role: map['role'] ?? 'member',
      requestedAt: map['requestedAt'] is Timestamp
          ? (map['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: map['respondedAt'] is Timestamp
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
      respondedBy: map['respondedBy'],
    );
  }

  factory MembershipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MembershipModel.fromMap(data, doc.id);
  }

  MembershipModel copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? userName,
    String? userPhone,
    MembershipStatus? status,
    String? role,
    DateTime? requestedAt,
    DateTime? respondedAt,
    String? respondedBy,
  }) {
    return MembershipModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      status: status ?? this.status,
      role: role ?? this.role,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
    );
  }
}
