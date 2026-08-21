import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String taskId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, taskId, authorId, body, createdAt];
}
