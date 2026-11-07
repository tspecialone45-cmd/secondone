import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';

class PendingRequestsScreen extends ConsumerWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequests = ref.watch(pendingRequestsProvider).value ?? [];
    final group = ref.watch(currentGroupProvider).value;
    final user = ref.watch(currentUserProfileProvider).value;

    final isFull = (group?.memberCount ?? 0) >= (group?.settings.maxMembers ?? 11);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('प्रलंबित विनंत्या (Join Requests)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Capacity Alert Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isFull ? Colors.red.shade50 : Colors.green.shade50,
              child: Row(
                children: [
                  Icon(
                    isFull ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: isFull ? Colors.red : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'गट क्षमता: ${group?.memberCount ?? 0} / ${group?.settings.maxMembers ?? 11} सदस्य ${isFull ? '(गट पूर्ण झाला आहे!)' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFull ? Colors.red.shade900 : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: pendingRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'कोणत्याही प्रलंबित विनंत्या नाहीत.',
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingRequests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = pendingRequests[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                    child: Text(
                                      req.userName.isNotEmpty ? req.userName[0] : 'म',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.userName,
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'मोबाईल: +91 ${req.userPhone}',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'विनंती दिनांक: ${req.requestedAt.toFormattedDate()}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        if (user == null || group == null) return;
                                        await ref.read(groupNotifierProvider.notifier).rejectMember(
                                              membershipId: req.id,
                                              groupId: group.id,
                                              userId: req.userId,
                                              respondedBy: user.uid,
                                              respondedByName: user.name,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('विनंती नाकारली.')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                                      label: const Text('नाकारा', style: TextStyle(color: AppColors.error)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.error),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: isFull
                                          ? null
                                          : () async {
                                              if (user == null || group == null) return;
                                              final success = await ref
                                                  .read(groupNotifierProvider.notifier)
                                                  .approveMember(
                                                    membershipId: req.id,
                                                    groupId: group.id,
                                                    userId: req.userId,
                                                    respondedBy: user.uid,
                                                    respondedByName: user.name,
                                                  );

                                              if (context.mounted) {
                                                if (success) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('सदस्य यशस्वीरित्या मंजूर केला!'),
                                                      backgroundColor: AppColors.success,
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('मंजूर करण्यात अयशस्वी. गट क्षमता पूर्ण झाली असावी.'),
                                                      backgroundColor: AppColors.error,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('मंजूर करा'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
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
