import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../data/models/loan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bank_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/savings_provider.dart';

class LeaderDashboard extends ConsumerWidget {
  const LeaderDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(currentGroupProvider).value;
    final user = ref.watch(currentUserProfileProvider).value;
    final pendingRequests = ref.watch(pendingRequestsProvider).value ?? [];
    final approvedMembers = ref.watch(approvedMembersProvider).value ?? [];
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);

    final totalSavings = ref.watch(totalGroupSavingsProvider);
    final totalLoans = ref.watch(totalOutstandingLoansProvider);
    final totalInterest = ref.watch(totalInterestEarnedProvider);
    final availableToLend = ref.watch(availableFundToLendProvider);
    final balances = ref.watch(currentBalancesProvider).value ?? {'bankBalance': 0.0, 'cashInHand': 0.0};
    final allLoans = ref.watch(groupLoansProvider).value ?? [];
    final allSavings = ref.watch(groupSavingsProvider).value ?? [];

    final bankBalance = balances['bankBalance'] ?? 0.0;
    final cashInHand = balances['cashInHand'] ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(group?.name ?? 'महिला बचत गट'),
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
            onPressed: () => context.push('/group-settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'लॉगआउट',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('लॉग आउट'),
                  content: const Text('तुम्हाला नक्की बाहेर पडायचे आहे का?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('नाही')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('होय')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              }
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
              // Welcome & Group Code Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'नमस्ते, ${user?.name ?? 'अध्यक्ष'}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'गाव: ${group?.village ?? ''} | सदस्य: ${group?.memberCount ?? 1}/${group?.settings.maxMembers ?? 11}',
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ),
                    if (group?.groupCode != null)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: group!.groupCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('गट कोड कॉपी केला!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                group!.groupCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy, size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Pending Requests Alert Banner
              if (pendingRequests.isNotEmpty) ...[
                InkWell(
                  onTap: () => context.push('/pending-requests'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade400),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notification_important, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${pendingRequests.length} नवीन सदस्य जोडणी विनंत्या प्रलंबित आहेत.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main Financial Overview Cards (2x2 Grid)
              const Text(
                'आर्थिक आढावा (Financial Overview)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'एकूण जमा बचत',
                      value: '₹${totalSavings.toStringAsFixed(0)}',
                      icon: Icons.savings,
                      color: AppColors.primary,
                      onTap: () => context.push('/savings-collection'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'बँकेत जमा रक्कम',
                      value: '₹${bankBalance.toStringAsFixed(0)}',
                      icon: Icons.account_balance,
                      color: const Color(0xFF1565C0),
                      onTap: () => context.push('/bank-book'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'हातातील रोख शिल्लक',
                      value: '₹${cashInHand.toStringAsFixed(0)}',
                      icon: Icons.payments,
                      color: const Color(0xFFE65100),
                      onTap: () => context.push('/bank-book'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'कर्ज देण्यासाठी शिल्लक',
                      value: '₹${availableToLend.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFF2E7D32),
                      onTap: () => context.push('/loan-management'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'सक्रिय कर्ज मुद्दल',
                      value: '₹${totalLoans.toStringAsFixed(0)}',
                      icon: Icons.monetization_on,
                      color: AppColors.secondary,
                      onTap: () => context.push('/loan-management'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'मिळालेले एकूण व्याज',
                      value: '₹${totalInterest.toStringAsFixed(0)}',
                      icon: Icons.trending_up,
                      color: const Color(0xFF00897B),
                      onTap: () => context.push('/loan-management'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Module Navigation Grid (2x3)
              const Text(
                'विभाग (Modules)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _buildNavTile(
                    icon: Icons.how_to_reg,
                    label: 'प्रलंबित विनंत्या',
                    badgeCount: pendingRequests.length,
                    color: Colors.orange,
                    onTap: () => context.push('/pending-requests'),
                  ),
                  _buildNavTile(
                    icon: Icons.playlist_add_check,
                    label: 'मासिक बचत संकलन',
                    color: AppColors.primary,
                    onTap: () => context.push('/savings-collection'),
                  ),
                  _buildNavTile(
                    icon: Icons.handshake,
                    label: 'कर्ज व्यवस्थापन',
                    color: AppColors.secondary,
                    onTap: () => context.push('/loan-management'),
                  ),
                  _buildNavTile(
                    icon: Icons.calendar_month,
                    label: 'मासिक बैठका',
                    color: Colors.teal,
                    onTap: () => context.push('/meeting'),
                  ),
                  _buildNavTile(
                    icon: Icons.menu_book,
                    label: 'बँक व रोख नोंद',
                    color: Colors.blue,
                    onTap: () => context.push('/bank-book'),
                  ),
                  _buildNavTile(
                    icon: Icons.picture_as_pdf,
                    label: 'अहवाल (PDF)',
                    color: Colors.purple,
                    onTap: () => context.push('/reports'),
                  ),
                  _buildNavTile(
                    icon: Icons.manage_accounts,
                    label: 'सदस्य व पदे',
                    color: Colors.indigo,
                    onTap: () => context.push('/members-list'),
                  ),
                  _buildNavTile(
                    icon: Icons.lock_clock,
                    label: 'ऑडिट नोंदवही',
                    color: Colors.brown,
                    onTap: () => context.push('/audit-logs'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Member-wise Table Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'सदस्यनिहाय माहिती तक्ता',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${approvedMembers.length} सदस्य',
                    style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.08)),
                    columns: const [
                      DataColumn(label: Text('नाव', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('बचत', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('कर्ज बाकी', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('भूमिका', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: approvedMembers.map((m) {
                      final memberSavings = allSavings
                          .where((s) => s.userId == m.uid)
                          .fold(0.0, (sum, s) => sum + s.totalPaid);

                      final memberActiveLoan = allLoans
                          .where((l) => l.userId == m.uid && (l.status == LoanStatus.active || l.status == LoanStatus.overdue))
                          .fold(0.0, (sum, l) => sum + l.outstandingPrincipal);

                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('XXXX-${m.aadhaarLast4}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          DataCell(Text('₹${memberSavings.toStringAsFixed(0)}')),
                          DataCell(
                            Text(
                              memberActiveLoan > 0 ? '₹${memberActiveLoan.toStringAsFixed(0)}' : '-',
                              style: TextStyle(
                                fontWeight: memberActiveLoan > 0 ? FontWeight.bold : FontWeight.normal,
                                color: memberActiveLoan > 0 ? AppColors.error : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: m.role.name == 'leader'
                                    ? AppColors.secondary.withOpacity(0.12)
                                    : AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                m.role.name == 'leader' ? 'अध्यक्ष' : 'सदस्य',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: m.role.name == 'leader' ? AppColors.secondary : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
