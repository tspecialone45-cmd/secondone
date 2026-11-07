import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/bank_transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../providers/group_provider.dart';

class BankBookScreen extends ConsumerStatefulWidget {
  const BankBookScreen({super.key});

  @override
  ConsumerState<BankBookScreen> createState() => _BankBookScreenState();
}

class _BankBookScreenState extends ConsumerState<BankBookScreen> {
  void _showAddTransactionDialog() {
    TransactionType selectedType = TransactionType.deposit;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime txDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('नवीन व्यवहार नोंदवा'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<TransactionType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'व्यवहाराचा प्रकार'),
                  items: const [
                    DropdownMenuItem(
                      value: TransactionType.deposit,
                      child: Text('बँकेत ठेव (Bank Deposit)'),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.withdrawal,
                      child: Text('बँकेतून काढणे (Bank Withdrawal)'),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.cashIn,
                      child: Text('रोख जमा (Cash In)'),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.cashOut,
                      child: Text('रोख खर्च (Cash Out)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'रक्कम (₹)',
                  hint: 'उदा. 2000',
                  controller: amountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'तपशील / कारण',
                  hint: 'उदा. राष्ट्रीयीकृत बँकेत मासिक बचत खात्यात जमा',
                  controller: descriptionController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करा')),
            ElevatedButton(
              onPressed: () async {
                final group = ref.read(currentGroupProvider).value;
                final user = ref.read(currentUserProfileProvider).value;
                if (group == null || user == null) return;

                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amount <= 0) return;

                const uuid = Uuid();
                final tx = BankTransactionModel(
                  id: uuid.v4(),
                  groupId: group.id,
                  type: selectedType,
                  amount: amount,
                  description: descriptionController.text.trim(),
                  date: txDate,
                  recordedBy: user.uid,
                );

                await ref.read(bankNotifierProvider.notifier).recordTransaction(
                      transaction: tx,
                      performedByName: user.name,
                    );

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('जतन करा'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balances = ref.watch(currentBalancesProvider).value ?? {'bankBalance': 0.0, 'cashInHand': 0.0};
    final transactions = ref.watch(bankTransactionsProvider).value ?? [];

    final bankBalance = balances['bankBalance'] ?? 0.0;
    final cashInHand = balances['cashInHand'] ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('बँक आणि रोख नोंदवही'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('व्यवहार नोंदवा', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddTransactionDialog,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Balances Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance, color: Colors.blue, size: 20),
                              SizedBox(width: 6),
                              Text('बँकेत जमा शिल्लक', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${bankBalance.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.payments, color: Colors.green, size: 20),
                              SizedBox(width: 6),
                              Text('हातातील रोख शिल्लक', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${cashInHand.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Transactions History
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('कोणतेही व्यवहार नोंदवले नाहीत.'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final isCredit = tx.type == TransactionType.deposit || tx.type == TransactionType.cashIn;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isCredit ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description.isNotEmpty ? tx.description : _getTypeLabel(tx.type),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      '${_getTypeLabel(tx.type)} • ${tx.date.toFormattedDate()}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isCredit ? '+' : '-'} ₹${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCredit ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return 'बँक ठेव';
      case TransactionType.withdrawal:
        return 'बँक काढणे';
      case TransactionType.cashIn:
        return 'रोख जमा';
      case TransactionType.cashOut:
        return 'रोख खर्च';
    }
  }
}
