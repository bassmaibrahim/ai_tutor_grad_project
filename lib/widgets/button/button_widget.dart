import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
}

class AppButton extends StatelessWidget {
  final AppButtonVariant variant;
  final VoidCallback? onPressed;
  final String text;
  final bool isPressed;

  const AppButton({
    Key? key,
    required this.variant,
    required this.text,
    this.onPressed,
    this.isPressed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = _getStyle();
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: style.textColor,
        backgroundColor: style.backgroundColor,
        side: style.borderSide,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: style.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _ButtonStyle _getStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonStyle(
          backgroundColor: isPressed
              ? AppColors.primary.withOpacity(0.8)
              : AppColors.primary,
          textColor: AppColors.surface,
          borderSide: BorderSide.none,
        );
      case AppButtonVariant.secondary:
        return _ButtonStyle(
          backgroundColor: isPressed
              ? AppColors.scaffoldBackground
              : AppColors.accent,
          textColor: isPressed
              ? AppColors.primary
              : AppColors.surface,
          borderSide: BorderSide.none,
        );
      case AppButtonVariant.outline:
        return _ButtonStyle(
          backgroundColor: isPressed
              ? AppColors.scaffoldBackground
              : Colors.transparent,
          textColor: AppColors.primary,
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1,
          ),
        );
      case AppButtonVariant.ghost:
        return _ButtonStyle(
          backgroundColor: isPressed
              ? AppColors.scaffoldBackground
              : Colors.transparent,
          textColor: AppColors.primary,
          borderSide: BorderSide.none,
        );
    }
  }
}

class _ButtonStyle {
  final Color? backgroundColor;
  final Color textColor;
  final BorderSide borderSide;

  _ButtonStyle({
    this.backgroundColor,
    required this.textColor,
    required this.borderSide,
  });
}