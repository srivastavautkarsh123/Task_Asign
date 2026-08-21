import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assignment/data/datasources/mock_data_source.dart';
import 'package:assignment/data/datasources/local_storage_data_source.dart';
import 'package:assignment/data/repositories/task_repository_impl.dart';
import 'package:assignment/data/repositories/notification_repository_impl.dart';
import 'package:assignment/domain/entities/task.dart';
import 'package:assignment/domain/entities/user.dart';
import 'package:assignment/domain/entities/org_member.dart';
import 'package:assignment/domain/entities/user_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDataSource mockDataSource;
  late LocalStorageDataSource localStorage;
  late NotificationRepositoryImpl notificationRepository;
  late TaskRepositoryImpl taskRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDataSource = MockDataSource();
    localStorage = LocalStorageDataSource();
    notificationRepository = NotificationRepositoryImpl(mockDataSource: mockDataSource);
    taskRepository = TaskRepositoryImpl(
      mockDataSource: mockDataSource,
      localStorage: localStorage,
      notificationRepository: notificationRepository,
    );
  });

  group('TaskRepositoryImpl Unit Tests', () {
    final sessionOrgA = UserSession(
      user: const User(id: 'user_001', name: 'Aditya', email: 'aditya.admin@nimbusdigital.test'),
      memberInfo: const OrgMember(orgId: 'org_a1b2c3', userId: 'user_001', role: OrgRole.orgAdmin),
      accessToken: 'token',
      refreshToken: 'rtoken',
      accessTokenExpiry: DateTime.now().add(const Duration(minutes: 15)),
    );

    test('getTasksForOrg returns only tasks scoped to projects of org_a1b2c3', () async {
      final res = await taskRepository.getTasksForOrg('org_a1b2c3');
      expect(res.isSuccess, isTrue);
      final tasks = res.dataOrNull!;
      expect(tasks, isNotEmpty);
      for (final t in tasks) {
        expect(['proj_1001', 'proj_1002'].contains(t.projectId), isTrue);
      }
    });

    test('prevent assigning user to a task if user does NOT belong to the active org', () async {
      final assignRes = await taskRepository.assignTaskUser(sessionOrgA, 'task_2001', 'user_004');
      expect(assignRes.isFailure, isTrue);
      expect(assignRes.failureOrNull?.message, contains('Assignee does not belong to the active organization'));
    });

    test('prevent selecting past due date when creating a task', () async {
      final pastTask = TaskEntity(
        id: 'task_past_01',
        projectId: 'proj_1001',
        title: 'Past Task',
        description: 'Testing past date restriction',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now(),
      );

      final res = await taskRepository.createTask(sessionOrgA, pastTask);
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull?.message, contains('Task due date cannot be in the past'));
    });

    test('assigning task to Ramesh dynamically creates a notification for Ramesh', () async {
      // Assign task_2005 (currently unassigned) to Ramesh (user_002)
      final assignRes = await taskRepository.assignTaskUser(sessionOrgA, 'task_2005', 'user_002');
      expect(assignRes.isSuccess, isTrue);

      // Check Ramesh's notifications
      final notifRes = await notificationRepository.getNotificationsForUser('user_002');
      expect(notifRes.isSuccess, isTrue);
      final notifs = notifRes.dataOrNull!;
      expect(notifs.any((n) => n.message.contains('Aditya assigned you to')), isTrue);
    });
  });
}
