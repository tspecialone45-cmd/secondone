import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/loan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/loan_provider.dart';

class LoanApplyScreen extends ConsumerStatefulWidget {
  const LoanApplyScreen({super.key});

  @override
  ConsumerState<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends ConsumerState<LoanApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  int _emiDay = 10;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProfileProvider).value;
    final group = ref.read(currentGroupProvider).value;
    if (user == null || group == null) return;

    setState(() => _isSubmitting = true);

    const uuid = Uuid();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final loan = LoanModel(
      id: uuid.v4(),
      groupId: group.id,
      userId: user.uid,
      memberName: user.name,
      amount: amount,
      purpose: _purposeController.text.trim(),
      status: LoanStatus.pending,
      interestRate: group.settings.interestRate,
      emiDay: _emiDay,
    );

    final success = await ref.read(loanNotifierProvider.notifier).applyForLoan(loan);
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('कर्ज अर्ज पाठवला!'),
            content: const Text(
              'आपला कर्ज अर्ज यशस्वीपणे अध्यक्षांकडे पाठवला आहे. अध्यक्षांच्या मंजुरीनंतर रक्कम वितरित केली जाईल.',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              CustomButton(
                label: 'ठीक आहे',
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('अर्ज करताना त्रुटी आली.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final myLoans = ref.watch(memberLoansProvider(user?.uid ?? '')).value ?? [];
    final availableFund = ref.watch(availableFundToLendProvider);
    final group = ref.watch(currentGroupProvider).value;

    final activeLoan = myLoans.cast<LoanModel?>().firstWhere(
          (l) => l?.status == LoanStatus.active || l?.status == LoanStatus.overdue,
          orElse: () => null,
        );

    final pendingLoan = myLoans.cast<LoanModel?>().firstWhere(
          (l) => l?.status == LoanStatus.pending,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('कर्ज अर्ज (Apply for Loan)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Loan Warning if member already has active loan
              if (activeLoan != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('आपले चालू कर्ज सक्रिय आहे', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('बाकी मुद्दल: ₹${activeLoan.outstandingPrincipal.toStringAsFixed(0)}'),
                      Text('पुढील हप्ता दिनांक: ${activeLoan.nextDueDate?.toFormattedDate() ?? 'लागू नाही'}'),
                      const SizedBox(height: 6),
                      const Text(
                        'नियम: चालू कर्ज पूर्ण भरल्यानंतरच नवीन कर्जासाठी अर्ज करता येईल.',
                        style: TextStyle(fontSize: 12, color: Colors.brown),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (pendingLoan != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.hourglass_top, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('कर्ज अर्ज प्रलंबित आहे', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('मागितलेली रक्कम: ₹${pendingLoan.amount.toStringAsFixed(0)}'),
                      Text('कारण: ${pendingLoan.purpose}'),
                      const SizedBox(height: 4),
                      const Text('अध्यक्षांच्या मंजुरीची प्रतीक्षा आहे.', style: TextStyle(color: Colors.blue, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // Loan Rules & Fund Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: AppColors.secondary, size: 22),
                          SizedBox(width: 8),
                          Text('गटातील उपलब्ध कर्ज निधी', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${availableFund.toStringAsFixed(0)} उपलब्ध',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                      const Divider(height: 18),
                      Text(
                        '• व्याज दर: ${group?.settings.interestRate ?? 1.0}% प्रति महिना (घटत्या मुद्दलावर)\n• हिशेब पूर्णतः पारदर्शक व गट बैठकीत मंजूर केला जाईल.',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Application Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        label: 'कर्ज रक्कम (₹)',
                        hint: 'उदा. 5000',
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.currency_rupee,
                        validator: Validators.validateAmount,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'कर्ज घेण्याचे कारण / उद्देश',
                        hint: 'उदा. घरगुती व्यवसाय / वैद्यकीय खर्च / मुलांचे शिक्षण',
                        controller: _purposeController,
                        prefixIcon: Icons.edit_note,
                        validator: (v) => Validators.validateRequired(v, 'कर्जाचे कारण'),
                      ),
                      const SizedBox(height: 16),

                      // EMI Day Dropdown
                      DropdownButtonFormField<int>(
                        value: _emiDay,
                        decoration: const InputDecoration(labelText: 'दरमहा हप्ता भरण्याची तारीख'),
                        items: [5, 10, 15, 20, 25]
                            .map((day) => DropdownMenuItem(value: day, child: Text('प्रत्येक महिन्याची $day तारीख')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _emiDay = val);
                        },
                      ),
                      const SizedBox(height: 28),

                      CustomButton(
                        label: 'कर्जासाठी अर्ज पाठवा',
                        icon: Icons.send,
                        isLoading: _isSubmitting,
                        backgroundColor: AppColors.secondary,
                        onPressed: _handleSubmit,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
