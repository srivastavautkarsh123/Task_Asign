import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assignment/core/constants/app_colors.dart';
import 'package:assignment/domain/entities/task.dart';
import 'package:assignment/presentation/providers/auth_provider.dart';
import 'package:assignment/presentation/providers/debug_settings_provider.dart';
import 'package:assignment/presentation/providers/notification_provider.dart';
import 'package:assignment/presentation/providers/project_provider.dart';
import 'package:assignment/presentation/providers/task_provider.dart';
import 'package:assignment/presentation/providers/theme_provider.dart';
import 'package:assignment/presentation/widgets/offline_banner.dart';
import 'package:assignment/presentation/screens/projects/project_list_screen.dart';
import 'package:assignment/presentation/screens/projects/project_detail_screen.dart';
import 'package:assignment/presentation/screens/tasks/task_list_screen.dart';
import 'package:assignment/presentation/screens/profile/profile_settings_screen.dart';
import 'package:assignment/presentation/screens/notifications/notifications_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final debugSettings = ref.watch(debugSettingsProvider);
    final projectState = ref.watch(projectListProvider);
    final taskState = ref.watch(taskListProvider);

    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = authState.session;
    final notifications = ref.watch(userNotificationsProvider(session.user.id));
    final unreadNotifsCount = notifications.where((n) => !n.read).length;

    List<TaskEntity> allTasks = [];
    if (taskState is TaskListSuccess) {
      allTasks = taskState.allTasks;
    }

    final todoCount = allTasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgressCount = allTasks.where((t) => t.status == TaskStatus.inProgress).length;
    final reviewCount = allTasks.where((t) => t.status == TaskStatus.review).length;
    final doneCount = allTasks.where((t) => t.status == TaskStatus.done).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.task_alt_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('TaskFlow', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Light/Dark Theme',
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              ref.read(themeModeProvider.notifier).toggleTheme(!isDark);
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NotificationsScreen(userId: session.user.id)),
                  );
                },
              ),
              if (unreadNotifsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadNotifsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (debugSettings.simulateOffline) const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(projectListProvider.notifier).loadProjects(session.orgId);
                ref.read(taskListProvider.notifier).loadTasksForOrg(session.orgId);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              backgroundImage: session.user.avatarUrl != null
                                  ? NetworkImage(session.user.avatarUrl!)
                                  : null,
                              child: session.user.avatarUrl == null
                                  ? Text(session.user.name[0], style: const TextStyle(fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.user.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    session.user.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: session.isAdmin
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.secondary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: session.isAdmin ? AppColors.primary : AppColors.secondary,
                                ),
                              ),
                              child: Text(
                                session.isAdmin ? 'Admin' : 'Member',
                                style: TextStyle(
                                  color: session.isAdmin ? AppColors.primary : AppColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Stats Section
                    const Text('Task Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'To Do',
                            count: todoCount,
                            color: AppColors.statusTodo,
                            icon: Icons.checklist_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            title: 'In Progress',
                            count: inProgressCount,
                            color: AppColors.statusInProgress,
                            icon: Icons.sync_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'In Review',
                            count: reviewCount,
                            color: AppColors.statusReview,
                            icon: Icons.rate_review_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            title: 'Completed',
                            count: doneCount,
                            color: AppColors.statusDone,
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Navigation Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProjectListScreen()),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Projects list summary preview
                    if (projectState is ProjectListSuccess) ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: projectState.projects.length > 3 ? 3 : projectState.projects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final project = projectState.projects[index];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.folder_outlined, color: AppColors.primary),
                              ),
                              title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                project.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Chip(
                                label: Text('${project.taskCount} Tasks', style: const TextStyle(fontSize: 11)),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ] else if (projectState is ProjectListLoading) ...[
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ] else ...[
                      const Text('No projects found.'),
                    ],

                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('Open Full Task Board & Filters'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TaskListScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
