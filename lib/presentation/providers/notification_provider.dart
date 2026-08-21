import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/i_notification_repository.dart';
import 'debug_settings_provider.dart';

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  final mockDs = ref.watch(mockDataSourceProvider);
  return NotificationRepositoryImpl(mockDataSource: mockDs);
});

final userNotificationsProvider = StateNotifierProvider.family<UserNotificationsNotifier, List<NotificationItem>, String>((ref, userId) {
  final repo = ref.watch(notificationRepositoryProvider);
  return UserNotificationsNotifier(repo, userId);
});

class UserNotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  final INotificationRepository _repository;
  final String userId;

  UserNotificationsNotifier(this._repository, this.userId) : super([]) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final res = await _repository.getNotificationsForUser(userId);
    res.fold((items) => state = items, (_) => null);
  }

  Future<void> markRead(String notificationId) async {
    final res = await _repository.markAsRead(notificationId);
    res.fold((updated) {
      state = [
        for (final item in state)
          if (item.id == notificationId) updated else item
      ];
    }, (_) => null);
  }
}
