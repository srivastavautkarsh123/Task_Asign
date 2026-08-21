import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AppButtonType { primary, secondary, danger, outline }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color getBgColor() {
      switch (type) {
        case AppButtonType.primary:
          return AppColors.primary;
        case AppButtonType.secondary:
          return AppColors.secondary;
        case AppButtonType.danger:
          return AppColors.error;
        case AppButtonType.outline:
          return Colors.transparent;
      }
    }

    Color getFgColor() {
      switch (type) {
        case AppButtonType.outline:
          return Theme.of(context).colorScheme.onSurface;
        default:
          return Colors.white;
      }
    }

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: getFgColor(),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: getFgColor()),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: getFgColor(),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: 48,
      child: type == AppButtonType.outline
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: getBgColor(),
                foregroundColor: getFgColor(),
                disabledBackgroundColor: getBgColor().withValues(alpha: 0.5),
              ),
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
    );
  }
}
