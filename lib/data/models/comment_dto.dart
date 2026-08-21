import '../../domain/entities/comment.dart';

class CommentDto {
  final String id;
  final String taskId;
  final String authorId;
  final String body;
  final String createdAt;

  CommentDto({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    return CommentDto(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      authorId: json['author_id'] as String,
      body: json['body'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'author_id': authorId,
      'body': body,
      'created_at': createdAt,
    };
  }

  Comment toEntity() {
    return Comment(
      id: id,
      taskId: taskId,
      authorId: authorId,
      body: body,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
