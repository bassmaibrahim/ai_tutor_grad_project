// lib/screens/quiz/quiz_review_screen.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';

class QuizReviewScreen extends StatelessWidget {
  const QuizReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};

    final List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(args['questions'] ?? []);
    final List<bool?> answers = List<bool?>.from(args['answers'] ?? []);
    final int correct = args['correct'] ?? 0;
    final int incorrect = args['incorrect'] ?? 0;
    final int total = args['total'] ?? questions.length;
    final int timeTaken = args['timeTaken'] ?? 0;

    final int percent = total > 0 ? ((correct / total) * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Quiz Review', style: AppTextStyles.heading3.copyWith(color: AppColors.primary)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Score card
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.05), AppColors.accent.withOpacity(0.03)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Column(children: [
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 120, height: 120,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 10,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(percent >= 70 ? AppColors.success : AppColors.warning),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$percent%', style: AppTextStyles.heading1.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  Text('$correct/$total', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ]),
              ]),
              const SizedBox(height: AppSpacing.lg),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _StatItem(icon: Icons.check_circle_rounded, label: 'Correct', value: '$correct', color: AppColors.success),
                _StatItem(icon: Icons.cancel_rounded, label: 'Review', value: '$incorrect', color: AppColors.error),
                _StatItem(icon: Icons.timer_rounded, label: 'Time', value: _formatTime(timeTaken), color: AppColors.primary),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Questions', style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),

          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final q = entry.value;
            final userAnswer = answers.length > index ? answers[index] : null;
            final isCorrect = userAnswer == true;
            final isIncorrect = userAnswer == false;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: userAnswer == null ? AppColors.divider : (isCorrect ? AppColors.success.withOpacity(0.4) : AppColors.error.withOpacity(0.4)),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: userAnswer == null ? AppColors.primary.withOpacity(0.1) : (isCorrect ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('${index + 1}', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(q['question'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                  if (userAnswer != null)
                    Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? AppColors.success : AppColors.error, size: 20),
                ]),
                if (userAnswer != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isCorrect ? AppColors.success.withOpacity(0.05) : AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(q['answer'] ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.5)),
                  ),
                ],
              ]),
            );
          }),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.studentHome, (route) => false),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(value, style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
    ]);
  }
}