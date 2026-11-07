import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(userNotificationsProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('सूचना व संदेश (Notifications)'),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 14),
                  const Text('कोणत्याही नवीन सूचना नाहीत.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return InkWell(
                  onTap: () {
                    if (!notif.isRead) {
                      ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notif.isRead ? Colors.white : AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: notif.isRead ? AppColors.border : AppColors.primary.withOpacity(0.4),
                        width: notif.isRead ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getNotifColor(notif.type).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getNotifIcon(notif.type), color: _getNotifColor(notif.type), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.message,
                                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.3),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif.createdAt.toFormattedDateTime(),
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getNotifColor(NotificationType type) {
    switch (type) {
      case NotificationType.joinApproved:
      case NotificationType.loanApproved:
      case NotificationType.repaymentReceived:
        return AppColors.success;
      case NotificationType.joinRejected:
      case NotificationType.loanRejected:
        return AppColors.error;
      case NotificationType.meetingScheduled:
        return AppColors.secondary;
      case NotificationType.savingDueReminder:
        return Colors.orange;
    }
  }

  IconData _getNotifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.joinApproved:
        return Icons.how_to_reg;
      case NotificationType.loanApproved:
        return Icons.currency_rupee;
      case NotificationType.repaymentReceived:
        return Icons.receipt;
      case NotificationType.joinRejected:
      case NotificationType.loanRejected:
        return Icons.cancel;
      case NotificationType.meetingScheduled:
        return Icons.event;
      case NotificationType.savingDueReminder:
        return Icons.alarm;
    }
  }
}
