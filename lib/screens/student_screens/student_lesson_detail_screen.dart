// lib/screens/student_screens/student_lesson_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_routes.dart';
import '../../widgets/ai/section_header.dart';
import '../../widgets/ai/content_card.dart';
import '../../widgets/ai/video_recommendations.dart';

class StudentLessonDetailScreen extends StatefulWidget {
  const StudentLessonDetailScreen({Key? key}) : super(key: key);

  @override
  State<StudentLessonDetailScreen> createState() => _StudentLessonDetailScreenState();
}

class _StudentLessonDetailScreenState extends State<StudentLessonDetailScreen> {
  Map<String, dynamic>? _quiz;
  Map<String, dynamic>? _attempt;
  bool _loadingQuiz = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final lesson = args['lesson'] as Map<String, dynamic>;
    final classId = args['classId'] as String;
    _fetchQuizStatus(classId, lesson);
  }

  Future<void> _fetchQuizStatus(String classId, Map<String, dynamic> lesson) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Find quiz tied to this lesson
    final quizSnap = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .where('lessonId', isEqualTo: lesson['_id'] ?? '')
        .limit(1)
        .get();
    if (quizSnap.docs.isNotEmpty) {
      final quizData = quizSnap.docs.first.data();
      final quizId = quizSnap.docs.first.id;
      final attemptDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .doc(quizId)
          .collection('attempts')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _quiz = {'id': quizId, 'data': quizData};
          _attempt = attemptDoc.exists ? attemptDoc.data() : null;
          _loadingQuiz = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingQuiz = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final lesson = args['lesson'] as Map<String, dynamic>;
    final classId = args['classId'] as String;

    final title = lesson['title'] ?? 'Untitled';
    final explanation = lesson['explanation'] ?? '';
    final summary = (lesson['summary']?['summary'] ?? '').toString();
    final keyPoints = List<String>.from(lesson['summary']?['key_points'] ?? []);
    final videos = List<Map<String, dynamic>>.from(lesson['youtube']?['videos'] ?? []);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: Text(title, style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (explanation.isNotEmpty) ...[
            SectionHeader(title: 'Explanation', icon: Icons.lightbulb_outline_rounded),
            const SizedBox(height: AppSpacing.sm),
            ContentCard(child: Text(explanation, style: AppTextStyles.body.copyWith(height: 1.6))),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (summary.isNotEmpty && summary != explanation) ...[
            SectionHeader(title: 'Summary', icon: Icons.summarize_rounded),
            const SizedBox(height: AppSpacing.sm),
            ContentCard(child: Text(summary, style: AppTextStyles.body.copyWith(height: 1.6))),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (keyPoints.isNotEmpty) ...[
            SectionHeader(title: 'Key Points', icon: Icons.star_rounded),
            const SizedBox(height: AppSpacing.sm),
            ...keyPoints.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ContentCard(child: Text(p)))),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (videos.isNotEmpty) ...[
            SectionHeader(title: 'Recommended Videos', icon: Icons.play_circle_outline_rounded),
            const SizedBox(height: AppSpacing.sm),
            VideoRecommendations(videos: videos),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Quiz section
          if (_loadingQuiz)
            const Center(child: CircularProgressIndicator())
          else if (_quiz != null)
            _buildQuizButton(classId),
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }

  Widget _buildQuizButton(String classId) {
    final quizData = _quiz!['data'];
    final quizId = _quiz!['id'] as String;
    final questions = List<Map<String, dynamic>>.from(quizData['questions'] ?? []);


    final int total = _attempt != null ? (_attempt!['total'] ?? questions.length) : questions.length;

    if (_attempt != null) {
      final int score = _attempt!['score'] ?? 0;
      return SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.rate_review_outlined),
          label: Text('View Results (Score: $score/$total)',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.quizReview, arguments: {
              'questions': questions,               // full list (for review)
              'answers': _attempt!['answers'] ?? [],
              'correct': score,
              'incorrect': total - score,
              'total': total,                       // actual number taken
              'timeTaken': 0,
            });
          },
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.quiz),
          label: const Text('Take Quiz', style: TextStyle(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.flipQuiz, arguments: {
              'qaPairs': questions,                 // all questions; user chooses count later
              'classId': classId,
              'quizId': quizId,
            });
          },
        ),
      );
    }
  }
}