import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../data/models/loan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/savings_provider.dart';

class MemberDashboard extends ConsumerWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final group = ref.watch(currentGroupProvider).value;
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);

    final mySavings = ref.watch(myTotalSavingsProvider);
    final myLoans = ref.watch(memberLoansProvider(user?.uid ?? '')).value ?? [];

    final activeLoan = myLoans.cast<LoanModel?>().firstWhere(
          (l) => l?.status == LoanStatus.active || l?.status == LoanStatus.overdue,
          orElse: () => null,
        );

    final myOutstandingLoan = activeLoan?.outstandingPrincipal ?? 0.0;
    final myInterestPaid = myLoans.fold(0.0, (sum, l) => sum + l.totalInterestPaid);
    final nextDueDate = activeLoan?.nextDueDate;

    // Read-only group summary figures
    final totalGroupSavings = ref.watch(totalGroupSavingsProvider);
    final totalGroupLoans = ref.watch(totalOutstandingLoansProvider);
    final groupAllLoans = ref.watch(groupLoansProvider).value ?? [];
    final activeGroupLoans = groupAllLoans
        .where((l) => l.status == LoanStatus.active || l.status == LoanStatus.overdue)
        .toList();

    final balances = ref.watch(currentBalancesProvider).value ?? {'bankBalance': 0.0, 'cashInHand': 0.0};
    final bankBalance = balances['bankBalance'] ?? 0.0;
    final cashInHand = balances['cashInHand'] ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(group?.name ?? 'माझे बचत गट खाते'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'सूचना',
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadNotifCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '$unreadNotifCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'सेटिंग्ज',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'लॉगआउट',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(currentGroupProvider);
          ref.refresh(groupSavingsProvider);
          ref.refresh(groupLoansProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Member Profile Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0] : 'म',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'सदस्य',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'आधार: XXXX-${user?.aadhaarLast4 ?? '****'}',
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                          ),
                          Text(
                            'गाव: ${user?.village ?? ''}',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // My Personal Stats Cards (2x2 Grid)
              const Text(
                'माझा वैयक्तिक हिशोब (My Summary)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'माझी एकूण जमा बचत',
                      value: '₹${mySavings.toStringAsFixed(0)}',
                      icon: Icons.savings,
                      color: AppColors.primary,
                      onTap: () => context.push('/passbook'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'माझे चालू कर्ज बाकी',
                      value: '₹${myOutstandingLoan.toStringAsFixed(0)}',
                      icon: Icons.monetization_on,
                      color: myOutstandingLoan > 0 ? AppColors.secondary : Colors.grey,
                      onTap: () => context.push('/apply-loan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'मी भरलेले एकूण व्याज',
                      value: '₹${myInterestPaid.toStringAsFixed(0)}',
                      icon: Icons.trending_up,
                      color: const Color(0xFF00897B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'पुढील हप्ता तारीख',
                      value: nextDueDate != null ? nextDueDate.toFormattedDate() : 'लागू नाही',
                      icon: Icons.event,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/passbook'),
                      icon: const Icon(Icons.book),
                      label: const Text('माझे पासबुक'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/apply-loan'),
                      icon: const Icon(Icons.currency_rupee),
                      label: const Text('कर्ज अर्ज करा'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.push('/meeting-history'),
                icon: const Icon(Icons.how_to_reg),
                label: const Text('माझी बैठक हजेरी'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 28),

              // Read-only Group Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.visibility, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'बचत गट पारदर्शक माहिती (Group Summary)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('गटाची एकूण जमा बचत:', style: TextStyle(color: AppColors.textSecondary)),
                        Text('₹${totalGroupSavings.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('बँक शिल्लक:', style: TextStyle(color: AppColors.textSecondary)),
                        Text('₹${bankBalance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('हातातील रोख शिल्लक:', style: TextStyle(color: AppColors.textSecondary)),
                        Text('₹${cashInHand.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('एकूण दिलेले कर्ज बाकी:', style: TextStyle(color: AppColors.textSecondary)),
                        Text('₹${totalGroupLoans.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'कर्ज घेतलेले सदस्य (Who has taken loans):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    if (activeGroupLoans.isEmpty)
                      const Text('सध्या कोणाकडेही कर्ज बाकी नाही.', style: TextStyle(fontSize: 13, color: AppColors.textLight))
                    else
                      ...activeGroupLoans.map(
                        (l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('• ${l.memberName}', style: const TextStyle(fontSize: 14)),
                              Text('₹${l.outstandingPrincipal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
