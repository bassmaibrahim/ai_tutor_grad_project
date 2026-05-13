// lib/screens/teacher/lesson_preview_screen.dart
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

class LessonPreviewScreen extends StatefulWidget {
  const LessonPreviewScreen({Key? key}) : super(key: key);

  @override
  State<LessonPreviewScreen> createState() => _LessonPreviewScreenState();
}

class _LessonPreviewScreenState extends State<LessonPreviewScreen> {
  bool _isSaving = false;
  bool _isPublishing = false;
  bool _hasSavedPersonal = false;

  late List<Map<String, dynamic>> _qaPairs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!
        .settings
        .arguments as Map<String, dynamic>;
    final result = args['result'] as Map<String, dynamic>? ?? {};
    _qaPairs = List<Map<String, dynamic>>.from(
      (result['qa']?['qa_pairs'] ?? []),
    );
  }

  // ---------- Question management (unchanged) ----------
  void _addQuestion() { /* ... */ }
  void _editQuestion(int index) { /* ... */ }
  void _removeQuestion(int index) { /* ... */ }

  // ---------- Safe extraction helpers ----------
  String _extractSummaryText(Map<String, dynamic> result) {
    final summaryRaw = result['summary'];
    if (summaryRaw is Map) return (summaryRaw['summary'] ?? '').toString();
    if (summaryRaw is String) return summaryRaw;
    return '';
  }

  List<String> _extractKeyPoints(Map<String, dynamic> result) {
    final summaryRaw = result['summary'];
    if (summaryRaw is Map) {
      return List<String>.from(summaryRaw['key_points'] ?? []);
    }
    return [];
  }

  String _extractExplanation(Map<String, dynamic> result) {
    final summaryRaw = result['summary'];
    if (summaryRaw is Map && summaryRaw['explanation'] != null) {
      return summaryRaw['explanation'].toString();
    }
    return (result['explanation'] ?? '').toString();
  }

  List<Map<String, dynamic>> _extractVideos(Map<String, dynamic> result) {
    final youtubeRaw = result['youtube'];
    if (youtubeRaw is Map) {
      return List<Map<String, dynamic>>.from(youtubeRaw['videos'] ?? []);
    }
    return [];
  }

  // ---------- Save Personal ----------
  Future<void> _savePersonal() async {
    if (_isSaving || _hasSavedPersonal) return;
    setState(() => _isSaving = true);
    try {
      final args = ModalRoute.of(context)!.settings.arguments
      as Map<String, dynamic>;
      final classData = args['classData'] as Map<String, dynamic>;
      final result = args['result'] as Map<String, dynamic>? ?? {};
      final lessonTitle =
          args['lessonTitle'] as String? ?? 'Untitled Lesson';
      final user = FirebaseAuth.instance.currentUser;

      final updatedResult = Map<String, dynamic>.from(result);
      updatedResult['qa'] = {'qa_pairs': _qaPairs};

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .collection('saved_lessons')
            .add({
          'title': lessonTitle,
          'summary': {
            'summary': _extractSummaryText(updatedResult),
            'key_points': _extractKeyPoints(updatedResult),
          },
          'key_points': _extractKeyPoints(updatedResult),
          'explanation': _extractExplanation(updatedResult),
          'youtube': {'videos': _extractVideos(updatedResult)},
          'qa': {'qa_pairs': _qaPairs},
          'detected_topic':
          (updatedResult['detected_topic'] ?? '').toString(),
          'word_count': updatedResult['word_count'] ?? 0,
          'classId': classData['classId'],
          'className': classData['name'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _hasSavedPersonal = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson saved to your library!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saving failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------- Publish to Class ----------
  Future<void> _publishToClass() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);
    try {
      final args = ModalRoute.of(context)!.settings.arguments
      as Map<String, dynamic>;
      final classData = args['classData'] as Map<String, dynamic>;
      final result = args['result'] as Map<String, dynamic>? ?? {};
      final lessonTitle =
          args['lessonTitle'] as String? ?? 'Untitled Lesson';
      final user = FirebaseAuth.instance.currentUser;

      final updatedResult = Map<String, dynamic>.from(result);
      updatedResult['qa'] = {'qa_pairs': _qaPairs};

      // Save lesson to class
      final lessonRef = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classData['classId'])
          .collection('lessons')
          .add({
        'title': lessonTitle,
        'summary': {
          'summary': _extractSummaryText(updatedResult),
          'key_points': _extractKeyPoints(updatedResult),
        },
        'key_points': _extractKeyPoints(updatedResult),
        'explanation': _extractExplanation(updatedResult),
        'youtube': {'videos': _extractVideos(updatedResult)},
        'qa': {'qa_pairs': _qaPairs},
        'detected_topic':
        (updatedResult['detected_topic'] ?? '').toString(),
        'word_count': updatedResult['word_count'] ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Personal copy if not already saved
      if (!_hasSavedPersonal && user != null) {
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .collection('saved_lessons')
            .add({
          'title': lessonTitle,
          'summary': {
            'summary': _extractSummaryText(updatedResult),
            'key_points': _extractKeyPoints(updatedResult),
          },
          'key_points': _extractKeyPoints(updatedResult),
          'explanation': _extractExplanation(updatedResult),
          'youtube': {'videos': _extractVideos(updatedResult)},
          'qa': {'qa_pairs': _qaPairs},
          'detected_topic':
          (updatedResult['detected_topic'] ?? '').toString(),
          'word_count': updatedResult['word_count'] ?? 0,
          'classId': classData['classId'],
          'className': classData['name'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _hasSavedPersonal = true;
      }

      // Update class counts
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .collection('classes')
            .doc(classData['classId'])
            .update({
          'lessonCount': FieldValue.increment(1),
          'insightsCount': FieldValue.increment(1), // ✅ AI insights
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Create quiz
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classData['classId'])
          .collection('quizzes')
          .add({
        'lessonId': lessonRef.id,
        'title': 'Quiz: $lessonTitle',
        'questions': _qaPairs,
        'attemptCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: AppColors.success, size: 40)),
            const SizedBox(height: AppSpacing.lg),
            Text('Lesson Published Successfully',
                style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publishing failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments
    as Map<String, dynamic>;
    final result = args['result'] as Map<String, dynamic>? ?? {};

    // Safe extraction for display
    final String summary = _extractSummaryText(result);
    final List<String> keyPoints = _extractKeyPoints(result);
    final String explanation = _extractExplanation(result);
    final List<Map<String, dynamic>> videos = _extractVideos(result);
    final String detectedTopic =
    (result['detected_topic'] ?? '').toString();
    final int wordCount = result['word_count'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.primary),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.teacherHome, (route) => false)),
        title: Text('Lesson Preview',
            style:
            AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info chips
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            if (detectedTopic.isNotEmpty)
              _InfoChip(
                  icon: Icons.topic_rounded,
                  label: detectedTopic,
                  color: AppColors.softPurple),
            _InfoChip(
                icon: Icons.text_fields_rounded,
                label: '$wordCount words',
                color: AppColors.softBlue),
            _InfoChip(
                icon: Icons.quiz_rounded,
                label: '${_qaPairs.length} Questions',
                color: AppColors.softGreen),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // Explanation
          if (explanation.isNotEmpty) ...[
            SectionHeader(
                title: 'Explanation',
                icon: Icons.lightbulb_outline_rounded,
                onListen: () => Navigator.pushNamed(context, AppRoutes.listen,
                    arguments: {'text': explanation})),
            const SizedBox(height: AppSpacing.sm),
            ContentCard(
                child: Text(explanation,
                    style: AppTextStyles.body.copyWith(height: 1.6))),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Summary (only if different from explanation)
          if (summary.isNotEmpty && summary != explanation) ...[
            SectionHeader(
                title: 'Summary',
                icon: Icons.summarize_rounded,
                onListen: () => Navigator.pushNamed(context, AppRoutes.listen,
                    arguments: {'text': summary})),
            const SizedBox(height: AppSpacing.sm),
            ContentCard(
                child: Text(summary,
                    style: AppTextStyles.body.copyWith(height: 1.6))),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Key Points
          if (keyPoints.isNotEmpty) ...[
            SectionHeader(
                title: 'Key Points',
                icon: Icons.star_rounded,
                onListen: () => Navigator.pushNamed(context, AppRoutes.listen,
                    arguments: {'text': keyPoints.join('. ')})),
            const SizedBox(height: AppSpacing.sm),
            ...keyPoints.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ContentCard(
                child:
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                          child: Text('${entry.key + 1}',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: Text(entry.value,
                          style: AppTextStyles.body.copyWith(height: 1.5))),
                ]),
              ),
            )),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Quiz Builder
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.quiz_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Quiz Questions',
                  style: AppTextStyles.heading2
                      .copyWith(fontWeight: FontWeight.w700)),
            ]),
            TextButton.icon(
                icon:
                const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Question'),
                onPressed: _addQuestion),
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (_qaPairs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text('No questions added yet.',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)),
            )
          else
            ..._qaPairs.asMap().entries.map((entry) {
              final index = entry.key;
              final qa = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(qa['question'] ?? '',
                                  style: AppTextStyles.body
                                      .copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(qa['answer'] ?? '',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.success)),
                            ]),
                      ),
                      Column(children: [
                        IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.primary),
                            onPressed: () => _editQuestion(index)),
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            onPressed: () => _removeQuestion(index)),
                      ]),
                    ]),
              );
            }),
          const SizedBox(height: AppSpacing.lg),

          // Videos
          if (videos.isNotEmpty) ...[
            SectionHeader(
                title: 'Recommended Videos',
                icon: Icons.play_circle_outline_rounded),
            const SizedBox(height: AppSpacing.sm),
            VideoRecommendations(videos: videos),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.surface, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ]),
        child: SafeArea(
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                  (_isSaving || _hasSavedPersonal) ? null : _savePersonal,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: _isSaving
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_hasSavedPersonal ? 'Saved' : 'Save to Library',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isPublishing ? null : _publishToClass,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: _isPublishing
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Text('Publish to Students',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ])),
      ),
    );
  }
}


class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),

      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primary,
          ),

          const SizedBox(width: 4),

          Text(
            label,
            style:
            AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}