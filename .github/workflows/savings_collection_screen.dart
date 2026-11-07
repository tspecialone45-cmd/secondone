import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/saving_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/savings_provider.dart';

class SavingsCollectionScreen extends ConsumerStatefulWidget {
  const SavingsCollectionScreen({super.key});

  @override
  ConsumerState<SavingsCollectionScreen> createState() => _SavingsCollectionScreenState();
}

class _SavingsCollectionScreenState extends ConsumerState<SavingsCollectionScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final Map<String, bool> _paidMap = {};
  final Map<String, double> _lateFeeMap = {};
  bool _isSaving = false;

  void _changeMonth(int delta) {
    setState(() {
      int newMonth = _selectedMonth + delta;
      if (newMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else if (newMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth = newMonth;
      }
      _paidMap.clear();
      _lateFeeMap.clear();
    });
  }

  Future<void> _handleSaveAll() async {
    final group = ref.read(currentGroupProvider).value;
    final user = ref.read(currentUserProfileProvider).value;
    final members = ref.read(approvedMembersProvider).value ?? [];

    if (group == null || user == null) return;

    setState(() => _isSaving = true);

    const uuid = Uuid();
    final List<SavingModel> savingsList = [];

    for (final member in members) {
      final isPaid = _paidMap[member.uid] ?? false;
      if (isPaid) {
        final lateFee = _lateFeeMap[member.uid] ?? 0.0;
        final saving = SavingModel(
          id: '${group.id}_${member.uid}_${_selectedMonth}_$_selectedYear',
          groupId: group.id,
          userId: member.uid,
          memberName: member.name,
          month: _selectedMonth,
          year: _selectedYear,
          amount: group.settings.monthlyAmount,
          lateFee: lateFee,
          totalPaid: group.settings.monthlyAmount + lateFee,
          paidAt: DateTime.now(),
          collectedBy: user.uid,
        );
        savingsList.add(saving);
      }
    }

    final success = await ref.read(savingsNotifierProvider.notifier).recordBulkSavings(
          groupId: group.id,
          savingsList: savingsList,
          performedBy: user.uid,
          performedByName: user.name,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${savingsList.length} सदस्यांचे बचत संकलन जतन केले!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('जतन करताना त्रुटी आली.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(currentGroupProvider).value;
    final members = ref.watch(approvedMembersProvider).value ?? [];
    final allSavings = ref.watch(groupSavingsProvider).value ?? [];

    // Filter savings for currently selected month and year
    final currentMonthSavings = allSavings
        .where((s) => s.month == _selectedMonth && s.year == _selectedYear)
        .toList();

    final paidUserIds = currentMonthSavings.map((s) => s.userId).toSet();

    final monthlyAmount = group?.settings.monthlyAmount ?? 100.0;
    final monthName = DateTimeExtensions.marathiMonths[_selectedMonth - 1];

    final totalCollected = currentMonthSavings.fold(0.0, (sum, s) => sum + s.totalPaid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('मासिक बचत संकलन'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '$monthName $_selectedYear',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  ),
                ],
              ),
            ),

            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('नियम दरमहा बचत', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('₹${monthlyAmount.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  Container(height: 36, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text('एकूण संकलन जमा', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('₹${totalCollected.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    ],
                  ),
                  Container(height: 36, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text('भरलेले सदस्य', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${paidUserIds.length} / ${members.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            // Member list with checkboxes
            Expanded(
              child: members.isEmpty
                  ? const Center(child: Text('या गटात अद्याप कोणतेही सदस्य नाहीत.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final alreadyPaid = paidUserIds.contains(member.uid);
                        final isChecked = alreadyPaid || (_paidMap[member.uid] ?? false);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: alreadyPaid ? Colors.green.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: alreadyPaid ? Colors.green.shade300 : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                activeColor: AppColors.primary,
                                onChanged: alreadyPaid
                                    ? null // already recorded in DB
                                    : (val) {
                                        setState(() {
                                          _paidMap[member.uid] = val ?? false;
                                        });
                                      },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'आधार: XXXX-${member.aadhaarLast4}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (alreadyPaid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'जमा झाले ✓',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  '₹${monthlyAmount.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Save Button
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: CustomButton(
                label: 'सर्व संकलन जतन करा (Save All)',
                icon: Icons.check_circle,
                isLoading: _isSaving,
                onPressed: _handleSaveAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
