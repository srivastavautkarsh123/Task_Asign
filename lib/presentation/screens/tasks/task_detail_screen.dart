import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:assignment/core/constants/app_colors.dart';
import 'package:assignment/domain/entities/task.dart';
import 'package:assignment/domain/entities/user.dart';
import 'package:assignment/presentation/providers/auth_provider.dart';
import 'package:assignment/presentation/providers/task_provider.dart';
import 'package:assignment/presentation/widgets/confirm_dialog.dart';
import 'package:assignment/presentation/widgets/priority_badge.dart';
import 'package:assignment/presentation/widgets/status_badge.dart';
import 'package:assignment/presentation/screens/tasks/create_edit_task_screen.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskEntity task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TaskEntity _currentTask;
  final _commentController = TextEditingController();
  bool _isAddingComment = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showAssigneePickerModal(BuildContext context, dynamic session, List<User> orgMembers) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assign Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_off_outlined)),
                title: const Text('Unassigned'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _updateAssignee(session, null);
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: orgMembers.length,
                  itemBuilder: (context, index) {
                    final member = orgMembers[index];
                    final isSelected = _currentTask.assigneeId == member.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                        child: member.avatarUrl == null ? Text(member.name[0]) : null,
                      ),
                      title: Text(member.name),
                      subtitle: Text(member.email),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await _updateAssignee(session, member.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAssignee(dynamic session, String? assigneeId) async {
    final err = await ref.read(taskListProvider.notifier).assignUser(session, _currentTask.id, assigneeId);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else if (mounted) {
      setState(() {
        _currentTask = _currentTask.copyWith(assigneeId: assigneeId, clearAssignee: assigneeId == null);
      });
    }
  }

  Future<void> _updateStatus(dynamic session, TaskStatus newStatus) async {
    final updated = _currentTask.copyWith(status: newStatus);
    final err = await ref.read(taskListProvider.notifier).updateTask(session, updated);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else if (mounted) {
      setState(() => _currentTask = updated);
    }
  }

  Future<void> _updatePriority(dynamic session, TaskPriority newPriority) async {
    final updated = _currentTask.copyWith(priority: newPriority);
    final err = await ref.read(taskListProvider.notifier).updateTask(session, updated);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
    } else if (mounted) {
      setState(() => _currentTask = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final session = authState.session;

    final membersAsync = ref.watch(orgMembersProvider(session.orgId));
    final commentsAsync = ref.watch(taskCommentsProvider(_currentTask.id));

    User? currentAssignee;
    membersAsync.whenData((members) {
      if (_currentTask.assigneeId != null) {
        currentAssignee = members.firstWhere((m) => m.id == _currentTask.assigneeId, orElse: () => User(id: '', name: 'Unknown', email: ''));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateEditTaskScreen(taskToEdit: _currentTask)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () async {
              final confirm = await ConfirmDialog.show(
                context,
                title: 'Delete Task?',
                content: 'Are you sure you want to delete "${_currentTask.title}"?',
                isDanger: true,
              );
              if (confirm == true) {
                final err = await ref.read(taskListProvider.notifier).deleteTask(session, _currentTask.id);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentTask.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                PopupMenuButton<TaskStatus>(
                  onSelected: (status) => _updateStatus(session, status),
                  itemBuilder: (ctx) => TaskStatus.values
                      .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  child: StatusBadge(status: _currentTask.status),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<TaskPriority>(
                  onSelected: (p) => _updatePriority(session, p),
                  itemBuilder: (ctx) => TaskPriority.values
                      .map((p) => PopupMenuItem(value: p, child: Text(p.label)))
                      .toList(),
                  child: PriorityBadge(priority: _currentTask.priority),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(_currentTask.description),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.event_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Due Date: ${DateFormat('MMMM d, yyyy').format(_currentTask.dueDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: currentAssignee?.avatarUrl != null ? NetworkImage(currentAssignee!.avatarUrl!) : null,
                  child: currentAssignee == null
                      ? const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary)
                      : (currentAssignee!.avatarUrl == null ? Text(currentAssignee!.name[0]) : null),
                ),
                title: const Text('Assignee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  currentAssignee != null ? currentAssignee!.name : 'Unassigned',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                trailing: OutlinedButton(
                  onPressed: () {
                    membersAsync.whenData((members) {
                      _showAssigneePickerModal(context, session, members);
                    });
                  },
                  child: const Text('Change'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Comments & Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No comments yet. Start the conversation below!'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final cmt = comments[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('User (${cmt.authorId})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  DateFormat('MMM d, h:mm a').format(cmt.createdAt),
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(cmt.body),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load comments.'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isAddingComment
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: _isAddingComment
                      ? null
                      : () async {
                          final text = _commentController.text.trim();
                          if (text.isEmpty) return;
                          setState(() => _isAddingComment = true);

                          await ref.read(taskRepositoryProvider).addComment(session, _currentTask.id, text);
                          ref.invalidate(taskCommentsProvider(_currentTask.id));

                          if (mounted) {
                            _commentController.clear();
                            setState(() => _isAddingComment = false);
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
