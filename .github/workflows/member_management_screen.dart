import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/audit_logger.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';

class MemberManagementScreen extends ConsumerWidget {
  const MemberManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(currentGroupProvider).value;
    final members = ref.watch(approvedMembersProvider).value ?? [];
    final currentUser = ref.watch(currentUserProfileProvider).value;

    final isLeader = currentUser?.role == UserRole.leader;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('गट सदस्य व भूमिका (Members & Roles)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('एकूण नोंदणीकृत सदस्य', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        '${members.length} / ${group?.settings.maxMembers ?? 11} (कमाल मर्यादा)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('१ अध्यक्ष • १ उपाध्यक्ष', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.secondary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final m = members[index];
                  final isThisUserLeader = m.role == UserRole.leader;
                  final isThisUserDeputy = m.role == UserRole.deputy;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isThisUserLeader
                            ? AppColors.secondary
                            : isThisUserDeputy
                                ? Colors.teal
                                : AppColors.border,
                        width: (isThisUserLeader || isThisUserDeputy) ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isThisUserLeader
                              ? AppColors.secondary.withOpacity(0.12)
                              : isThisUserDeputy
                                  ? Colors.teal.withOpacity(0.12)
                                  : AppColors.primary.withOpacity(0.12),
                          child: Text(
                            m.name.isNotEmpty ? m.name[0] : 'म',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isThisUserLeader
                                  ? AppColors.secondary
                                  : isThisUserDeputy
                                      ? Colors.teal
                                      : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isThisUserLeader
                                          ? AppColors.secondary.withOpacity(0.12)
                                          : isThisUserDeputy
                                              ? Colors.teal.withOpacity(0.12)
                                              : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isThisUserLeader
                                          ? 'अध्यक्ष'
                                          : isThisUserDeputy
                                              ? 'उपाध्यक्ष'
                                              : 'सदस्य',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isThisUserLeader
                                            ? AppColors.secondary
                                            : isThisUserDeputy
                                                ? Colors.teal
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('+91 ${m.phone}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text('आधार: XXXX-${m.aadhaarLast4} | गाव: ${m.village}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                            ],
                          ),
                        ),

                        // Promote/Demote option for Leader
                        if (isLeader && !isThisUserLeader)
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (group == null || currentUser == null) return;
                              final newRole = value == 'deputy' ? UserRole.deputy : UserRole.member;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(m.uid)
                                  .update({'role': newRole.name});

                              if (value == 'deputy') {
                                await FirebaseFirestore.instance
                                    .collection('groups')
                                    .doc(group.id)
                                    .update({'deputyUid': m.uid});
                              }

                              await AuditLogger.log(
                                groupId: group.id,
                                action: 'CHANGE_ROLE',
                                performedBy: currentUser.uid,
                                performedByName: currentUser.name,
                                targetId: m.uid,
                                targetType: 'user_role',
                                newValue: {'role': newRole.name, 'name': m.name},
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${m.name} यांची भूमिका बदलली: ${value == 'deputy' ? 'उपाध्यक्ष' : 'सदस्य'}'),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (ctx) => [
                              if (!isThisUserDeputy)
                                const PopupMenuItem(
                                  value: 'deputy',
                                  child: Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.teal, size: 20),
                                      SizedBox(width: 8),
                                      Text('उपाध्यक्ष बनवा'),
                                    ],
                                  ),
                                )
                              else
                                const PopupMenuItem(
                                  value: 'member',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, color: AppColors.primary, size: 20),
                                      SizedBox(width: 8),
                                      Text('सदस्य बनवा'),
                                    ],
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
