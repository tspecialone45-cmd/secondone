import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_keys.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/audit_logger.dart';
import '../models/group_model.dart';
import '../models/membership_model.dart';

class GroupRepository {
  final FirebaseFirestore _firestore;

  GroupRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String generateGroupCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Creates a group and associates the leader
  Future<GroupModel> createGroup({
    required String name,
    required String village,
    required DateTime startDate,
    required String leaderUid,
    required String leaderName,
    required String leaderPhone,
    GroupSettings? settings,
  }) async {
    try {
      final docRef = _firestore.collection(FirestoreCollections.groups).doc();
      final code = generateGroupCode();
      final group = GroupModel(
        id: docRef.id,
        name: name,
        village: village,
        startDate: startDate,
        leaderUid: leaderUid,
        groupCode: code,
        settings: settings ?? GroupSettings(),
        memberCount: 1,
        createdAt: DateTime.now(),
      );

      final batch = _firestore.batch();
      batch.set(docRef, group.toMap());

      // Update leader's user document
      final userRef = _firestore.collection(FirestoreCollections.users).doc(leaderUid);
      batch.update(userRef, {
        'groupId': docRef.id,
        'role': 'leader',
      });

      // Create membership record for the leader as approved
      final membershipRef = _firestore
          .collection(FirestoreCollections.memberships)
          .doc('${docRef.id}_$leaderUid');
      final membership = MembershipModel(
        id: membershipRef.id,
        groupId: docRef.id,
        userId: leaderUid,
        userName: leaderName,
        userPhone: leaderPhone,
        status: MembershipStatus.approved,
        role: 'leader',
        requestedAt: DateTime.now(),
        respondedAt: DateTime.now(),
        respondedBy: leaderUid,
      );
      batch.set(membershipRef, membership.toMap());

      await batch.commit();

      await AuditLogger.log(
        groupId: docRef.id,
        action: 'CREATE_GROUP',
        performedBy: leaderUid,
        performedByName: leaderName,
        targetId: docRef.id,
        targetType: 'group',
        newValue: group.toMap(),
      );

      return group;
    } catch (e) {
      throw AppException('गट तयार करताना त्रुटी आली: ${e.toString()}');
    }
  }

  Future<GroupModel?> getGroupByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.groups)
          .where('groupCode', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return GroupModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw AppException('गट शोधताना त्रुटी आली: ${e.toString()}');
    }
  }

  Future<GroupModel?> getGroupById(String id) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.groups).doc(id).get();
      if (!doc.exists) return null;
      return GroupModel.fromFirestore(doc);
    } catch (e) {
      throw AppException('गट माहिती आणताना त्रुटी आली: ${e.toString()}');
    }
  }

  Stream<GroupModel?> watchGroup(String id) {
    return _firestore
        .collection(FirestoreCollections.groups)
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? GroupModel.fromFirestore(doc) : null);
  }

  Future<void> updateGroupSettings({
    required String groupId,
    required GroupSettings settings,
    required String performedBy,
    required String performedByName,
  }) async {
    try {
      final groupRef = _firestore.collection(FirestoreCollections.groups).doc(groupId);
      await groupRef.update({'settings': settings.toMap()});

      await AuditLogger.log(
        groupId: groupId,
        action: 'UPDATE_SETTINGS',
        performedBy: performedBy,
        performedByName: performedByName,
        targetId: groupId,
        targetType: 'settings',
        newValue: settings.toMap(),
      );
    } catch (e) {
      throw AppException('सेटिंग्ज जतन करताना त्रुटी आली: ${e.toString()}');
    }
  }
}
