import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/loan_model.dart';
import '../../../data/models/repayment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/loan_provider.dart';

class LoanManagementScreen extends ConsumerStatefulWidget {
  const LoanManagementScreen({super.key});

  @override
  ConsumerState<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends ConsumerState<LoanManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRepaymentDialog(LoanModel loan) {
    final principalController = TextEditingController();
    final interestRate = loan.interestRate; // 1% per month default
    final calculatedInterest = ref.read(loanRepositoryProvider).calculateMonthlyInterest(loan.outstandingPrincipal, interestRate);
    final interestController = TextEditingController(text: calculatedInterest.toStringAsFixed(0));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final principal = double.tryParse(principalController.text) ?? 0.0;
          final remaining = (loan.outstandingPrincipal - principal).clamp(0.0, double.infinity);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('${loan.memberName} - हप्ता / परतफेड'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('सध्याचे मुद्दल:'),
                            Text('₹${loan.outstandingPrincipal.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('१% मासिक व्याज:'),
                            Text('₹${calculatedInterest.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    label: 'परतफेड मुद्दल रक्कम (₹)',
                    hint: 'उदा. 500',
                    controller: principalController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'भरलेले व्याज (₹)',
                    hint: 'उदा. 100',
                    controller: interestController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'नोंद / टिप्पणी (पर्यायी)',
                    hint: 'उदा. रोख प्राप्त',
                    controller: notesController,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('उर्वरित बाकी मुद्दल:'),
                        Text(
                          '₹${remaining.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('रद्द करा'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final user = ref.read(currentUserProfileProvider).value;
                  if (user == null) return;

                  final pPaid = double.tryParse(principalController.text) ?? 0.0;
                  final iPaid = double.tryParse(interestController.text) ?? 0.0;

                  if (pPaid <= 0 && iPaid <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('कृपया मुद्दल किंवा व्याज रक्कम टाका.')),
                    );
                    return;
                  }

                  const uuid = Uuid();
                  final repayment = RepaymentModel(
                    id: uuid.v4(),
                    loanId: loan.id,
                    groupId: loan.groupId,
                    userId: loan.userId,
                    principalPaid: pPaid,
                    interestPaid: iPaid,
                    totalPaid: pPaid + iPaid,
                    recordedBy: user.uid,
                    remainingPrincipal: remaining,
                    notes: notesController.text.trim(),
                  );

                  final success = await ref
                      .read(loanNotifierProvider.notifier)
                      .recordRepayment(repayment: repayment, performedByName: user.name);

                  if (ctx.mounted) Navigator.pop(ctx);

                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('परतफेड यशस्वीरित्या नोंदवली गेली!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('जतन करा'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(groupLoansProvider).value ?? [];
    final user = ref.watch(currentUserProfileProvider).value;

    final pendingLoans = loans.where((l) => l.status == LoanStatus.pending).toList();
    final activeLoans = loans.where((l) => l.status == LoanStatus.active).toList();
    final overdueLoans = loans.where((l) => l.status == LoanStatus.overdue).toList();
    final closedLoans = loans.where((l) => l.status == LoanStatus.closed).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('कर्ज व्यवस्थापन (Loans)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(text: 'सक्रिय (${activeLoans.length})'),
            Tab(text: 'प्रलंबित अर्ज (${pendingLoans.length})'),
            Tab(text: 'थकित (${overdueLoans.length})'),
            Tab(text: 'पूर्ण/बंद (${closedLoans.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoanList(activeLoans, isActiveTab: true),
          _buildPendingLoanList(pendingLoans, user),
          _buildLoanList(overdueLoans, isOverdueTab: true),
          _buildLoanList(closedLoans, isClosedTab: true),
        ],
      ),
    );
  }

  Widget _buildPendingLoanList(List<LoanModel> list, dynamic user) {
    if (list.isEmpty) {
      return const Center(child: Text('कोणतेही प्रलंबित कर्ज अर्ज नाहीत.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final loan = list[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loan.memberName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '₹${loan.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('कारण: ${loan.purpose}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              Text('अर्ज दिनांक: ${loan.createdAt.toFormattedDate()}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (user == null) return;
                        ref.read(loanNotifierProvider.notifier).rejectLoan(
                              loanId: loan.id,
                              groupId: loan.groupId,
                              rejectedBy: user.uid,
                              rejectedByName: user.name,
                            );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('नाकारा'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (user == null) return;
                        ref.read(loanNotifierProvider.notifier).approveLoan(
                              loanId: loan.id,
                              groupId: loan.groupId,
                              approvedBy: user.uid,
                              approvedByName: user.name,
                            );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('मंजूर व वितरित करा'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoanList(
    List<LoanModel> list, {
    bool isActiveTab = false,
    bool isOverdueTab = false,
    bool isClosedTab = false,
  }) {
    if (list.isEmpty) {
      return const Center(child: Text('या विभागात कोणतीही कर्जे नाहीत.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final loan = list[index];
        final interestDue = ref.read(loanRepositoryProvider).calculateMonthlyInterest(loan.outstandingPrincipal, loan.interestRate);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverdueTab ? AppColors.error : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loan.memberName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isClosedTab
                          ? Colors.grey.shade200
                          : isOverdueTab
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isClosedTab ? 'पूर्ण' : isOverdueTab ? 'थकित' : 'सक्रिय',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isClosedTab ? Colors.grey : isOverdueTab ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('बाकी मुद्दल:', style: TextStyle(color: AppColors.textSecondary)),
                  Text('₹${loan.outstandingPrincipal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('मासिक व्याज (१%):', style: TextStyle(color: AppColors.textSecondary)),
                  Text('₹${interestDue.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('एकूण परतफेड मुद्दल:', style: TextStyle(color: AppColors.textSecondary)),
                  Text('₹${loan.totalRepaid.toStringAsFixed(0)}'),
                ],
              ),
              if (isActiveTab || isOverdueTab) ...[
                const Divider(height: 20),
                CustomButton(
                  label: 'हप्ता / व्याज नोंदवा (Record Repayment)',
                  icon: Icons.payments,
                  height: 46,
                  onPressed: () => _showRepaymentDialog(loan),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
