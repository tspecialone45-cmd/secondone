import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';

class MeetingHistoryScreen extends ConsumerWidget {
  const MeetingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final meetings = ref.watch(groupMeetingsProvider).value ?? [];
    final statsAsync = ref.watch(memberAttendanceStatsProvider(user?.uid ?? ''));

    final stats = statsAsync.value ?? {'total': 0, 'attended': 0, 'percentage': 100.0};
    final total = stats['total'] as int? ?? 0;
    final attended = stats['attended'] as int? ?? 0;
    final percentage = (stats['percentage'] as num?)?.toDouble() ?? 100.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('माझी बैठक हजेरी (Attendance)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Attendance Percentage Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: total > 0 ? (attended / total) : 1.0,
                          strokeWidth: 7,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('एकूण उपस्थिती प्रमाण', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          '$total पैकी $attended बैठकांना उपस्थित',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          percentage >= 80 ? 'उत्कृष्ट हजेरी! 👏' : 'नियमित उपस्थिती राखा.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: percentage >= 80 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Meetings List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('बैठक तपशील व इतिवृत्त', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${meetings.length} बैठका', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: meetings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('अद्याप कोणत्याही बैठका झालेल्या नाहीत.'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: meetings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final m = meetings[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        m.date.toFormattedDate(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  Text(m.time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('ठिकाण: ${m.place}', style: const TextStyle(fontSize: 13)),
                              Text('अजेंडा: ${m.agenda}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              if (m.minutes != null && m.minutes!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('बैठकीचे इतिवृत्त:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(m.minutes!, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
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
