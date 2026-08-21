import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assignment/data/datasources/mock_data_source.dart';
import 'package:assignment/data/datasources/local_storage_data_source.dart';
import 'package:assignment/data/repositories/task_repository_impl.dart';
import 'package:assignment/domain/entities/user.dart';
import 'package:assignment/domain/entities/org_member.dart';
import 'package:assignment/domain/entities/user_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDataSource mockDataSource;
  late LocalStorageDataSource localStorage;
  late TaskRepositoryImpl taskRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDataSource = MockDataSource();
    localStorage = LocalStorageDataSource();
    taskRepository = TaskRepositoryImpl(
      mockDataSource: mockDataSource,
      localStorage: localStorage,
    );
  });

  group('TaskRepositoryImpl Unit Tests', () {
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
      final sessionOrgA = UserSession(
        user: const User(id: 'user_001', name: 'Aditya', email: 'aditya.admin@nimbusdigital.test'),
        memberInfo: const OrgMember(orgId: 'org_a1b2c3', userId: 'user_001', role: OrgRole.orgAdmin),
        accessToken: 'token',
        refreshToken: 'rtoken',
        accessTokenExpiry: DateTime.now().add(const Duration(minutes: 15)),
      );

      final assignRes = await taskRepository.assignTaskUser(sessionOrgA, 'task_2001', 'user_004');
      expect(assignRes.isFailure, isTrue);
      expect(assignRes.failureOrNull?.message, contains('Assignee does not belong to the active organization'));
    });
  });
}
