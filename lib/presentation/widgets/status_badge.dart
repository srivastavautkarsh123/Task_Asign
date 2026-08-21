import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/task.dart';

class StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      switch (status) {
        case TaskStatus.todo:
          return AppColors.statusTodo;
        case TaskStatus.inProgress:
          return AppColors.statusInProgress;
        case TaskStatus.review:
          return AppColors.statusReview;
        case TaskStatus.done:
          return AppColors.statusDone;
      }
    }

    final color = getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
