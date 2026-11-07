import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/audit_log_model.dart';
import '../../providers/group_provider.dart';

final auditLogsProvider = StreamProvider<List<AuditLogModel>>((ref) {
  final group = ref.watch(currentGroupProvider).value;
  if (group == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('auditLogs')
      .where('groupId', isEqualTo: group.id)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => AuditLogModel.fromFirestore(doc)).toList());
});

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogs = ref.watch(auditLogsProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ऑडिट नोंदवही (Audit Log)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.amber.shade50,
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.brown, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'पारदर्शकता नियम: या नोंदी कायमस्वरूपी सुरक्षित असून कोणालाही डिलीट किंवा बदलता येत नाहीत.',
                      style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: auditLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          const Text('अद्याप कोणत्याही नोंदी नाहीत.', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: auditLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final log = auditLogs[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getActionColor(log.action).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getActionLabel(log.action),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getActionColor(log.action),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    log.timestamp.toFormattedDateTime(),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'नोंद करणारे: ${log.performedByName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'घटक: ${log.targetType}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              if (log.newValue != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'तपशील: ${log.newValue.toString()}',
                                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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

  String _getActionLabel(String action) {
    switch (action) {
      case 'CREATE_GROUP':
        return 'गट निर्मिती';
      case 'RECORD_SAVING':
      case 'BULK_RECORD_SAVINGS':
        return 'बचत संकलन';
      case 'APPROVE_LOAN':
        return 'कर्ज मंजुरी';
      case 'REJECT_LOAN':
        return 'कर्ज नकार';
      case 'RECORD_REPAYMENT':
        return 'हप्ता परतफेड';
      case 'APPROVE_MEMBER':
        return 'सदस्य मंजुरी';
      case 'REJECT_MEMBER':
        return 'सदस्य नकार';
      case 'RECORD_TRANSACTION':
        return 'बँक/रोख व्यवहार';
      case 'UPDATE_SETTINGS':
        return 'नियम बदल';
      case 'MARK_ATTENDANCE':
        return 'हजेरी नोंद';
      case 'UPDATE_MINUTES':
        return 'इतिवृत्त नोंद';
      default:
        return action;
    }
  }

  Color _getActionColor(String action) {
    if (action.contains('APPROVE') || action.contains('RECORD')) {
      return AppColors.primary;
    } else if (action.contains('REJECT')) {
      return AppColors.error;
    }
    return AppColors.secondary;
  }
}
