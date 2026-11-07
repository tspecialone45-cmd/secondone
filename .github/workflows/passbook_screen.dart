import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/savings_provider.dart';

class PassbookScreen extends ConsumerWidget {
  const PassbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final group = ref.watch(currentGroupProvider).value;

    final mySavings = ref.watch(memberSavingsProvider(user?.uid ?? '')).value ?? [];
    final myLoans = ref.watch(memberLoansProvider(user?.uid ?? '')).value ?? [];
    final totalSaved = mySavings.fold(0.0, (sum, s) => sum + s.totalPaid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('माझे पासबुक (Passbook)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'शेअर करा (WhatsApp)',
            onPressed: () async {
              if (user == null || group == null) return;
              try {
                final pdfBytes = await PdfGenerator.generatePassbookPdf(
                  member: user,
                  group: group,
                  savings: mySavings,
                  memberLoans: myLoans,
                );
                await PdfGenerator.sharePdf(
                  pdfBytes: pdfBytes,
                  filename: 'Passbook_${user.name}.pdf',
                  text: '${group.name} - ${user.name} पासबुक',
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF तयार करताना त्रुटी: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Passbook Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFF4A148C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.secondary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'XXXX-${user?.aadhaarLast4 ?? ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('गट: ${group?.name ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('एकूण जमा बचत:', style: TextStyle(color: Colors.white70)),
                      Text(
                        '₹${totalSaved.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Month-wise Savings List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('महिनानिहाय बचत इतिहास', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${mySavings.length} महिने जमा', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: mySavings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('अद्याप कोणतीही बचत जमा नोंदवलेली नाही.'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: mySavings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = mySavings[index];
                        final monthName = s.month >= 1 && s.month <= 12
                            ? DateTimeExtensions.marathiMonths[s.month - 1]
                            : '${s.month}';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.green, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$monthName ${s.year}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'पावती दिनांक: ${s.paidAt.toFormattedDate()}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${s.totalPaid.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  if (s.lateFee > 0)
                                    Text(
                                      '(दंड ₹${s.lateFee.toStringAsFixed(0)})',
                                      style: const TextStyle(fontSize: 11, color: AppColors.error),
                                    ),
                                ],
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
}
