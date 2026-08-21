import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/task.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color getPriorityColor() {
      switch (priority) {
        case TaskPriority.low:
          return AppColors.priorityLow;
        case TaskPriority.medium:
          return AppColors.priorityMedium;
        case TaskPriority.high:
          return AppColors.priorityHigh;
        case TaskPriority.urgent:
          return AppColors.priorityUrgent;
      }
    }

    IconData getPriorityIcon() {
      switch (priority) {
        case TaskPriority.low:
          return Icons.keyboard_arrow_down_rounded;
        case TaskPriority.medium:
          return Icons.remove_rounded;
        case TaskPriority.high:
          return Icons.keyboard_arrow_up_rounded;
        case TaskPriority.urgent:
          return Icons.priority_high_rounded;
      }
    }

    final color = getPriorityColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getPriorityIcon(), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
