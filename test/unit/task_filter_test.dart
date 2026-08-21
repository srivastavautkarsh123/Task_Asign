import 'package:flutter_test/flutter_test.dart';
import 'package:assignment/domain/entities/task.dart';
import 'package:assignment/presentation/providers/task_provider.dart';

void main() {
  final sampleTasks = [
    TaskEntity(
      id: 'task_1',
      projectId: 'proj_1',
      title: 'Fix auth bug',
      description: 'Fixing login form validation',
      status: TaskStatus.todo,
      priority: TaskPriority.urgent,
      assigneeId: 'user_001',
      dueDate: DateTime(2026, 1, 10),
      createdAt: DateTime(2026, 1, 1),
    ),
    TaskEntity(
      id: 'task_2',
      projectId: 'proj_1',
      title: 'Design tokens in Figma',
      description: 'Colors and typography',
      status: TaskStatus.done,
      priority: TaskPriority.low,
      assigneeId: 'user_002',
      dueDate: DateTime(2026, 2, 10),
      createdAt: DateTime(2026, 1, 2),
    ),
  ];

  group('Task Filtering Logic Unit Tests', () {
    test('filters tasks by status', () {
      final filter = const TaskFilterState(statusFilter: TaskStatus.done);
      final filtered = sampleTasks.where((t) => t.status == filter.statusFilter).toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('task_2'));
    });

    test('filters tasks by priority', () {
      final filter = const TaskFilterState(priorityFilter: TaskPriority.urgent);
      final filtered = sampleTasks.where((t) => t.priority == filter.priorityFilter).toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('task_1'));
    });

    test('filters tasks by search query', () {
      const query = 'Figma';
      final filtered = sampleTasks
          .where((t) => t.title.contains(query) || t.description.contains(query))
          .toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.title, contains('Design tokens'));
    });
  });
}
