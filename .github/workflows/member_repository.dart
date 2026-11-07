import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_keys.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/audit_logger.dart';
import '../models/group_model.dart';
import '../models/membership_model.dart';
import '../models/user_model.dart';

class MemberRepository {
  final FirebaseFirestore _firestore;

  MemberRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw AppException('वापरकर्ता प्रोफाइल तयार करताना त्रुटी: ${e.toString()}');
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw AppException('वापरकर्ता माहिती आणताना त्रुटी: ${e.toString()}');
    }
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      throw AppException('प्रोफाइल अपडेट करताना त्रुटी: ${e.toString()}');
    }
  }

  /// Sends a join request for a member to join a group
  Future<void> sendJoinRequest({
    required String groupId,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    try {
      // Check if user is already a member or has pending request
      final membershipId = '${groupId}_$userId';
      final doc = await _firestore
          .collection(FirestoreCollections.memberships)
          .doc(membershipId)
          .get();

      if (doc.exists) {
        final existing = MembershipModel.fromFirestore(doc);
        if (existing.status == MembershipStatus.approved) {
          throw AppException('आपण आधीच या गटाचे मंजूर सदस्य आहात.');
        } else if (existing.status == MembershipStatus.pending) {
          throw AppException('आपली विनंती आधीच प्रलंबित आहे. कृपया अध्यक्षांच्या मंजुरीची प्रतीक्षा करा.');
        }
      }

      final membership = MembershipModel(
        id: membershipId,
        groupId: groupId,
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        status: MembershipStatus.pending,
        role: 'member',
        requestedAt: DateTime.now(),
      );

      await _firestore
          .collection(FirestoreCollections.memberships)
          .doc(membershipId)
          .set(membership.toMap());
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('विनंती पाठवताना त्रुटी आली: ${e.toString()}');
    }
  }

  /// Stream of pending join requests for leader dashboard
  Stream<List<MembershipModel>> getPendingRequests(String groupId) {
    return _firestore
        .collection(FirestoreCollections.memberships)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: MembershipStatus.pending.name)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MembershipModel.fromFirestore(doc)).toList());
  }

  /// Stream of approved members for a group
  Stream<List<UserModel>> getApprovedMembers(String groupId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .where('groupId', isEqualTo: groupId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  /// Leader approves member request with strict 11-member check
  Future<void> approveMembership({
    required String membershipId,
    required String groupId,
    required String userId,
    required String respondedBy,
    required String respondedByName,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection(FirestoreCollections.groups).doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw AppException('गट सापडला नाही.');
        }

        final group = GroupModel.fromFirestore(groupDoc);
        final maxCapacity = group.settings.maxMembers; // default 11

        if (group.memberCount >= maxCapacity) {
          throw GroupFullException(
              'गटात आधीच जास्तीत जास्त $maxCapacity सदस्य आहेत. नवीन सदस्य जोडता येणार नाही.');
        }

        final membershipRef =
            _firestore.collection(FirestoreCollections.memberships).doc(membershipId);
        final userRef = _firestore.collection(FirestoreCollections.users).doc(userId);

        transaction.update(membershipRef, {
          'status': MembershipStatus.approved.name,
          'respondedAt': FieldValue.serverTimestamp(),
          'respondedBy': respondedBy,
        });

        transaction.update(userRef, {
          'groupId': groupId,
          'role': 'member',
        });

        transaction.update(groupRef, {
          'memberCount': FieldValue.increment(1),
        });
      });

      await AuditLogger.log(
        groupId: groupId,
        action: 'APPROVE_MEMBER',
        performedBy: respondedBy,
        performedByName: respondedByName,
        targetId: userId,
        targetType: 'membership',
        newValue: {'status': 'approved'},
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('मंजूर करताना त्रुटी आली: ${e.toString()}');
    }
  }

  /// Rejects membership request
  Future<void> rejectMembership({
    required String membershipId,
    required String groupId,
    required String userId,
    required String respondedBy,
    required String respondedByName,
  }) async {
    try {
      final membershipRef =
          _firestore.collection(FirestoreCollections.memberships).doc(membershipId);
      await membershipRef.update({
        'status': MembershipStatus.rejected.name,
        'respondedAt': FieldValue.serverTimestamp(),
        'respondedBy': respondedBy,
      });

      await AuditLogger.log(
        groupId: groupId,
        action: 'REJECT_MEMBER',
        performedBy: respondedBy,
        performedByName: respondedByName,
        targetId: userId,
        targetType: 'membership',
        newValue: {'status': 'rejected'},
      );
    } catch (e) {
      throw AppException('नाकारताना त्रुटी आली: ${e.toString()}');
    }
  }
}
