import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/errors/failures.dart';
import '../models/organization_dto.dart';
import '../models/user_dto.dart';
import '../models/org_member_dto.dart';
import '../models/project_dto.dart';
import '../models/task_dto.dart';
import '../models/comment_dto.dart';
import '../models/notification_dto.dart';
import '../models/auth_mock_dto.dart';

class MockDataSource {
  bool simulate404 = false;
  bool simulateTimeout = false;
  bool simulateValidationError = false;
  bool simulateOffline = false;
  int artificialDelayMs = 400;

  Map<String, dynamic>? _rawJson;

  List<OrganizationDto> organizations = [];
  List<UserDto> users = [];
  List<OrgMemberDto> orgMembers = [];
  List<ProjectDto> projects = [];
  List<TaskDto> tasks = [];
  List<CommentDto> comments = [];
  List<NotificationDto> notifications = [];
  List<TestCredentialDto> testCredentials = [];
  MockLoginResponseDto? mockLoginResponse;

  Future<void> init() async {
    if (_rawJson != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/mock_data/TaskFlow-MockData.json');
      _rawJson = jsonDecode(jsonString) as Map<String, dynamic>;
      _parseRawData();
    } catch (e) {
      throw ServerFailure("Failed to load mock data JSON asset: $e");
    }
  }

  void _parseRawData() {
    final rawMap = _rawJson!;
    organizations = (rawMap['organizations'] as List).map((e) => OrganizationDto.fromJson(e)).toList();
    users = (rawMap['users'] as List).map((e) => UserDto.fromJson(e)).toList();
    orgMembers = (rawMap['org_members'] as List).map((e) => OrgMemberDto.fromJson(e)).toList();
    projects = (rawMap['projects'] as List).map((e) => ProjectDto.fromJson(e)).toList();
    tasks = (rawMap['tasks'] as List).map((e) => TaskDto.fromJson(e)).toList();
    comments = (rawMap['comments'] as List).map((e) => CommentDto.fromJson(e)).toList();
    notifications = (rawMap['notifications'] as List).map((e) => NotificationDto.fromJson(e)).toList();

    final authMock = rawMap['auth_mock'] as Map<String, dynamic>;
    testCredentials = (authMock['test_credentials'] as List).map((e) => TestCredentialDto.fromJson(e)).toList();
    mockLoginResponse = MockLoginResponseDto.fromJson(authMock['mock_login_response'] as Map<String, dynamic>);
  }

  Future<void> _simulateNetworkEffects() async {
    if (simulateOffline) {
      throw const OfflineFailure("Offline mode enabled in settings.");
    }
    if (simulateTimeout) {
      await Future.delayed(Duration(milliseconds: artificialDelayMs));
      throw const NetworkTimeoutFailure("Simulated network timeout reached.");
    }
    if (artificialDelayMs > 0) {
      await Future.delayed(Duration(milliseconds: artificialDelayMs));
    }
    if (simulate404) {
      throw const NotFoundFailure("Simulated 404: Resource not found.");
    }
    if (simulateValidationError) {
      throw const ValidationError(
        "Simulated validation error.",
        fieldErrors: {'input': 'The provided payload failed simulated validation checks.'},
      );
    }
  }

  // --- Data Access Methods ---

  Future<List<OrganizationDto>> getOrganizations() async {
    await init();
    await _simulateNetworkEffects();
    return organizations;
  }

  Future<List<UserDto>> getUsers() async {
    await init();
    await _simulateNetworkEffects();
    return users;
  }

  Future<List<OrgMemberDto>> getOrgMembers() async {
    await init();
    await _simulateNetworkEffects();
    return orgMembers;
  }

  Future<List<ProjectDto>> getProjects() async {
    await init();
    await _simulateNetworkEffects();
    return projects;
  }

  Future<List<TaskDto>> getTasks() async {
    await init();
    await _simulateNetworkEffects();
    return tasks;
  }

  Future<List<CommentDto>> getComments() async {
    await init();
    await _simulateNetworkEffects();
    return comments;
  }

  Future<List<NotificationDto>> getNotifications() async {
    await init();
    await _simulateNetworkEffects();
    return notifications;
  }

  Future<List<TestCredentialDto>> getTestCredentials() async {
    await init();
    return testCredentials;
  }

  Future<MockLoginResponseDto> getMockLoginResponse() async {
    await init();
    return mockLoginResponse!;
  }
}
