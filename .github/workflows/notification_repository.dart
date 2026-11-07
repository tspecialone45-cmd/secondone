import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/app_exception.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw AppException('सूचना पाठवताना त्रुटी: ${e.toString()}');
    }
  }

  Future<void> sendNotificationToGroup({
    required String groupId,
    required List<String> userIds,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    try {
      final batch = _firestore.batch();
      for (final uid in userIds) {
        final docRef = _firestore.collection('notifications').doc();
        final notif = NotificationModel(
          id: docRef.id,
          userId: uid,
          groupId: groupId,
          title: title,
          message: message,
          type: type,
        );
        batch.set(docRef, notif.toMap());
      }
      await batch.commit();
    } catch (e) {
      print('Group notification error: $e');
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }
}
