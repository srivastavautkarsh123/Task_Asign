import '../../domain/entities/notification_item.dart';

class NotificationDto {
  final String id;
  final String userId;
  final String type;
  final String taskId;
  final String message;
  final bool read;
  final String createdAt;

  NotificationDto({
    required this.id,
    required this.userId,
    required this.type,
    required this.taskId,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      taskId: json['task_id'] as String,
      message: json['message'] as String,
      read: json['read'] as bool,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'task_id': taskId,
      'message': message,
      'read': read,
      'created_at': createdAt,
    };
  }

  NotificationItem toEntity() {
    return NotificationItem(
      id: id,
      userId: userId,
      type: type,
      taskId: taskId,
      message: message,
      read: read,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
