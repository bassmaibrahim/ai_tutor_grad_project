import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';
import '../../../widgets/ai/section_header.dart';
import '../../../widgets/ai/content_card.dart';
import '../../../widgets/ai/video_recommendations.dart';

class LessonViewScreen extends StatelessWidget {
  const LessonViewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final lesson = args['lesson'] as Map<String, dynamic>;

    final title = lesson['title'] ?? 'Untitled Lesson';
    final explanation = lesson['explanation'] ?? '';
    final summary = (lesson['summary']?['summary'] ?? '').toString();
    final keyPoints = List<String>.from(lesson['summary']?['key_points'] ?? []);
    final qaPairs = List<Map<String, dynamic>>.from((lesson['qa']?['qa_pairs'] ?? []));
    final videos = List<Map<String, dynamic>>.from((lesson['youtube']?['videos'] ?? []));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
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
              SectionHeader(title: 'Explanation', icon: Icons.lightbulb_outline_rounded),
              const SizedBox(height: AppSpacing.sm),
              ContentCard(child: Text(explanation, style: AppTextStyles.body.copyWith(height: 1.6))),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (summary.isNotEmpty) ...[
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
            ],
            if (qaPairs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(title: 'Questions & Answers', icon: Icons.quiz_rounded),
              ...qaPairs.map((q) => _QACard(question: q['question'] ?? '', answer: q['answer'] ?? '')),
            ],
            if (videos.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(title: 'Recommended Videos', icon: Icons.play_circle_outline_rounded),
              const SizedBox(height: AppSpacing.sm),
              VideoRecommendations(videos: videos),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
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
          Text(question, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(answer, style: AppTextStyles.caption.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}