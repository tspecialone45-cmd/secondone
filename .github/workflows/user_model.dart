import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { leader, deputy, member }

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String village;
  final String aadhaarLast4;
  final String aadhaarEncrypted;
  final UserRole role;
  final String? groupId;
  final String? fcmToken;
  final String language;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.village,
    required this.aadhaarLast4,
    required this.aadhaarEncrypted,
    required this.role,
    this.groupId,
    this.fcmToken,
    this.language = 'mr',
    this.profilePhotoUrl,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'village': village,
      'aadhaarLast4': aadhaarLast4,
      'aadhaarEncrypted': aadhaarEncrypted,
      'role': role.name,
      'groupId': groupId,
      'fcmToken': fcmToken,
      'language': language,
      'profilePhotoUrl': profilePhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      village: map['village'] ?? '',
      aadhaarLast4: map['aadhaarLast4'] ?? '',
      aadhaarEncrypted: map['aadhaarEncrypted'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.member,
      ),
      groupId: map['groupId'],
      fcmToken: map['fcmToken'],
      language: map['language'] ?? 'mr',
      profilePhotoUrl: map['profilePhotoUrl'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? village,
    String? aadhaarLast4,
    String? aadhaarEncrypted,
    UserRole? role,
    String? groupId,
    String? fcmToken,
    String? language,
    String? profilePhotoUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      village: village ?? this.village,
      aadhaarLast4: aadhaarLast4 ?? this.aadhaarLast4,
      aadhaarEncrypted: aadhaarEncrypted ?? this.aadhaarEncrypted,
      role: role ?? this.role,
      groupId: groupId ?? this.groupId,
      fcmToken: fcmToken ?? this.fcmToken,
      language: language ?? this.language,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
