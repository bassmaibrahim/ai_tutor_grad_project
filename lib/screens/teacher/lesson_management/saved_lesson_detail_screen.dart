import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';
import '../../../widgets/ai/section_header.dart';
import '../../../widgets/ai/content_card.dart';
import '../../../widgets/ai/video_recommendations.dart';

class SavedLessonDetailScreen extends StatefulWidget {
  const SavedLessonDetailScreen({Key? key}) : super(key: key);

  @override
  State<SavedLessonDetailScreen> createState() =>
      _SavedLessonDetailScreenState();
}

class _SavedLessonDetailScreenState extends State<SavedLessonDetailScreen> {
  bool _isPublishing = false;

  Future<void> _publishToClass() async {
    final args = ModalRoute.of(context)!.settings.arguments
    as Map<String, dynamic>;
    final lesson = args['lesson'] as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch teacher's classes for selection
    final classesSnap = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(user.uid)
        .collection('classes')
        .get();

    if (!mounted) return;

    if (classesSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No classes available. Create a class first.')),
      );
      return;
    }

    // Show class picker dialog
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Choose a class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: classesSnap.docs.map((doc) {
                final data = doc.data();
                return ListTile(
                  title: Text(data['name'] ?? 'Unnamed'),
                  subtitle: Text('Code: ${data['code']}'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _isPublishing = true);

                    try {
                      final lessonTitle =
                          lesson['title'] ?? 'Untitled Lesson';
                      final qaPairs = List<Map<String, dynamic>>.from(
                          (lesson['qa']?['qa_pairs'] ?? []));

                      // 1. Save lesson to class's public lessons
                      final lessonRef = await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(doc.id)
                          .collection('lessons')
                          .add({
                        ...lesson,
                        'title': lessonTitle,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // 2. Update lesson count on teacher's class document
                      await FirebaseFirestore.instance
                          .collection('teachers')
                          .doc(user.uid)
                          .collection('classes')
                          .doc(doc.id)
                          .update({
                        'lessonCount': FieldValue.increment(1),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      // 3. Create quiz from Q&A pairs
                      if (qaPairs.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('classes')
                            .doc(doc.id)
                            .collection('quizzes')
                            .add({
                          'lessonId': lessonRef.id,
                          'title': 'Quiz: $lessonTitle',
                          'questions': qaPairs,
                          'attemptCount': 0,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Lesson published successfully!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isPublishing = false);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments
    as Map<String, dynamic>;
    final lesson = args['lesson'] as Map<String, dynamic>;

    final title = lesson['title'] ?? 'Untitled';
    final explanation = lesson['explanation'] ?? '';
    final summary =
    (lesson['summary']?['summary'] ?? '').toString();
    final keyPoints =
    List<String>.from(lesson['summary']?['key_points'] ?? []);
    final qaPairs = List<Map<String, dynamic>>.from(
        (lesson['qa']?['qa_pairs'] ?? []));
    final videos = List<Map<String, dynamic>>.from(
        (lesson['youtube']?['videos'] ?? []));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title,
            style:
            AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.primary),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.teacherHome, (route) => false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (explanation.isNotEmpty) ...[
              SectionHeader(
                  title: 'Explanation',
                  icon: Icons.lightbulb_outline_rounded),
              const SizedBox(height: AppSpacing.sm),
              ContentCard(
                  child: Text(explanation,
                      style: AppTextStyles.body.copyWith(height: 1.6))),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (summary.isNotEmpty) ...[
              SectionHeader(
                  title: 'Summary', icon: Icons.summarize_rounded),
              const SizedBox(height: AppSpacing.sm),
              ContentCard(
                  child: Text(summary,
                      style: AppTextStyles.body.copyWith(height: 1.6))),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (keyPoints.isNotEmpty) ...[
              SectionHeader(
                  title: 'Key Points', icon: Icons.star_rounded),
              const SizedBox(height: AppSpacing.sm),
              ...keyPoints.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ContentCard(child: Text(p)))),
            ],
            if (qaPairs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                  title: 'Questions & Answers',
                  icon: Icons.quiz_rounded),
              const SizedBox(height: AppSpacing.sm),
              ...qaPairs.map((q) => _QACard(
                  question: q['question'] ?? '',
                  answer: q['answer'] ?? '')),
            ],
            if (videos.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                  title: 'Recommended Videos',
                  icon: Icons.play_circle_outline_rounded),
              const SizedBox(height: AppSpacing.sm),
              VideoRecommendations(videos: videos),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      // Publish button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2))
            ]),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: _isPublishing
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(
                _isPublishing ? 'Publishing...' : 'Publish to Class',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isPublishing ? null : _publishToClass,
            ),
          ),
        ),
      ),
    );
  }
}

class _QACard extends StatelessWidget {
  final String question;
  final String answer;
  const _QACard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(question,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(answer,
              style: AppTextStyles.caption.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}