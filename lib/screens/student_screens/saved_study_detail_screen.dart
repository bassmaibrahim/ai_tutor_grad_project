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

class _SavedStudyDetailScreenState
    extends State<SavedStudyDetailScreen> {
  final TextEditingController _quizCountController =
  TextEditingController(text: "5");

  final TextEditingController _videoCountController =
  TextEditingController(text: "4");

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

    final args =
    ModalRoute.of(context)!.settings.arguments
    as Map<String, dynamic>;

    data = args['data'] as Map<String, dynamic>;

    // ---------------- BASIC INFO ----------------

    title = (data['title'] ?? 'Untitled Study').toString();

    detectedTopic =
        (data['detected_topic'] ?? '').toString();

    wordCount = data['word_count'] is int
        ? data['word_count']
        : int.tryParse(
        data['word_count']?.toString() ?? '0') ??
        0;

    explanation =
        (data['explanation'] ?? '').toString();

    // ---------------- SUMMARY ----------------

    final summaryRaw = data['summary'];

    if (summaryRaw is Map) {
      // summary text
      summaryText =
          (summaryRaw['summary'] ?? '').toString();

      // explanation fallback
      if (explanation.isEmpty &&
          summaryRaw['explanation'] != null) {
        explanation =
            summaryRaw['explanation'].toString();
      }

      // key points
      final rawKP = summaryRaw['key_points'];

      if (rawKP is List) {
        keyPoints = rawKP
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } else if (summaryRaw is String) {
      summaryText = summaryRaw;

      // fallback root-level key_points
      final rawKP = data['key_points'];

      if (rawKP is List) {
        keyPoints = rawKP
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // ---------------- QA ----------------

    final qa = data['qa'];

    if (qa is Map<String, dynamic>) {
      final rawQaPairs = qa['qa_pairs'];

      if (rawQaPairs is List) {
        qaPairs = rawQaPairs
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    // ---------------- VIDEOS ----------------

    final youtube = data['youtube'];

    if (youtube is Map<String, dynamic>) {
      final rawVideos = youtube['videos'];

      if (rawVideos is List) {
        videos = rawVideos
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    // ---------------- DEBUG ----------------

    debugPrint('SUMMARY RAW: $summaryRaw');
    debugPrint('KEY POINTS: $keyPoints');
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
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primary,
          ),
          overflow: TextOverflow.ellipsis,
        ),

        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.home_outlined,
              color: AppColors.primary,
            ),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.studentHome,
                    (route) => false,
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ---------------- CHIPS ----------------

            Wrap(
              spacing: AppSpacing.sm,
              children: [
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
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ---------------- EXPLANATION ----------------

            SectionHeader(
              title: 'Explanation',
              icon: Icons.lightbulb_outline_rounded,

              onListen: explanation.isNotEmpty
                  ? () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.listen,
                  arguments: {
                    'text': explanation,
                  },
                );
              }
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

            // ---------------- SUMMARY ----------------

            if (summaryText.trim().isNotEmpty) ...[
              SectionHeader(
                title: 'Summary',
                icon: Icons.summarize_rounded,

                onListen: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.listen,
                    arguments: {
                      'text': summaryText,
                    },
                  );
                },
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

            // ---------------- KEY POINTS ----------------

            if (keyPoints.isNotEmpty) ...[
              SectionHeader(
                title: 'Key Points',
                icon: Icons.star_rounded,

                onListen: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.listen,
                    arguments: {
                      'text': keyPoints.join('. '),
                    },
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              ...List.generate(
                keyPoints.length,
                    (index) {
                  final point = keyPoints[index];

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.sm,
                    ),

                    child: ContentCard(
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [
                          Container(
                            width: 28,
                            height: 28,

                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.1),

                              borderRadius:
                              BorderRadius.circular(8),
                            ),

                            child: Center(
                              child: Text(
                                '${index + 1}',

                                style: AppTextStyles.caption
                                    .copyWith(
                                  color: AppColors.primary,
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: AppSpacing.md,
                          ),

                          Expanded(
                            child: Text(
                              point,

                              style:
                              AppTextStyles.body.copyWith(
                                color:
                                AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),
            ],

            // ---------------- QUIZ ----------------

            SectionHeader(
              title: 'Quiz & Videos',
              icon: Icons.tune_rounded,
            ),

            const SizedBox(height: AppSpacing.sm),

            ContentCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),

                      const SizedBox(
                        width: AppSpacing.sm,
                      ),

                      Expanded(
                        child: Text(
                          'Questions',

                          style:
                          AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                            AppColors.textPrimary,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 60,

                        child: TextField(
                          controller:
                          _quizCountController,

                          keyboardType:
                          TextInputType.number,

                          textAlign: TextAlign.center,

                          decoration:
                          const InputDecoration(
                            border:
                            OutlineInputBorder(),
                            isDense: true,
                            contentPadding:
                            EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.quiz),

                      label: const Text('Start Quiz'),

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        AppColors.primary,

                        foregroundColor:
                        AppColors.surface,

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),

                      onPressed: qaPairs.isEmpty
                          ? null
                          : () {
                        final count =
                            int.tryParse(
                              _quizCountController
                                  .text,
                            ) ??
                                5;

                        Navigator.pushNamed(
                          context,
                          AppRoutes.flipQuiz,
                          arguments: {
                            'questionCount':
                            count,
                            'qaPairs': qaPairs,
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ---------------- VIDEOS ----------------

            SectionHeader(
              title: 'Recommended Videos',
              icon:
              Icons.play_circle_outline_rounded,
            ),

            const SizedBox(height: AppSpacing.sm),

            videos.isNotEmpty
                ? VideoRecommendations(
              videos: videos
                  .take(
                int.tryParse(
                  _videoCountController
                      .text,
                ) ??
                    4,
              )
                  .toList(),
            )
                : const Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
              ),

              child: Center(
                child: Text(
                  'No videos found for this content.',

                  style:
                  TextStyle(color: Colors.grey),
                ),
              ),
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

            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}