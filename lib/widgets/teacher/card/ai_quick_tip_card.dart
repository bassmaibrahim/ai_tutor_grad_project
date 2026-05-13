// lib/widgets/teacher/ai_quick_tip_card.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';

class AIQuickTipCard extends StatelessWidget {
  const AIQuickTipCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.06), AppColors.accent.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('AI QUICK TIP', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"Upload any study material and let AI transform it into summaries, quizzes, and interactive lessons in seconds."',
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontStyle: FontStyle.italic, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.howItWorks);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Try it Now', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}