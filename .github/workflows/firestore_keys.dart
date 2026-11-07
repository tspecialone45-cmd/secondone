class FirestoreCollections {
  static const String users = 'users';
  static const String groups = 'groups';
  static const String memberships = 'memberships';
  static const String savings = 'savings';
  static const String loans = 'loans';
  static const String repayments = 'repayments';
  static const String meetings = 'meetings';
  static const String attendance = 'attendance';
  static const String bankTransactions = 'bankTransactions';
  static const String auditLogs = 'auditLogs';
}

class UserFields {
  static const String uid = 'uid';
  static const String name = 'name';
  static const String phone = 'phone';
  static const String village = 'village';
  static const String aadhaarLast4 = 'aadhaarLast4';
  static const String aadhaarEncrypted = 'aadhaarEncrypted';
  static const String role = 'role'; // 'leader', 'deputy', 'member'
  static const String groupId = 'groupId';
  static const String fcmToken = 'fcmToken';
  static const String language = 'language';
  static const String profilePhotoUrl = 'profilePhotoUrl';
  static const String createdAt = 'createdAt';
  static const String isActive = 'isActive';
}

class GroupFields {
  static const String id = 'id';
  static const String name = 'name';
  static const String village = 'village';
  static const String startDate = 'startDate';
  static const String leaderUid = 'leaderUid';
  static const String deputyUid = 'deputyUid';
  static const String groupCode = 'groupCode';
  static const String settings = 'settings';
  static const String memberCount = 'memberCount';
  static const String createdAt = 'createdAt';
}

class MembershipFields {
  static const String id = 'id';
  static const String groupId = 'groupId';
  static const String userId = 'userId';
  static const String userName = 'userName';
  static const String userPhone = 'userPhone';
  static const String status = 'status'; // 'pending', 'approved', 'rejected'
  static const String role = 'role';
  static const String requestedAt = 'requestedAt';
  static const String respondedAt = 'respondedAt';
  static const String respondedBy = 'respondedBy';
}
