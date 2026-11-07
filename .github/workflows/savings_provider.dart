import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/saving_model.dart';
import '../../data/repositories/savings_repository.dart';
import 'auth_provider.dart';
import 'group_provider.dart';

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepository();
});

final groupSavingsProvider = StreamProvider<List<SavingModel>>((ref) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value([]);
  return ref.watch(savingsRepositoryProvider).getSavingsForGroup(group.id);
});

final memberSavingsProvider = StreamProvider.family<List<SavingModel>, String>((ref, userId) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value([]);
  return ref.watch(savingsRepositoryProvider).getSavingsForMember(group.id, userId);
});

// Total savings collected in the group
final totalGroupSavingsProvider = Provider<double>((ref) {
  final savings = ref.watch(groupSavingsProvider).value ?? [];
  return savings.fold(0.0, (sum, item) => sum + item.totalPaid);
});

// My personal total savings
final myTotalSavingsProvider = Provider<double>((ref) {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return 0.0;
  final savings = ref.watch(memberSavingsProvider(user.uid)).value ?? [];
  return savings.fold(0.0, (sum, item) => sum + item.totalPaid);
});

class SavingsState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  SavingsState({this.isLoading = false, this.error, this.successMessage});

  SavingsState copyWith({bool? isLoading, String? error, String? successMessage}) {
    return SavingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class SavingsNotifier extends StateNotifier<SavingsState> {
  final SavingsRepository _savingsRepository;

  SavingsNotifier(this._savingsRepository) : super(SavingsState());

  Future<bool> recordSaving(SavingModel saving, String performedByName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _savingsRepository.recordSaving(
        saving: saving,
        performedByName: performedByName,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'बचत यशस्वीरित्या नोंदवली गेली!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> recordBulkSavings({
    required String groupId,
    required List<SavingModel> savingsList,
    required String performedBy,
    required String performedByName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _savingsRepository.recordBulkSavings(
        groupId: groupId,
        savingsList: savingsList,
        performedBy: performedBy,
        performedByName: performedByName,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'मासिक संकलन यशस्वीरित्या जतन केले!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final savingsNotifierProvider =
    StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  return SavingsNotifier(ref.watch(savingsRepositoryProvider));
});
