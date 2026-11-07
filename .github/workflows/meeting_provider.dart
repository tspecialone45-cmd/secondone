import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/meeting_model.dart';
import '../../data/repositories/meeting_repository.dart';
import 'group_provider.dart';

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return MeetingRepository();
});

final groupMeetingsProvider = StreamProvider<List<MeetingModel>>((ref) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value([]);
  return ref.watch(meetingRepositoryProvider).getMeetings(group.id);
});

final meetingAttendanceProvider =
    FutureProvider.family<List<AttendanceModel>, String>((ref, meetingId) {
  return ref.watch(meetingRepositoryProvider).getAttendanceForMeeting(meetingId);
});

final memberAttendanceStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Future.value({'total': 0, 'attended': 0, 'percentage': 0.0});
  return ref.watch(meetingRepositoryProvider).getMemberAttendanceStats(group.id, userId);
});

class MeetingNotifier extends StateNotifier<AsyncValue<void>> {
  final MeetingRepository _meetingRepository;

  MeetingNotifier(this._meetingRepository) : super(const AsyncValue.data(null));

  Future<bool> createMeeting(MeetingModel meeting) async {
    state = const AsyncValue.loading();
    try {
      await _meetingRepository.createMeeting(meeting);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateMinutes({
    required String meetingId,
    required String minutes,
    required String performedBy,
    required String performedByName,
    required String groupId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _meetingRepository.updateMeetingMinutes(
        meetingId: meetingId,
        minutes: minutes,
        performedBy: performedBy,
        performedByName: performedByName,
        groupId: groupId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> markAttendance({
    required String meetingId,
    required String groupId,
    required List<AttendanceModel> attendanceList,
    required String performedBy,
    required String performedByName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _meetingRepository.markAttendance(
        meetingId: meetingId,
        groupId: groupId,
        attendanceList: attendanceList,
        performedBy: performedBy,
        performedByName: performedByName,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final meetingNotifierProvider =
    StateNotifierProvider<MeetingNotifier, AsyncValue<void>>((ref) {
  return MeetingNotifier(ref.watch(meetingRepositoryProvider));
});
