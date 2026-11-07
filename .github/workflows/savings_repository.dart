import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_keys.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/audit_logger.dart';
import '../models/saving_model.dart';

class SavingsRepository {
  final FirebaseFirestore _firestore;

  SavingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> recordSaving({
    required SavingModel saving,
    required String performedByName,
  }) async {
    try {
      final docRef = _firestore.collection(FirestoreCollections.savings).doc(saving.id);
      await docRef.set(saving.toMap());

      await AuditLogger.log(
        groupId: saving.groupId,
        action: 'RECORD_SAVING',
        performedBy: saving.collectedBy,
        performedByName: performedByName,
        targetId: saving.id,
        targetType: 'saving',
        newValue: saving.toMap(),
      );
    } catch (e) {
      throw AppException('बचत नोंदवताना त्रुटी आली: ${e.toString()}');
    }
  }

  /// Bulk record savings for monthly collection
  Future<void> recordBulkSavings({
    required String groupId,
    required List<SavingModel> savingsList,
    required String performedBy,
    required String performedByName,
  }) async {
    try {
      final batch = _firestore.batch();
      for (final saving in savingsList) {
        final docRef =
            _firestore.collection(FirestoreCollections.savings).doc(saving.id);
        batch.set(docRef, saving.toMap(), SetOptions(merge: true));
      }
      await batch.commit();

      await AuditLogger.log(
        groupId: groupId,
        action: 'BULK_RECORD_SAVINGS',
        performedBy: performedBy,
        performedByName: performedByName,
        targetId: groupId,
        targetType: 'savings_batch',
        newValue: {'count': savingsList.length},
      );
    } catch (e) {
      throw AppException('बचत संकलन जतन करताना त्रुटी आली: ${e.toString()}');
    }
  }

  Stream<List<SavingModel>> getSavingsForGroup(String groupId) {
    return _firestore
        .collection(FirestoreCollections.savings)
        .where('groupId', isEqualTo: groupId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SavingModel.fromFirestore(doc)).toList());
  }

  Stream<List<SavingModel>> getSavingsForMember(String groupId, String userId) {
    return _firestore
        .collection(FirestoreCollections.savings)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SavingModel.fromFirestore(doc)).toList());
  }

  Future<List<SavingModel>> getMonthlySavings(String groupId, int month, int year) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.savings)
          .where('groupId', isEqualTo: groupId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      return snapshot.docs.map((doc) => SavingModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw AppException('मासिक बचत आणताना त्रुटी आली: ${e.toString()}');
    }
  }
}
