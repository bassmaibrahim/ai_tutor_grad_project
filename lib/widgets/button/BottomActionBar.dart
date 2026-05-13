// lib/widgets/document_viewer/bottom_action_bar.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback onExplain;
  final VoidCallback onQuiz;
  final VoidCallback onSummary;

  const BottomActionBar({
    Key? key,
    required this.onExplain,
    required this.onQuiz,
    required this.onSummary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _ActionButton(
              icon: Icons.lightbulb_outline,
              label: 'Explain',
              onTap: onExplain,
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionButton(
              icon: Icons.quiz_outlined,
              label: 'Quiz',
              onTap: onQuiz,
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionButton(
              icon: Icons.summarize_outlined,
              label: 'Summarize',
              onTap: onSummary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.surface, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}