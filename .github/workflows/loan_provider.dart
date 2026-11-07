import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/repayment_model.dart';
import '../../data/repositories/loan_repository.dart';
import 'auth_provider.dart';
import 'group_provider.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository();
});

final groupLoansProvider = StreamProvider<List<LoanModel>>((ref) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value([]);
  return ref.watch(loanRepositoryProvider).getLoansForGroup(group.id);
});

final memberLoansProvider = StreamProvider.family<List<LoanModel>, String>((ref, userId) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value([]);
  return ref.watch(loanRepositoryProvider).getLoansForMember(group.id, userId);
});

// Total outstanding loan given across the group
final totalOutstandingLoansProvider = Provider<double>((ref) {
  final loans = ref.watch(groupLoansProvider).value ?? [];
  return loans
      .where((l) => l.status == LoanStatus.active || l.status == LoanStatus.overdue)
      .fold(0.0, (sum, item) => sum + item.outstandingPrincipal);
});

// Total interest earned across the group
final totalInterestEarnedProvider = Provider<double>((ref) {
  final loans = ref.watch(groupLoansProvider).value ?? [];
  return loans.fold(0.0, (sum, item) => sum + item.totalInterestPaid);
});

class LoanState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  LoanState({this.isLoading = false, this.error, this.successMessage});

  LoanState copyWith({bool? isLoading, String? error, String? successMessage}) {
    return LoanState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class LoanNotifier extends StateNotifier<LoanState> {
  final LoanRepository _loanRepository;

  LoanNotifier(this._loanRepository) : super(LoanState());

  Future<bool> applyForLoan(LoanModel loan) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _loanRepository.applyForLoan(loan);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'कर्जासाठी अर्ज यशस्वीरित्या पाठवला आहे!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> approveLoan({
    required String loanId,
    required String groupId,
    required String approvedBy,
    required String approvedByName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _loanRepository.approveLoan(
        loanId: loanId,
        groupId: groupId,
        approvedBy: approvedBy,
        approvedByName: approvedByName,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'कर्ज मंजूर करून वितरित केले आहे!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> rejectLoan({
    required String loanId,
    required String groupId,
    required String rejectedBy,
    required String rejectedByName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _loanRepository.rejectLoan(
        loanId: loanId,
        groupId: groupId,
        rejectedBy: rejectedBy,
        rejectedByName: rejectedByName,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'कर्ज अर्ज नाकारण्यात आला.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> recordRepayment({
    required RepaymentModel repayment,
    required String performedByName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _loanRepository.recordRepayment(
        repayment: repayment,
        performedByName: performedByName,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'हप्ता यशस्वीरित्या नोंदवला गेला!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final loanNotifierProvider = StateNotifierProvider<LoanNotifier, LoanState>((ref) {
  return LoanNotifier(ref.watch(loanRepositoryProvider));
});
