import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bank_transaction_model.dart';
import '../../data/repositories/bank_repository.dart';
import 'group_provider.dart';
import 'loan_provider.dart';
import 'savings_provider.dart';

final bankRepositoryProvider = Provider<BankRepository>((ref) {
  return BankRepository();
});

final bankTransactionsProvider = StreamProvider<List<BankTransactionModel>>((ref) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value([]);
  return ref.watch(bankRepositoryProvider).getTransactions(group.id);
});

final currentBalancesProvider = StreamProvider<Map<String, double>>((ref) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value({'bankBalance': 0.0, 'cashInHand': 0.0});
  return ref.watch(bankRepositoryProvider).getCurrentBalances(group.id);
});

// Available fund to lend = (Total savings + Total interest earned) - Total active loans outstanding
final availableFundToLendProvider = Provider<double>((ref) {
  final totalSavings = ref.watch(totalGroupSavingsProvider);
  final totalInterest = ref.watch(totalInterestEarnedProvider);
  final totalLoansOutstanding = ref.watch(totalOutstandingLoansProvider);

  final totalFund = totalSavings + totalInterest;
  final available = totalFund - totalLoansOutstanding;
  return available.clamp(0.0, double.infinity);
});

class BankNotifier extends StateNotifier<AsyncValue<void>> {
  final BankRepository _bankRepository;

  BankNotifier(this._bankRepository) : super(const AsyncValue.data(null));

  Future<bool> recordTransaction({
    required BankTransactionModel transaction,
    required String performedByName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _bankRepository.recordTransaction(
        transaction: transaction,
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

final bankNotifierProvider = StateNotifierProvider<BankNotifier, AsyncValue<void>>((ref) {
  return BankNotifier(ref.watch(bankRepositoryProvider));
});
