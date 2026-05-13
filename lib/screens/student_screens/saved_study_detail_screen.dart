// lib/screens/student_screens/saved_study_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_routes.dart';
import '../../widgets/ai/content_card.dart';
import '../../widgets/ai/section_header.dart';
import '../../widgets/ai/video_recommendations.dart';

class SavedStudyDetailScreen extends StatefulWidget {
  const SavedStudyDetailScreen({Key? key}) : super(key: key);

  @override
  State<SavedStudyDetailScreen> createState() =>
      _SavedStudyDetailScreenState();
}

class _SavedStudyDetailScreenState extends State<SavedStudyDetailScreen> {
  final TextEditingController _quizCountController =
  TextEditingController(text: "5");
  final TextEditingController _videoCountController =
  TextEditingController(text: "4");

  // These fields are initialised in didChangeDependencies
  late Map<String, dynamic> data;
  String title = '';
  String detectedTopic = '';
  int wordCount = 0;
  String explanation = '';
  String summaryText = '';
  List<String> keyPoints = [];
  List<Map<String, dynamic>> qaPairs = [];
  List<Map<String, dynamic>> videos = [];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)!.settings.arguments
    as Map<String, dynamic>;
    data = args['data'] as Map<String, dynamic>;

    // ---- Safe extraction of summary & explanation ----
    final summaryRaw = data['summary'];
    explanation = (data['explanation'] ?? '').toString();

    if (summaryRaw is Map) {
      summaryText = (summaryRaw['summary'] ?? '').toString();
      if (summaryRaw.containsKey('explanation')) {
        explanation = summaryRaw['explanation'].toString();
      }
      final rawKP = summaryRaw['key_points'];
      keyPoints = rawKP is List ? List<String>.from(rawKP) : [];
    } else if (summaryRaw is String) {
      summaryText = summaryRaw;
      keyPoints = [];
    } else {
      summaryText = '';
      keyPoints = [];
    }

    title = data['title'] ?? 'Untitled Study';
    detectedTopic = data['detected_topic'] ?? '';
    wordCount = data['word_count'] ?? 0;

    final qa = data['qa'] ?? {};
    final rawQaPairs = qa['qa_pairs'];
    qaPairs = rawQaPairs is List
        ? List<Map<String, dynamic>>.from(rawQaPairs)
        : [];

    final youtube = data['youtube'] ?? {};
    final rawVideos = youtube['videos'];
    videos = rawVideos is List
        ? List<Map<String, dynamic>>.from(rawVideos)
        : [];
  }

  @override
  void dispose() {
    _quizCountController.dispose();
    _videoCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.primary),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.studentHome,
                  (route) => false,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic & word count chips
            Wrap(spacing: AppSpacing.sm, children: [
              if (detectedTopic.isNotEmpty)
                _InfoChip(
                  icon: Icons.topic_rounded,
                  label: detectedTopic,
                  color: AppColors.softPurple,
                ),
              if (wordCount > 0)
                _InfoChip(
                  icon: Icons.text_fields_rounded,
                  label: '$wordCount words',
                  color: AppColors.softBlue,
                ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // Explanation
            SectionHeader(
              title: 'Explanation',
              icon: Icons.lightbulb_outline_rounded,
              onListen: explanation.isNotEmpty
                  ? () => Navigator.pushNamed(
                context,
                AppRoutes.listen,
                arguments: {'text': explanation},
              )
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            ContentCard(
              child: Text(
                explanation.isNotEmpty
                    ? explanation
                    : 'No explanation available.',
                style: AppTextStyles.body.copyWith(
                  color: explanation.isNotEmpty
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary
            if (summaryText.isNotEmpty) ...[
              SectionHeader(
                title: 'Summary',
                icon: Icons.summarize_rounded,
                onListen: () => Navigator.pushNamed(
                  context,
                  AppRoutes.listen,
                  arguments: {'text': summaryText},
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ContentCard(
                child: Text(
                  summaryText,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Key Points
            if (keyPoints.isNotEmpty) ...[
              SectionHeader(
                title: 'Key Points',
                icon: Icons.star_rounded,
                onListen: () => Navigator.pushNamed(
                  context,
                  AppRoutes.listen,
                  arguments: {'text': keyPoints.join('. ')},
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...keyPoints.map(
                    (point) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ContentCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${keyPoints.indexOf(point) + 1}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            point,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Quiz & Videos
            SectionHeader(
              title: 'Quiz & Videos',
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            ContentCard(
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.quiz_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Questions',
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _quizCountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Videos',
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _videoCountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.quiz, size: 18),
                    label: const Text('Start Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: qaPairs.isEmpty
                        ? null
                        : () {
                      final count = int.tryParse(_quizCountController.text) ?? 5;
                      Navigator.pushNamed(
                        context,
                        AppRoutes.flipQuiz,
                        arguments: {'questionCount': count, 'qaPairs': qaPairs},
                      );
                    },
                  ),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Videos
            SectionHeader(
              title: 'Recommended Videos',
              icon: Icons.play_circle_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            videos.isNotEmpty
                ? VideoRecommendations(
                videos: videos.take(int.tryParse(_videoCountController.text) ?? 4).toList())
                : const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: Text('No videos found for this content.', style: TextStyle(color: Colors.grey))),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}