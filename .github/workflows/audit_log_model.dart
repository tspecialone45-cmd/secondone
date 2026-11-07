import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String groupId;
  final String action;
  final String performedBy;
  final String performedByName;
  final String targetId;
  final String targetType;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.groupId,
    required this.action,
    required this.performedBy,
    required this.performedByName,
    required this.targetId,
    required this.targetType,
    this.oldValue,
    this.newValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'action': action,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'targetId': targetId,
      'targetType': targetType,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return AuditLogModel(
      id: docId,
      groupId: map['groupId'] ?? '',
      action: map['action'] ?? '',
      performedBy: map['performedBy'] ?? '',
      performedByName: map['performedByName'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? '',
      oldValue: map['oldValue'] as Map<String, dynamic>?,
      newValue: map['newValue'] as Map<String, dynamic>?,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuditLogModel.fromMap(data, doc.id);
  }
}
