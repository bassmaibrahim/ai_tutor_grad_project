// lib/widgets/ai/quiz_section.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_routes.dart';
import 'section_header.dart';

class QuizSection extends StatelessWidget {
  final TextEditingController quizController;
  final Map<String, dynamic>? apiResult;

  const QuizSection({Key? key, required this.quizController, required this.apiResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Generate Quiz', icon: Icons.quiz_rounded),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: quizController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Number of Questions (1-10)",
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Create'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final count = int.tryParse(quizController.text) ?? 10;
                  Navigator.pushNamed(context, AppRoutes.flipQuiz, arguments: {"questionCount": count, "apiResult": apiResult});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}