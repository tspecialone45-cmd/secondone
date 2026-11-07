import 'package:cloud_firestore/cloud_firestore.dart';

class GroupSettings {
  final int maxMembers;
  final double monthlyAmount;
  final double interestRate;
  final double lateFee;
  final bool lateFeeEnabled;
  final bool deputyCanWrite;

  GroupSettings({
    this.maxMembers = 11,
    this.monthlyAmount = 100.0,
    this.interestRate = 1.0,
    this.lateFee = 0.0,
    this.lateFeeEnabled = false,
    this.deputyCanWrite = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'maxMembers': maxMembers,
      'monthlyAmount': monthlyAmount,
      'interestRate': interestRate,
      'lateFee': lateFee,
      'lateFeeEnabled': lateFeeEnabled,
      'deputyCanWrite': deputyCanWrite,
    };
  }

  factory GroupSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return GroupSettings();
    return GroupSettings(
      maxMembers: map['maxMembers'] ?? 11,
      monthlyAmount: (map['monthlyAmount'] as num?)?.toDouble() ?? 100.0,
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 1.0,
      lateFee: (map['lateFee'] as num?)?.toDouble() ?? 0.0,
      lateFeeEnabled: map['lateFeeEnabled'] ?? false,
      deputyCanWrite: map['deputyCanWrite'] ?? true,
    );
  }

  GroupSettings copyWith({
    int? maxMembers,
    double? monthlyAmount,
    double? interestRate,
    double? lateFee,
    bool? lateFeeEnabled,
    bool? deputyCanWrite,
  }) {
    return GroupSettings(
      maxMembers: maxMembers ?? this.maxMembers,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      interestRate: interestRate ?? this.interestRate,
      lateFee: lateFee ?? this.lateFee,
      lateFeeEnabled: lateFeeEnabled ?? this.lateFeeEnabled,
      deputyCanWrite: deputyCanWrite ?? this.deputyCanWrite,
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String village;
  final DateTime startDate;
  final String leaderUid;
  final String? deputyUid;
  final String groupCode;
  final GroupSettings settings;
  final int memberCount;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.village,
    required this.startDate,
    required this.leaderUid,
    this.deputyUid,
    required this.groupCode,
    GroupSettings? settings,
    this.memberCount = 1,
    DateTime? createdAt,
  })  : settings = settings ?? GroupSettings(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'village': village,
      'startDate': Timestamp.fromDate(startDate),
      'leaderUid': leaderUid,
      'deputyUid': deputyUid,
      'groupCode': groupCode,
      'settings': settings.toMap(),
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String docId) {
    return GroupModel(
      id: docId,
      name: map['name'] ?? '',
      village: map['village'] ?? '',
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      leaderUid: map['leaderUid'] ?? '',
      deputyUid: map['deputyUid'],
      groupCode: map['groupCode'] ?? '',
      settings: GroupSettings.fromMap(map['settings'] as Map<String, dynamic>?),
      memberCount: map['memberCount'] ?? 1,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GroupModel.fromMap(data, doc.id);
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? village,
    DateTime? startDate,
    String? leaderUid,
    String? deputyUid,
    String? groupCode,
    GroupSettings? settings,
    int? memberCount,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      village: village ?? this.village,
      startDate: startDate ?? this.startDate,
      leaderUid: leaderUid ?? this.leaderUid,
      deputyUid: deputyUid ?? this.deputyUid,
      groupCode: groupCode ?? this.groupCode,
      settings: settings ?? this.settings,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
