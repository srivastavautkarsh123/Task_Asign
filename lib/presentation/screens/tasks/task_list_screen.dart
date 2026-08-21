import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:assignment/core/constants/app_colors.dart';
import 'package:assignment/domain/entities/task.dart';
import 'package:assignment/presentation/providers/auth_provider.dart';
import 'package:assignment/presentation/providers/task_provider.dart';
import 'package:assignment/presentation/widgets/app_button.dart';
import 'package:assignment/presentation/widgets/app_text_field.dart';
import 'package:assignment/presentation/widgets/empty_state_widget.dart';
import 'package:assignment/presentation/widgets/error_state_widget.dart';
import 'package:assignment/presentation/widgets/priority_badge.dart';
import 'package:assignment/presentation/widgets/skeleton_loader.dart';
import 'package:assignment/presentation/widgets/status_badge.dart';
import 'package:assignment/presentation/screens/tasks/task_detail_screen.dart';
import 'package:assignment/presentation/screens/tasks/create_edit_task_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authState = ref.read(authStateProvider);
      if (authState is Authenticated) {
        ref.read(taskListProvider.notifier).loadTasksForOrg(authState.session.orgId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterBottomSheet(BuildContext context, TaskFilterState currentFilters, String orgId) {
    TaskStatus? tempStatus = currentFilters.statusFilter;
    TaskPriority? tempPriority = currentFilters.priorityFilter;
    String? tempAssignee = currentFilters.assigneeIdFilter;
    DateTimeRange? tempDateRange = currentFilters.dateRangeFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempStatus = null;
                            tempPriority = null;
                            tempAssignee = null;
                            tempDateRange = null;
                          });
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: TaskStatus.values.map((s) {
                      final selected = tempStatus == s;
                      return ChoiceChip(
                        label: Text(s.label),
                        selected: selected,
                        onSelected: (val) {
                          setModalState(() {
                            tempStatus = val ? s : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: TaskPriority.values.map((p) {
                      final selected = tempPriority == p;
                      return ChoiceChip(
                        label: Text(p.label),
                        selected: selected,
                        onSelected: (val) {
                          setModalState(() {
                            tempPriority = val ? p : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('Assignee', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Consumer(
                    builder: (context, ref, child) {
                      final membersAsync = ref.watch(orgMembersProvider(orgId));
                      return membersAsync.when(
                        data: (members) {
                          return DropdownButtonFormField<String?>(
                            value: tempAssignee,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Members')),
                              ...members.map(
                                (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                              ),
                            ],
                            onChanged: (val) => setModalState(() => tempAssignee = val),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Failed to load members'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Date Range', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            tempDateRange == null
                                ? 'No date range selected'
                                : '${DateFormat('MMM d').format(tempDateRange!.start)} - ${DateFormat('MMM d').format(tempDateRange!.end)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range_rounded, size: 16),
                        label: Text(tempDateRange == null ? 'Select' : 'Change'),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                            initialDateRange: tempDateRange,
                          );
                          if (picked != null) {
                            setModalState(() => tempDateRange = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    text: 'Apply Filters',
                    onPressed: () {
                      final updatedFilters = TaskFilterState(
                        statusFilter: tempStatus,
                        priorityFilter: tempPriority,
                        assigneeIdFilter: tempAssignee,
                        searchQuery: _searchController.text.trim(),
                        dateRangeFilter: tempDateRange,
                      );
                      ref.read(taskListProvider.notifier).setFilter(updatedFilters);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final taskState = ref.watch(taskListProvider);

    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = authState.session;

    TaskFilterState activeFilters = const TaskFilterState();
    if (taskState is TaskListSuccess) activeFilters = taskState.filters;
    if (taskState is TaskListEmpty) activeFilters = taskState.filters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks Board'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: activeFilters.hasActiveFilters ? AppColors.primary : null,
            ),
            onPressed: () => _openFilterBottomSheet(context, activeFilters, session.orgId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateEditTaskScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                AppTextField(
                  controller: _searchController,
                  label: '',
                  hint: 'Search tasks by title or keyword...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  onChanged: (val) {
                    final currentFilters = activeFilters.copyWith(searchQuery: val);
                    ref.read(taskListProvider.notifier).setFilter(currentFilters);
                  },
                ),
                if (activeFilters.hasActiveFilters) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (activeFilters.statusFilter != null)
                          Chip(
                            label: Text('Status: ${activeFilters.statusFilter!.label}'),
                            onDeleted: () {
                              ref.read(taskListProvider.notifier).setFilter(
                                    activeFilters.copyWith(clearStatus: true),
                                  );
                            },
                          ),
                        if (activeFilters.priorityFilter != null) ...[
                          const SizedBox(width: 6),
                          Chip(
                            label: Text('Priority: ${activeFilters.priorityFilter!.label}'),
                            onDeleted: () {
                              ref.read(taskListProvider.notifier).setFilter(
                                    activeFilters.copyWith(clearPriority: true),
                                  );
                            },
                          ),
                        ],
                        if (activeFilters.assigneeIdFilter != null) ...[
                          const SizedBox(width: 6),
                          Chip(
                            label: const Text('Assignee Filtered'),
                            onDeleted: () {
                              ref.read(taskListProvider.notifier).setFilter(
                                    activeFilters.copyWith(clearAssignee: true),
                                  );
                            },
                          ),
                        ],
                        if (activeFilters.dateRangeFilter != null) ...[
                          const SizedBox(width: 6),
                          Chip(
                            label: const Text('Date Range Filtered'),
                            onDeleted: () {
                              ref.read(taskListProvider.notifier).setFilter(
                                    activeFilters.copyWith(clearDateRange: true),
                                  );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(taskListProvider.notifier).loadTasksForOrg(session.orgId);
              },
              child: _buildTaskListContent(context, ref, taskState, session),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListContent(BuildContext context, WidgetRef ref, TaskListState state, dynamic session) {
    if (state is TaskListLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonLoader(height: 100),
      );
    }

    if (state is TaskListError) {
      return ErrorStateWidget(
        failure: state.failure,
        onRetry: () => ref.read(taskListProvider.notifier).loadTasksForOrg(session.orgId),
      );
    }

    if (state is TaskListEmpty) {
      return EmptyStateWidget(
        title: 'No Matching Tasks',
        message: 'No tasks were found for the current search or filters.',
        icon: Icons.task_alt_rounded,
        action: state.filters.hasActiveFilters
            ? OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(taskListProvider.notifier).setFilter(const TaskFilterState());
                },
                child: const Text('Clear Filters'),
              )
            : null,
      );
    }

    if (state is TaskListSuccess) {
      final tasks = state.filteredTasks;
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final task = tasks[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        PriorityBadge(priority: task.priority),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(status: task.status),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(task.dueDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
