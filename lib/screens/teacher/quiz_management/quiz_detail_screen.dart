import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';

class QuizDetailScreen extends StatelessWidget {
  const QuizDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final classId = args['classId'] as String;
    final quizId = args['quizId'] as String;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Quiz Details',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('quizzes')
            .doc(quizId)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snap.data!.data() as Map<String, dynamic>;
          final title = data['title'] ?? 'Untitled Quiz';
          final questions =
          List<Map<String, dynamic>>.from(data['questions'] ?? []);
          final attemptCount = data['attemptCount'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Quiz info ----
                Text(title,
                    style: AppTextStyles.heading2
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text('Total attempts: $attemptCount',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.lg),

                // ---- Questions ----
                Text('Questions', style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.sm),
                ...questions.map((q) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q['question'] ?? '',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(q['answer'] ?? '',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.success)),
                    ],
                  ),
                )),
                const SizedBox(height: AppSpacing.lg),

                // ---- Student Attempts ----
                Text('Student Attempts', style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.sm),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(classId)
                      .collection('quizzes')
                      .doc(quizId)
                      .collection('attempts')
                      .orderBy('completedAt', descending: true)
                      .snapshots(),
                  builder: (context, attemptSnap) {
                    if (!attemptSnap.hasData ||
                        attemptSnap.data!.docs.isEmpty) {
                      return Text('No attempts yet',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary));
                    }

                    return Column(
                      children: attemptSnap.data!.docs.map((doc) {
                        final attemptData =
                        doc.data() as Map<String, dynamic>;
                        // ✅ The document ID is the student's UID
                        final userId = doc.id;
                        final score = attemptData['score'] ?? 0;
                        final total = attemptData['total'] ?? questions.length;

                        final futureUser = userId.isNotEmpty
                            ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get()
                            : Future.value(null);

                        return FutureBuilder<DocumentSnapshot?>(
                          future: futureUser,
                          builder: (context, userSnap) {
                            String name = userId;
                            String email = '';

                            if (userId.isEmpty ||
                                !userSnap.hasData ||
                                userSnap.data == null ||
                                !userSnap.data!.exists) {
                              name = 'Unknown Student';
                            } else {
                              final userData = userSnap.data!.data()
                              as Map<String, dynamic>?;
                              name = userData?['name'] ?? userId;
                              email = userData?['email'] ?? '';
                            }

                            // Determine pass/fail (≥ 50%)
                            final bool passed = (score / total) >= 0.5;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: passed
                                    ? AppColors.success.withOpacity(0.15)
                                    : AppColors.error.withOpacity(0.15),
                                child: Icon(
                                  passed ? Icons.check : Icons.close,
                                  color: passed
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: 20,
                                ),
                              ),
                              title: Text(name,
                                  style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${email.isNotEmpty ? "$email — " : ""}Score: $score / $total',
                                style: AppTextStyles.caption,
                              ),
                              trailing: Text(
                                (attemptData['completedAt'] as Timestamp?)
                                    ?.toDate()
                                    .toString()
                                    .substring(0, 16) ??
                                    '',
                                style: AppTextStyles.caption,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}