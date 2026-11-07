import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import 'auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final userNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(notificationRepositoryProvider).getUserNotifications(user.uid);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(userNotificationsProvider).value ?? [];
  return list.where((n) => !n.isRead).length;
});
