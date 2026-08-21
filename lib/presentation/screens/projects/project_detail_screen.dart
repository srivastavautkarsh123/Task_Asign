import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assignment/core/constants/app_colors.dart';
import 'package:assignment/domain/entities/project.dart';
import 'package:assignment/domain/entities/task.dart';
import 'package:assignment/presentation/providers/auth_provider.dart';
import 'package:assignment/presentation/providers/project_provider.dart';
import 'package:assignment/presentation/providers/task_provider.dart';
import 'package:assignment/presentation/widgets/confirm_dialog.dart';
import 'package:assignment/presentation/widgets/priority_badge.dart';
import 'package:assignment/presentation/widgets/status_badge.dart';
import 'package:assignment/presentation/widgets/empty_state_widget.dart';
import 'package:assignment/presentation/widgets/error_state_widget.dart';
import 'package:assignment/presentation/widgets/skeleton_loader.dart';
import 'package:assignment/presentation/screens/tasks/task_detail_screen.dart';
import 'package:assignment/presentation/screens/tasks/create_edit_task_screen.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskListProvider.notifier).loadTasksForProject(widget.project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final taskState = ref.watch(taskListProvider);

    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = authState.session;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          if (session.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Delete Project?',
                  content: 'Are you sure you want to delete "${widget.project.name}"?',
                  isDanger: true,
                );
                if (confirm == true) {
                  final err = await ref.read(projectListProvider.notifier).deleteProject(session, widget.project.id);
                  if (mounted) {
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
                    } else {
                      Navigator.of(context).pop();
                    }
                  }
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CreateEditTaskScreen(projectId: widget.project.id)),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(taskListProvider.notifier).loadTasksForProject(widget.project.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text('Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.project.status.toUpperCase(),
                              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(widget.project.description),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (taskState is TaskListSuccess) ...[
                _buildStatusSummaryGrid(context, taskState.allTasks),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Project Tasks (${taskState.filteredTasks.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: taskState.filteredTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final task = taskState.filteredTasks[index];
                    return _TaskCard(task: task);
                  },
                ),
              ] else if (taskState is TaskListEmpty) ...[
                _buildStatusSummaryGrid(context, []),
                const SizedBox(height: 24),
                EmptyStateWidget(
                  title: 'No Tasks Yet',
                  message: 'Create a task to get work started on this project.',
                  icon: Icons.task_rounded,
                  action: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CreateEditTaskScreen(projectId: widget.project.id)),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Task'),
                  ),
                ),
              ] else if (taskState is TaskListLoading) ...[
                const SkeletonLoader(height: 120),
                const SizedBox(height: 16),
                const SkeletonLoader(height: 80),
              ] else if (taskState is TaskListError) ...[
                ErrorStateWidget(
                  failure: taskState.failure,
                  onRetry: () => ref.read(taskListProvider.notifier).loadTasksForProject(widget.project.id),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSummaryGrid(BuildContext context, List<TaskEntity> tasks) {
    final todo = tasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final review = tasks.where((t) => t.status == TaskStatus.review).length;
    final done = tasks.where((t) => t.status == TaskStatus.done).length;

    return Row(
      children: [
        _miniSummaryItem('To Do', todo, AppColors.statusTodo),
        _miniSummaryItem('In Progress', inProgress, AppColors.statusInProgress),
        _miniSummaryItem('Review', review, AppColors.statusReview),
        _miniSummaryItem('Done', done, AppColors.statusDone),
      ],
    );
  }

  Widget _miniSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskEntity task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusBadge(status: task.status),
                const SizedBox(width: 8),
                PriorityBadge(priority: task.priority),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          );
        },
      ),
    );
  }
}
