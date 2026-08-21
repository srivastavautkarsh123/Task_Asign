import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assignment/core/constants/app_colors.dart';
import 'package:assignment/presentation/providers/auth_provider.dart';
import 'package:assignment/presentation/providers/project_provider.dart';
import 'package:assignment/presentation/widgets/app_text_field.dart';
import 'package:assignment/presentation/widgets/confirm_dialog.dart';
import 'package:assignment/presentation/widgets/empty_state_widget.dart';
import 'package:assignment/presentation/widgets/error_state_widget.dart';
import 'package:assignment/presentation/widgets/skeleton_loader.dart';
import 'package:assignment/presentation/screens/projects/project_detail_screen.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Project'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameController,
                label: 'Project Name',
                hint: 'Cloud Migration Phase 1',
                validator: (val) => val == null || val.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: descController,
                label: 'Description',
                hint: 'High level goal & milestone summary',
                maxLines: 2,
                validator: (val) => val == null || val.trim().isEmpty ? 'Description required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final authState = ref.read(authStateProvider);
              if (authState is Authenticated) {
                final err = await ref.read(projectListProvider.notifier).createProject(
                      authState.session,
                      nameController.text.trim(),
                      descController.text.trim(),
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final projectState = ref.watch(projectListProvider);

    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = authState.session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      floatingActionButton: session.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateProjectDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(projectListProvider.notifier).loadProjects(session.orgId);
        },
        child: _buildBody(context, ref, projectState, session),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProjectListState state, dynamic session) {
    if (state is ProjectListLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonLoader(height: 90),
      );
    }

    if (state is ProjectListError) {
      return ErrorStateWidget(
        failure: state.failure,
        onRetry: () => ref.read(projectListProvider.notifier).loadProjects(session.orgId),
      );
    }

    if (state is ProjectListEmpty) {
      return EmptyStateWidget(
        title: 'No Projects Found',
        message: 'Your organization does not have any active projects yet.',
        icon: Icons.folder_open_rounded,
        action: session.isAdmin
            ? ElevatedButton.icon(
                onPressed: () => _showCreateProjectDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create First Project'),
              )
            : null,
      );
    }

    if (state is ProjectListSuccess) {
      final projects = state.projects;
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final project = projects[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${project.taskCount} Tasks',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (session.isAdmin)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            onPressed: () async {
                              final confirm = await ConfirmDialog.show(
                                context,
                                title: 'Delete Project?',
                                content: 'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
                                isDanger: true,
                              );
                              if (confirm == true) {
                                final err = await ref.read(projectListProvider.notifier).deleteProject(session, project.id);
                                if (err != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(err), backgroundColor: AppColors.error),
                                  );
                                }
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      project.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
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
