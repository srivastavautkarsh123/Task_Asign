import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:assignment/core/constants/app_colors.dart';
import 'package:assignment/presentation/providers/notification_provider.dart';
import 'package:assignment/presentation/providers/task_provider.dart';
import 'package:assignment/presentation/widgets/empty_state_widget.dart';
import 'package:assignment/presentation/screens/tasks/task_detail_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(userNotificationsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? const EmptyStateWidget(
              title: 'No Notifications',
              message: 'You have no task assignment notifications at this time.',
              icon: Icons.notifications_none_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final notif = notifications[index];
                return Card(
                  color: notif.read ? null : AppColors.primary.withValues(alpha: 0.08),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notif.read ? AppColors.darkSurfaceVariant : AppColors.primary,
                      child: Icon(
                        Icons.assignment_ind_rounded,
                        color: notif.read ? Theme.of(context).colorScheme.onSurface : Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notif.message,
                      style: TextStyle(
                        fontWeight: notif.read ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(notif.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    trailing: notif.read
                        ? null
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () async {
                      ref.read(userNotificationsProvider(userId).notifier).markRead(notif.id);
                      final taskRes = await ref.read(taskRepositoryProvider).getTaskById(notif.taskId);
                      taskRes.fold(
                        (task) {
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                            );
                          }
                        },
                        (failure) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
