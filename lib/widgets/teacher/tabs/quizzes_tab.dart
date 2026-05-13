// lib/widgets/teacher/tabs/quizzes_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';

class QuizzesTab extends StatelessWidget {
  final String classId;

  const QuizzesTab({Key? key, required this.classId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text('No quizzes yet',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            final doc = snap.data!.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _QuizCard(
              quizId: doc.id,
              data: data,
              classId: classId,
            );
          },
        );
      },
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String quizId;
  final Map<String, dynamic> data;
  final String classId;

  const _QuizCard({
    required this.quizId,
    required this.data,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled Quiz';
    final lessonId = data['lessonId'] ?? '';
    final questionCount = (data['questions'] as List?)?.length ?? 0;
    final attemptCount = data['attemptCount'] ?? 0; // You can store this as a counter

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            if (lessonId.isNotEmpty)
              Text('Linked to lesson',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.quiz_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('$questionCount questions',
                    style: AppTextStyles.caption),
                const Spacer(),
                Icon(Icons.people, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('$attemptCount attempts',
                    style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Question'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addQuestion,
                        arguments: {
                          'classId': classId,
                          'quizId': quizId,
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.quizDetail,
                        arguments: {
                          'classId': classId,
                          'quizId': quizId,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}