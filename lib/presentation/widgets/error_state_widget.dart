import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/errors/failures.dart';
import 'app_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.failure,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    IconData getIcon() {
      if (failure is NotFoundFailure) return Icons.search_off_rounded;
      if (failure is NetworkTimeoutFailure) return Icons.timer_off_rounded;
      if (failure is OfflineFailure) return Icons.wifi_off_rounded;
      if (failure is UnauthorizedFailure) return Icons.lock_outline_rounded;
      return Icons.error_outline_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(getIcon(), size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              "Something Went Wrong",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: "Retry",
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
