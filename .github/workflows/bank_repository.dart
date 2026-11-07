import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_keys.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/audit_logger.dart';
import '../models/bank_transaction_model.dart';

class BankRepository {
  final FirebaseFirestore _firestore;

  BankRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> recordTransaction({
    required BankTransactionModel transaction,
    required String performedByName,
  }) async {
    try {
      final docRef = _firestore
          .collection(FirestoreCollections.bankTransactions)
          .doc(transaction.id);
      await docRef.set(transaction.toMap());

      await AuditLogger.log(
        groupId: transaction.groupId,
        action: 'RECORD_TRANSACTION',
        performedBy: transaction.recordedBy,
        performedByName: performedByName,
        targetId: transaction.id,
        targetType: 'bank_transaction',
        newValue: transaction.toMap(),
      );
    } catch (e) {
      throw AppException('व्यवहार नोंदवताना त्रुटी आली: ${e.toString()}');
    }
  }

  Stream<List<BankTransactionModel>> getTransactions(String groupId) {
    return _firestore
        .collection(FirestoreCollections.bankTransactions)
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BankTransactionModel.fromFirestore(doc))
            .toList());
  }

  /// Calculates real-time bank balance and cash in hand
  Stream<Map<String, double>> getCurrentBalances(String groupId) {
    return _firestore
        .collection(FirestoreCollections.bankTransactions)
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      double bankBalance = 0.0;
      double cashInHand = 0.0;

      for (final doc in snapshot.docs) {
        final tx = BankTransactionModel.fromFirestore(doc);
        switch (tx.type) {
          case TransactionType.deposit:
            bankBalance += tx.amount;
            break;
          case TransactionType.withdrawal:
            bankBalance -= tx.amount;
            break;
          case TransactionType.cashIn:
            cashInHand += tx.amount;
            break;
          case TransactionType.cashOut:
            cashInHand -= tx.amount;
            break;
        }
      }

      return {
        'bankBalance': bankBalance,
        'cashInHand': cashInHand,
      };
    });
  }
}
