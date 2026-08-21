import '../../core/utils/result.dart';
import '../entities/notification_item.dart';

abstract class INotificationRepository {
  Future<Result<List<NotificationItem>>> getNotificationsForUser(String userId);
  Future<Result<NotificationItem>> markAsRead(String notificationId);
  Future<Result<NotificationItem>> addNotification({
    required String userId,
    required String taskId,
    required String message,
  });
}
