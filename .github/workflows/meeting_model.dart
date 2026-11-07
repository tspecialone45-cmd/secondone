import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingModel {
  final String id;
  final String groupId;
  final DateTime date;
  final String time;
  final String place;
  final String agenda;
  final String? minutes;
  final String createdBy;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final DateTime createdAt;

  MeetingModel({
    required this.id,
    required this.groupId,
    required this.date,
    required this.time,
    required this.place,
    required this.agenda,
    this.minutes,
    required this.createdBy,
    this.status = 'scheduled',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'date': Timestamp.fromDate(date),
      'time': time,
      'place': place,
      'agenda': agenda,
      'minutes': minutes,
      'createdBy': createdBy,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MeetingModel.fromMap(Map<String, dynamic> map, String docId) {
    return MeetingModel(
      id: docId,
      groupId: map['groupId'] ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      time: map['time'] ?? '',
      place: map['place'] ?? '',
      agenda: map['agenda'] ?? '',
      minutes: map['minutes'],
      createdBy: map['createdBy'] ?? '',
      status: map['status'] ?? 'scheduled',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory MeetingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MeetingModel.fromMap(data, doc.id);
  }

  MeetingModel copyWith({
    String? id,
    String? groupId,
    DateTime? date,
    String? time,
    String? place,
    String? agenda,
    String? minutes,
    String? createdBy,
    String? status,
    DateTime? createdAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      date: date ?? this.date,
      time: time ?? this.time,
      place: place ?? this.place,
      agenda: agenda ?? this.agenda,
      minutes: minutes ?? this.minutes,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
