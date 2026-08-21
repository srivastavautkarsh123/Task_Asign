import 'package:equatable/equatable.dart';

class NotificationItem extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String taskId;
  final String message;
  final bool read;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.taskId,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? type,
    String? taskId,
    String? message,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      taskId: taskId ?? this.taskId,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, taskId, message, read, createdAt];
}
