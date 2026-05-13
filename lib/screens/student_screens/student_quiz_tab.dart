// lib/screens/student/tabs/student_quiz_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';

class StudentQuizTab extends StatelessWidget {
  const StudentQuizTab({Key? key}) : super(key: key);

  // Fetch all classes the student is enrolled in
  Stream<List<Map<String, dynamic>>> _enrolledClasses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('enrolledClasses')
        .snapshots()
        .asyncMap((snap) async {
      final classesData = <Map<String, dynamic>>[];
      for (var doc in snap.docs) {
        final data = doc.data();
        classesData.add({
          'classId': data['classId'],
          'className': data['className'] ?? 'Unknown',
          'code': data['code'] ?? '',
        });
      }
      return classesData;
    });
  }

  // Fetch all quizzes for a given class
  Stream<QuerySnapshot> _quizzesForClass(String classId) {
    return FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .snapshots();
  }

  // Get attempt data if exists
  Future<Map<String, dynamic>?> _getAttempt(String classId, String quizId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .doc(quizId)
        .collection('attempts')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Eshrhly AI Tutor',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _enrolledClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 80, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Start taking quizzes to track your progress!',
                      style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Join a class and complete the quizzes that your teacher has prepared.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classData = classes[index];
              final classId = classData['classId'] as String;
              final className = classData['className'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(className,
                          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(classData['code'] ?? '',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      const Divider(height: AppSpacing.lg),
                      StreamBuilder<QuerySnapshot>(
                        stream: _quizzesForClass(classId),
                        builder: (context, quizSnap) {
                          if (!quizSnap.hasData || quizSnap.data!.docs.isEmpty) {
                            return Text('No quizzes available yet.',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary));
                          }

                          final quizzes = quizSnap.data!.docs;
                          return Column(
                            children: quizzes.map((quizDoc) {
                              final quizData = quizDoc.data() as Map<String, dynamic>;
                              final quizId = quizDoc.id;
                              final title = quizData['title'] ?? 'Untitled Quiz';
                              final questionCount = (quizData['questions'] as List?)?.length ?? 0;

                              return FutureBuilder<Map<String, dynamic>?>(
                                future: _getAttempt(classId, quizId),
                                builder: (context, attemptSnap) {
                                  final attempt = attemptSnap.data;
                                  final isCompleted = attempt != null;
                                  final displayTotal = attempt?['total'] ?? questionCount;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isCompleted ? AppColors.success : AppColors.textSecondary,
                                    ),
                                    title: Text(title,
                                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      isCompleted
                                          ? 'Score: ${attempt?['score']}/$displayTotal'
                                          : '$questionCount questions',
                                      style: AppTextStyles.caption,
                                    ),
                                    trailing: TextButton(
                                      child: Text(isCompleted ? 'Review' : 'Start',
                                          style: TextStyle(fontWeight: FontWeight.w600)),
                                      onPressed: () {
                                        if (isCompleted) {
                                          // Build the subset of questions that were actually attempted
                                          final allQuestions = List<Map<String, dynamic>>.from(quizData['questions'] ?? []);
                                          final attemptedQuestions = allQuestions.take(displayTotal).toList();
                                          final answers = List<bool>.from(attempt!['answers'] ?? []);
                                          final correct = attempt['score'] ?? 0;

                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.quizReview,
                                            arguments: {
                                              'questions': attemptedQuestions,
                                              'answers': answers,
                                              'correct': correct,
                                              'incorrect': displayTotal - correct,
                                              'total': displayTotal,
                                              'timeTaken': 0,
                                            },
                                          );
                                        } else {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.flipQuiz,
                                            arguments: {
                                              'qaPairs': List<Map<String, dynamic>>.from(quizData['questions']),
                                              'classId': classId,
                                              'quizId': quizId,
                                            },
                                          );
                                        }
                                      },
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}