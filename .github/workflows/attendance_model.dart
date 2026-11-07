import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String meetingId;
  final String groupId;
  final String userId;
  final String memberName;
  final bool isPresent;
  final String markedBy;
  final DateTime markedAt;

  AttendanceModel({
    required this.id,
    required this.meetingId,
    required this.groupId,
    required this.userId,
    required this.memberName,
    required this.isPresent,
    required this.markedBy,
    DateTime? markedAt,
  }) : markedAt = markedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meetingId': meetingId,
      'groupId': groupId,
      'userId': userId,
      'memberName': memberName,
      'isPresent': isPresent,
      'markedBy': markedBy,
      'markedAt': Timestamp.fromDate(markedAt),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
    return AttendanceModel(
      id: docId,
      meetingId: map['meetingId'] ?? '',
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      memberName: map['memberName'] ?? '',
      isPresent: map['isPresent'] ?? true,
      markedBy: map['markedBy'] ?? '',
      markedAt: map['markedAt'] is Timestamp
          ? (map['markedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttendanceModel.fromMap(data, doc.id);
  }
}
