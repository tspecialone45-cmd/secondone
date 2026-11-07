import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_keys.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/audit_logger.dart';
import '../models/attendance_model.dart';
import '../models/meeting_model.dart';

class MeetingRepository {
  final FirebaseFirestore _firestore;

  MeetingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createMeeting(MeetingModel meeting) async {
    try {
      final docRef = _firestore.collection(FirestoreCollections.meetings).doc(meeting.id);
      await docRef.set(meeting.toMap());
    } catch (e) {
      throw AppException('बैठक आयोजित करताना त्रुटी आली: ${e.toString()}');
    }
  }

  Future<void> updateMeetingMinutes({
    required String meetingId,
    required String minutes,
    required String performedBy,
    required String performedByName,
    required String groupId,
  }) async {
    try {
      final docRef = _firestore.collection(FirestoreCollections.meetings).doc(meetingId);
      await docRef.update({
        'minutes': minutes,
        'status': 'completed',
      });

      await AuditLogger.log(
        groupId: groupId,
        action: 'UPDATE_MINUTES',
        performedBy: performedBy,
        performedByName: performedByName,
        targetId: meetingId,
        targetType: 'meeting',
        newValue: {'minutes': minutes},
      );
    } catch (e) {
      throw AppException('इतिवृत्त जतन करताना त्रुटी आली: ${e.toString()}');
    }
  }

  Future<void> markAttendance({
    required String meetingId,
    required String groupId,
    required List<AttendanceModel> attendanceList,
    required String performedBy,
    required String performedByName,
  }) async {
    try {
      final batch = _firestore.batch();
      for (final att in attendanceList) {
        final docRef = _firestore
            .collection(FirestoreCollections.attendance)
            .doc('${meetingId}_${att.userId}');
        batch.set(docRef, att.toMap(), SetOptions(merge: true));
      }
      await batch.commit();

      await AuditLogger.log(
        groupId: groupId,
        action: 'MARK_ATTENDANCE',
        performedBy: performedBy,
        performedByName: performedByName,
        targetId: meetingId,
        targetType: 'attendance_batch',
        newValue: {'count': attendanceList.length},
      );
    } catch (e) {
      throw AppException('हजेरी जतन करताना त्रुटी आली: ${e.toString()}');
    }
  }

  Stream<List<MeetingModel>> getMeetings(String groupId) {
    return _firestore
        .collection(FirestoreCollections.meetings)
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MeetingModel.fromFirestore(doc)).toList());
  }

  Future<List<AttendanceModel>> getAttendanceForMeeting(String meetingId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.attendance)
          .where('meetingId', isEqualTo: meetingId)
          .get();

      return snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw AppException('हजेरी माहिती आणताना त्रुटी आली: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getMemberAttendanceStats(
      String groupId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.attendance)
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .get();

      final total = snapshot.docs.length;
      final attended = snapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .where((att) => att.isPresent)
          .length;

      final percentage = total > 0 ? (attended / total) * 100.0 : 100.0;
      return {
        'total': total,
        'attended': attended,
        'percentage': percentage,
      };
    } catch (e) {
      return {'total': 0, 'attended': 0, 'percentage': 0.0};
    }
  }
}
