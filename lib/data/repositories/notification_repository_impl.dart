import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../datasources/mock_data_source.dart';
import '../models/notification_dto.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final MockDataSource _mockDataSource;
  List<NotificationDto>? _inMemoryNotifications;

  NotificationRepositoryImpl({required MockDataSource mockDataSource})
      : _mockDataSource = mockDataSource;

  Future<void> _ensureLoaded() async {
    if (_inMemoryNotifications == null) {
      final list = await _mockDataSource.getNotifications();
      _inMemoryNotifications = List.from(list);
    }
  }

  @override
  Future<Result<List<NotificationItem>>> getNotificationsForUser(String userId) async {
    try {
      await _ensureLoaded();
      final filtered = _inMemoryNotifications!
          .where((n) => n.userId == userId)
          .map((n) => n.toEntity())
          .toList();
      return Success(filtered);
    } catch (e) {
      return Error(ServerFailure("Failed to load notifications: $e"));
    }
  }

  @override
  Future<Result<NotificationItem>> markAsRead(String notificationId) async {
    try {
      await _ensureLoaded();
      final index = _inMemoryNotifications!.indexWhere((n) => n.id == notificationId);
      if (index == -1) return const Error(NotFoundFailure("Notification not found."));

      final current = _inMemoryNotifications![index];
      final updated = NotificationDto(
        id: current.id,
        userId: current.userId,
        type: current.type,
        taskId: current.taskId,
        message: current.message,
        read: true,
        createdAt: current.createdAt,
      );
      _inMemoryNotifications![index] = updated;

      return Success(updated.toEntity());
    } catch (e) {
      return Error(ServerFailure("Failed to update notification: $e"));
    }
  }

  @override
  Future<Result<NotificationItem>> addNotification({
    required String userId,
    required String taskId,
    required String message,
  }) async {
    try {
      await _ensureLoaded();
      final newNotif = NotificationDto(
        id: "notif_${DateTime.now().millisecondsSinceEpoch}",
        userId: userId,
        type: "task_assigned",
        taskId: taskId,
        message: message,
        read: false,
        createdAt: DateTime.now().toIso8601String(),
      );
      _inMemoryNotifications!.insert(0, newNotif);
      return Success(newNotif.toEntity());
    } catch (e) {
      return Error(ServerFailure("Failed to create notification: $e"));
    }
  }
}
