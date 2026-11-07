import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AuditLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Uuid _uuid = Uuid();

  /// Logs a financial or group lifecycle change to the append-only auditLogs collection
  static Future<void> log({
    required String groupId,
    required String action,
    required String performedBy,
    required String performedByName,
    required String targetId,
    required String targetType,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      final logId = _uuid.v4();
      await _firestore.collection('auditLogs').doc(logId).set({
        'id': logId,
        'groupId': groupId,
        'action': action,
        'performedBy': performedBy,
        'performedByName': performedByName,
        'targetId': targetId,
        'targetType': targetType,
        'oldValue': oldValue,
        'newValue': newValue,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // In offline mode or error, ensure audit failure doesn't silently block client UI
      print('AuditLog error: $e');
    }
  }
}
