import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_keys.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/audit_logger.dart';
import '../models/loan_model.dart';
import '../models/repayment_model.dart';

class LoanRepository {
  final FirebaseFirestore _firestore;

  LoanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 1% per month on outstanding reducing principal
  double calculateMonthlyInterest(double outstandingPrincipal, [double monthlyRate = 1.0]) {
    if (outstandingPrincipal <= 0) return 0.0;
    return (outstandingPrincipal * (monthlyRate / 100.0));
  }

  Future<void> applyForLoan(LoanModel loan) async {
    try {
      final docRef = _firestore.collection(FirestoreCollections.loans).doc(loan.id);
      await docRef.set(loan.toMap());
    } catch (e) {
      throw AppException('कर्ज अर्ज करताना त्रुटी आली: ${e.toString()}');
    }
  }

  Future<void> approveLoan({
    required String loanId,
    required String groupId,
    required String approvedBy,
    required String approvedByName,
  }) async {
    try {
      final loanRef = _firestore.collection(FirestoreCollections.loans).doc(loanId);
      final now = DateTime.now();
      await loanRef.update({
        'status': LoanStatus.active.name,
        'approvedBy': approvedBy,
        'disbursedAt': Timestamp.fromDate(now),
        'nextDueDate': Timestamp.fromDate(DateTime(now.year, now.month + 1, 10)),
      });

      await AuditLogger.log(
        groupId: groupId,
        action: 'APPROVE_LOAN',
        performedBy: approvedBy,
        performedByName: approvedByName,
        targetId: loanId,
        targetType: 'loan',
        newValue: {'status': 'active'},
      );
    } catch (e) {
      throw AppException('कर्ज मंजूर करताना त्रुटी आली: ${e.toString()}');
    }
  }

  Future<void> rejectLoan({
    required String loanId,
    required String groupId,
    required String rejectedBy,
    required String rejectedByName,
  }) async {
    try {
      final loanRef = _firestore.collection(FirestoreCollections.loans).doc(loanId);
      await loanRef.update({
        'status': LoanStatus.closed.name,
      });

      await AuditLogger.log(
        groupId: groupId,
        action: 'REJECT_LOAN',
        performedBy: rejectedBy,
        performedByName: rejectedByName,
        targetId: loanId,
        targetType: 'loan',
        newValue: {'status': 'rejected'},
      );
    } catch (e) {
      throw AppException('कर्ज नाकारताना त्रुटी आली: ${e.toString()}');
    }
  }

  /// Records loan repayment (reducing balance formula)
  Future<void> recordRepayment({
    required RepaymentModel repayment,
    required String performedByName,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final loanRef = _firestore.collection(FirestoreCollections.loans).doc(repayment.loanId);
        final loanDoc = await transaction.get(loanRef);

        if (!loanDoc.exists) {
          throw AppException('कर्ज माहिती सापडली नाही.');
        }

        final currentLoan = LoanModel.fromFirestore(loanDoc);
        final newOutstanding =
            (currentLoan.outstandingPrincipal - repayment.principalPaid).clamp(0.0, double.infinity);
        final newRepaid = currentLoan.totalRepaid + repayment.principalPaid;
        final newInterest = currentLoan.totalInterestPaid + repayment.interestPaid;
        final isClosed = newOutstanding <= 0.0;

        // Next due date: next month
        final currentDue = currentLoan.nextDueDate ?? DateTime.now();
        final nextDue = DateTime(currentDue.year, currentDue.month + 1, currentLoan.emiDay);

        transaction.update(loanRef, {
          'outstandingPrincipal': newOutstanding,
          'totalRepaid': newRepaid,
          'totalInterestPaid': newInterest,
          'status': isClosed ? LoanStatus.closed.name : LoanStatus.active.name,
          'nextDueDate': Timestamp.fromDate(nextDue),
        });

        final repaymentRef =
            _firestore.collection(FirestoreCollections.repayments).doc(repayment.id);
        transaction.set(repaymentRef, repayment.toMap());
      });

      await AuditLogger.log(
        groupId: repayment.groupId,
        action: 'RECORD_REPAYMENT',
        performedBy: repayment.recordedBy,
        performedByName: performedByName,
        targetId: repayment.id,
        targetType: 'repayment',
        newValue: repayment.toMap(),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('परतफेड नोंदवताना त्रुटी आली: ${e.toString()}');
    }
  }

  Stream<List<LoanModel>> getLoansForGroup(String groupId) {
    return _firestore
        .collection(FirestoreCollections.loans)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LoanModel.fromFirestore(doc)).toList());
  }

  Stream<List<LoanModel>> getLoansForMember(String groupId, String userId) {
    return _firestore
        .collection(FirestoreCollections.loans)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LoanModel.fromFirestore(doc)).toList());
  }

  Stream<List<RepaymentModel>> getRepaymentsForLoan(String loanId) {
    return _firestore
        .collection(FirestoreCollections.repayments)
        .where('loanId', isEqualTo: loanId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RepaymentModel.fromFirestore(doc)).toList());
  }
}
