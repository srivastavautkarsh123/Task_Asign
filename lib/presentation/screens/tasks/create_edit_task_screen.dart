import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:assignment/core/constants/app_colors.dart';
import 'package:assignment/domain/entities/task.dart';
import 'package:assignment/domain/entities/user.dart';
import 'package:assignment/presentation/providers/auth_provider.dart';
import 'package:assignment/presentation/providers/project_provider.dart';
import 'package:assignment/presentation/providers/task_provider.dart';
import 'package:assignment/presentation/widgets/app_button.dart';
import 'package:assignment/presentation/widgets/app_text_field.dart';

class CreateEditTaskScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final TaskEntity? taskToEdit;

  const CreateEditTaskScreen({
    super.key,
    this.projectId,
    this.taskToEdit,
  });

  @override
  ConsumerState<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends ConsumerState<CreateEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  TaskStatus _selectedStatus = TaskStatus.todo;
  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _selectedProjectId;
  String? _selectedAssigneeId;
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.taskToEdit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.taskToEdit?.description ?? '');

    if (widget.taskToEdit != null) {
      _selectedStatus = widget.taskToEdit!.status;
      _selectedPriority = widget.taskToEdit!.priority;
      _selectedProjectId = widget.taskToEdit!.projectId;
      _selectedAssigneeId = widget.taskToEdit!.assigneeId;
      _selectedDueDate = widget.taskToEdit!.dueDate;
    } else {
      _selectedProjectId = widget.projectId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project'), backgroundColor: AppColors.error),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    setState(() => _isLoading = true);
    final session = authState.session;

    String? error;

    if (widget.taskToEdit != null) {
      final updated = widget.taskToEdit!.copyWith(
        projectId: _selectedProjectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        assigneeId: _selectedAssigneeId,
        clearAssignee: _selectedAssigneeId == null,
        dueDate: _selectedDueDate,
      );
      error = await ref.read(taskListProvider.notifier).updateTask(session, updated);
    } else {
      final newTask = TaskEntity(
        id: "task_${DateTime.now().millisecondsSinceEpoch}",
        projectId: _selectedProjectId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        assigneeId: _selectedAssigneeId,
        dueDate: _selectedDueDate,
        createdAt: DateTime.now(),
      );
      error = await ref.read(taskListProvider.notifier).createTask(session, newTask);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;
    final authState = ref.watch(authStateProvider);
    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final session = authState.session;
    final projectState = ref.watch(projectListProvider);
    final membersAsync = ref.watch(orgMembersProvider(session.orgId));

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Create Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Task Title',
                hint: 'e.g. Build authentication flow',
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Detailed requirements and acceptance criteria...',
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              if (projectState is ProjectListSuccess) ...[
                Text(
                  'Project',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedProjectId ?? projectState.projects.firstOrNull?.id,
                  decoration: const InputDecoration(),
                  items: projectState.projects.map((p) {
                    return DropdownMenuItem(value: p.id, child: Text(p.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedProjectId = val),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<TaskPriority>(
                          value: _selectedPriority,
                          decoration: const InputDecoration(),
                          items: TaskPriority.values.map((p) {
                            return DropdownMenuItem(value: p, child: Text(p.label));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPriority = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<TaskStatus>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(),
                          items: TaskStatus.values.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s.label));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Assignee',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 6),
              membersAsync.when(
                data: (members) {
                  return DropdownButtonFormField<String?>(
                    value: _selectedAssigneeId,
                    decoration: const InputDecoration(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Unassigned')),
                      ...members.map((m) => DropdownMenuItem(value: m.id, child: Text('${m.name} (${m.email})'))),
                    ],
                    onChanged: (val) => setState(() => _selectedAssigneeId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading org members'),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDueDate),
                        style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: const Text('Pick Date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDueDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              AppButton(
                text: isEditing ? 'Update Task' : 'Create Task',
                isLoading: _isLoading,
                onPressed: _saveTask,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
