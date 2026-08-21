import '../../domain/entities/project.dart';

class ProjectDto {
  final String id;
  final String orgId;
  final String name;
  final String description;
  final int taskCount;
  final String status;
  final String createdAt;

  ProjectDto({
    required this.id,
    required this.orgId,
    required this.name,
    required this.description,
    required this.taskCount,
    required this.status,
    required this.createdAt,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    return ProjectDto(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      taskCount: json['task_count'] as int,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'org_id': orgId,
      'name': name,
      'description': description,
      'task_count': taskCount,
      'status': status,
      'created_at': createdAt,
    };
  }

  Project toEntity() {
    return Project(
      id: id,
      orgId: orgId,
      name: name,
      description: description,
      taskCount: taskCount,
      status: status,
      createdAt: DateTime.parse(createdAt),
    );
  }

  factory ProjectDto.fromEntity(Project entity) {
    return ProjectDto(
      id: entity.id,
      orgId: entity.orgId,
      name: entity.name,
      description: entity.description,
      taskCount: entity.taskCount,
      status: entity.status,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
