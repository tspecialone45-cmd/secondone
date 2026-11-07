import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/group_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/member_repository.dart';
import 'auth_provider.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

final currentGroupProvider = StreamProvider<GroupModel?>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).value;
  if (userProfile?.groupId == null) return Stream.value(null);
  return ref.watch(groupRepositoryProvider).watchGroup(userProfile!.groupId!);
});

final pendingRequestsProvider = StreamProvider<List<MembershipModel>>((ref) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value([]);
  return ref.watch(memberRepositoryProvider).getPendingRequests(group.id);
});

final approvedMembersProvider = StreamProvider<List<UserModel>>((ref) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value([]);
  return ref.watch(memberRepositoryProvider).getApprovedMembers(group.id);
});

class GroupState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  GroupState({this.isLoading = false, this.error, this.successMessage});

  GroupState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return GroupState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class GroupNotifier extends StateNotifier<GroupState> {
  final GroupRepository _groupRepository;
  final MemberRepository _memberRepository;

  GroupNotifier(this._groupRepository, this._memberRepository) : super(GroupState());

  Future<GroupModel?> createGroup({
    required String name,
    required String village,
    required DateTime startDate,
    required String leaderUid,
    required String leaderName,
    required String leaderPhone,
    GroupSettings? settings,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final group = await _groupRepository.createGroup(
        name: name,
        village: village,
        startDate: startDate,
        leaderUid: leaderUid,
        leaderName: leaderName,
        leaderPhone: leaderPhone,
        settings: settings,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'गट यशस्वीरित्या तयार करण्यात आला!',
      );
      return group;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> joinGroupByCode({
    required String groupCode,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final group = await _groupRepository.getGroupByCode(groupCode);
      if (group == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'हा गट कोड सापडला नाही. कृपया बरोबर कोड टाका.',
        );
        return false;
      }

      await _memberRepository.sendJoinRequest(
        groupId: group.id,
        userId: userId,
        userName: userName,
        userPhone: userPhone,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'आपली विनंती पाठवली आहे. अध्यक्षांच्या मंजुरीची प्रतीक्षा करा.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> approveMember({
    required String membershipId,
    required String groupId,
    required String userId,
    required String respondedBy,
    required String respondedByName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _memberRepository.approveMembership(
        membershipId: membershipId,
        groupId: groupId,
        userId: userId,
        respondedBy: respondedBy,
        respondedByName: respondedByName,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'सदस्य यशस्वीरित्या मंजूर करण्यात आला!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> rejectMember({
    required String membershipId,
    required String groupId,
    required String userId,
    required String respondedBy,
    required String respondedByName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _memberRepository.rejectMembership(
        membershipId: membershipId,
        groupId: groupId,
        userId: userId,
        respondedBy: respondedBy,
        respondedByName: respondedByName,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'विनंती नाकारण्यात आली आहे.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateSettings({
    required String groupId,
    required GroupSettings settings,
    required String performedBy,
    required String performedByName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _groupRepository.updateGroupSettings(
        groupId: groupId,
        settings: settings,
        performedBy: performedBy,
        performedByName: performedByName,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'सेटिंग्ज यशस्वीरित्या अपडेट झाल्या!',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final groupNotifierProvider = StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  final groupRepo = ref.watch(groupRepositoryProvider);
  final memberRepo = ref.watch(memberRepositoryProvider);
  return GroupNotifier(groupRepo, memberRepo);
});
