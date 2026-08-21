import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_dto.dart';
import '../models/task_dto.dart';

class LocalStorageDataSource {
  static const String _keyProjects = 'cached_projects';
  static const String _keyTasks = 'cached_tasks';
  static const String _keyPendingMutations = 'pending_mutations';

  Future<void> saveProjects(List<ProjectDto> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = projects.map((p) => p.toJson()).toList();
    await prefs.setString(_keyProjects, jsonEncode(jsonList));
  }

  Future<List<ProjectDto>?> getCachedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProjects);
    if (raw == null) return null;
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => ProjectDto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTasks(List<TaskDto> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_keyTasks, jsonEncode(jsonList));
  }

  Future<List<TaskDto>?> getCachedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTasks);
    if (raw == null) return null;
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => TaskDto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> queuePendingMutation(Map<String, dynamic> action) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getPendingMutations();
    current.add(action);
    await prefs.setString(_keyPendingMutations, jsonEncode(current));
  }

  Future<List<Map<String, dynamic>>> getPendingMutations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingMutations);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearPendingMutations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingMutations);
  }
}
