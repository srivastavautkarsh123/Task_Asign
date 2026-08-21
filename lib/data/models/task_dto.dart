import '../../domain/entities/task.dart';

class TaskDto {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assigneeId;
  final String dueDate;
  final String createdAt;

  TaskDto({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    required this.dueDate,
    required this.createdAt,
  });

  factory TaskDto.fromJson(Map<String, dynamic> json) {
    return TaskDto(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      assigneeId: json['assignee_id'] as String?,
      dueDate: json['due_date'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assignee_id': assigneeId,
      'due_date': dueDate,
      'created_at': createdAt,
    };
  }

  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      status: TaskStatus.fromString(status),
      priority: TaskPriority.fromString(priority),
      assigneeId: assigneeId,
      dueDate: DateTime.parse(dueDate),
      createdAt: DateTime.parse(createdAt),
    );
  }

  factory TaskDto.fromEntity(TaskEntity entity) {
    return TaskDto(
      id: entity.id,
      projectId: entity.projectId,
      title: entity.title,
      description: entity.description,
      status: entity.status.value,
      priority: entity.priority.value,
      assigneeId: entity.assigneeId,
      dueDate: entity.dueDate.toIso8601String().split('T').first,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
