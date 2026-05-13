// lib/screens/ai/ai_features_screen.dart

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

class AIFeaturesScreen extends StatefulWidget {
  const AIFeaturesScreen({Key? key}) : super(key: key);

  @override
  State<AIFeaturesScreen> createState() =>
      _AIFeaturesScreenState();
}

class _AIFeaturesScreenState
    extends State<AIFeaturesScreen> {
  final TextEditingController _quizCountController =
  TextEditingController(text: "5");

  final TextEditingController _videoCountController =
  TextEditingController(text: "4");

  final TextEditingController _lessonNameController =
  TextEditingController();

  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      final args =
      ModalRoute.of(context)?.settings.arguments
      as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _lessonNameController.text =
              args?['title'] ?? 'My Lesson';
        });
      }
    });
  }

  Future<void> _saveToRecentStudies() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final lessonName =
    _lessonNameController.text.trim();

    if (lessonName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a lesson name',
          ),
        ),
      );
      return;
    }

    final args =
    ModalRoute.of(context)!
        .settings
        .arguments as Map<String, dynamic>;

    final apiResult =
    args['apiResult']
    as Map<String, dynamic>?;

    if (apiResult == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text('No data to save'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final summaryText =
      (apiResult['summary'] ?? '')
          .toString();

      final keyPointsList =
      List.from(
        apiResult['key_points'] ?? [],
      );

      final videosList =
      List.from(
        (apiResult['youtube'] ?? {})['videos'] ??
            [],
      );

      await FirebaseFirestore.instance
          .collection('user_studies')
          .add({
        'userId': user.uid,

        'title': lessonName,

        'type':
        (apiResult['file_name']
            ?.toString()
            .endsWith('.pdf') ??
            false)
            ? 'pdf'
            : 'text',

        'detected_topic':
        (apiResult['detected_topic'] ?? '')
            .toString(),

        'word_count':
        apiResult['word_count'] ?? 0,

        'explanation':
        (apiResult['explanation'] ?? '')
            .toString(),

        // UPDATED STRUCTURE
        'summary': summaryText,

        'key_points': keyPointsList,

        'youtube': {
          'videos': videosList,
        },

        'qa':
        apiResult['qa'] ?? {},

        'createdAt':
        FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _saved = true;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Lesson saved to Recent Studies',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Save failed: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _quizCountController.dispose();
    _videoCountController.dispose();
    _lessonNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments
    as Map<String, dynamic>?;

    final String title =
        args?['title'] ?? 'Document';

    final Map<String, dynamic>? apiResult =
    args?['apiResult'];

    if (apiResult == null) {
      return Scaffold(
        backgroundColor:
        AppColors.scaffoldBackground,

        appBar: AppBar(
          backgroundColor:
          AppColors.surface,

          elevation: 0,

          leading: IconButton(
            icon: const Icon(
              Icons.home_outlined,
              color: AppColors.primary,
            ),
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.studentHome,
                      (route) => false,
                ),
          ),

          title: Text(
            title,
            style: AppTextStyles.heading3
                .copyWith(
              color: AppColors.primary,
            ),
          ),

          centerTitle: true,
        ),

        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(
              AppSpacing.xl,
            ),

            child: Text(
              'No AI results available.\nPlease upload a document and try again.',

              textAlign: TextAlign.center,

              style: AppTextStyles.body.copyWith(
                color:
                AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    // ================= UPDATED API STRUCTURE =================

    final String summary =
    (apiResult['summary'] ?? '')
        .toString();

    final List<String> keyPoints =
    List<String>.from(
      apiResult['key_points'] ?? [],
    );

    final String explanation =
    (apiResult['explanation'] ?? '')
        .toString();

    final qaData =
        apiResult['qa'] ?? {};

    final List<Map<String, dynamic>>
    qaPairs =
    List<Map<String, dynamic>>.from(
      qaData['qa_pairs'] ?? [],
    );

    final youtubeData =
        apiResult['youtube'] ?? {};

    final List<Map<String, dynamic>>
    videos =
    List<Map<String, dynamic>>.from(
      youtubeData['videos'] ?? [],
    );

    final String detectedTopic =
    (apiResult['detected_topic'] ?? '')
        .toString();

    final int wordCount =
        apiResult['word_count'] ?? 0;

    return Scaffold(
      backgroundColor:
      AppColors.scaffoldBackground,

      appBar: AppBar(
        backgroundColor:
        AppColors.surface,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.home_outlined,
            color: AppColors.primary,
          ),

          onPressed: () =>
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.studentHome,
                    (route) => false,
              ),
        ),

        title: Text(
          title,

          style: AppTextStyles.heading3
              .copyWith(
            color: AppColors.primary,
          ),

          overflow: TextOverflow.ellipsis,
        ),

        centerTitle: true,

        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : Icon(
              _saved
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color:
              AppColors.primary,
            ),

            onPressed:
            (!_isSaving)
                ? _saveToRecentStudies
                : null,

            tooltip: 'Save Lesson',
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          AppSpacing.md,
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            TextField(
              controller:
              _lessonNameController,

              style:
              AppTextStyles.heading2
                  .copyWith(
                color: AppColors.primary,
              ),

              decoration: InputDecoration(
                labelText: 'Lesson Name',

                hintText:
                'Enter a name for this lesson',

                filled: true,

                fillColor:
                AppColors.surface,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),

                  borderSide: BorderSide(
                    color:
                    AppColors.divider,
                  ),
                ),

                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),

                  borderSide:
                  const BorderSide(
                    color:
                    AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: AppSpacing.md,
            ),

            Padding(
              padding:
              const EdgeInsets.only(
                bottom: AppSpacing.md,
              ),

              child: Wrap(
                spacing: AppSpacing.sm,

                children: [
                  _InfoChip(
                    icon:
                    Icons.topic_rounded,
                    label: detectedTopic,
                    color:
                    AppColors.softPurple,
                  ),

                  _InfoChip(
                    icon: Icons
                        .text_fields_rounded,
                    label:
                    '$wordCount words',
                    color:
                    AppColors.softBlue,
                  ),
                ],
              ),
            ),

            // ================= EXPLANATION =================

            SectionHeader(
              title: 'Explanation',
              icon: Icons
                  .lightbulb_outline_rounded,

              onListen: () =>
                  Navigator.pushNamed(
                    context,
                    AppRoutes.listen,
                    arguments: {
                      'text': explanation,
                    },
                  ),
            ),

            const SizedBox(
              height: AppSpacing.sm,
            ),

            ContentCard(
              child: Text(
                explanation.isNotEmpty
                    ? explanation
                    : 'No explanation generated for this document.',

                style:
                AppTextStyles.body
                    .copyWith(
                  color:
                  explanation.isNotEmpty
                      ? AppColors
                      .textPrimary
                      : AppColors
                      .textSecondary,

                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            // ================= SUMMARY =================

            if (summary.isNotEmpty) ...[
              SectionHeader(
                title: 'Summary',
                icon:
                Icons.summarize_rounded,

                onListen: () =>
                    Navigator.pushNamed(
                      context,
                      AppRoutes.listen,
                      arguments: {
                        'text': summary,
                      },
                    ),
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              ContentCard(
                child: Text(
                  summary,

                  style:
                  AppTextStyles.body
                      .copyWith(
                    color: AppColors
                        .textPrimary,

                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(
                height: AppSpacing.lg,
              ),
            ],

            // ================= KEY POINTS =================

            if (keyPoints.isNotEmpty) ...[
              SectionHeader(
                title: 'Key Points',
                icon: Icons.star_rounded,

                onListen: () =>
                    Navigator.pushNamed(
                      context,
                      AppRoutes.listen,
                      arguments: {
                        'text':
                        keyPoints.join('. '),
                      },
                    ),
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              ...keyPoints.map(
                    (point) => Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom: AppSpacing.sm,
                  ),

                  child: ContentCard(
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [
                        Container(
                          width: 28,
                          height: 28,

                          decoration:
                          BoxDecoration(
                            color: AppColors
                                .primary
                                .withOpacity(
                                0.1),

                            borderRadius:
                            BorderRadius
                                .circular(
                              8,
                            ),
                          ),

                          child: Center(
                            child: Text(
                              '${keyPoints.indexOf(point) + 1}',

                              style:
                              AppTextStyles
                                  .caption
                                  .copyWith(
                                color:
                                AppColors
                                    .primary,

                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width:
                          AppSpacing.md,
                        ),

                        Expanded(
                          child: Text(
                            point,

                            style:
                            AppTextStyles
                                .body
                                .copyWith(
                              color: AppColors
                                  .textPrimary,

                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: AppSpacing.lg,
              ),
            ],

            // ================= QUIZ =================

            SectionHeader(
              title: 'Quiz & Videos',
              icon: Icons.tune_rounded,
            ),

            const SizedBox(
              height: AppSpacing.sm,
            ),

            ContentCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        color:
                        AppColors.primary,
                        size: 20,
                      ),

                      const SizedBox(
                        width:
                        AppSpacing.sm,
                      ),

                      Expanded(
                        child: Text(
                          'Questions',

                          style:
                          AppTextStyles
                              .body
                              .copyWith(
                            fontWeight:
                            FontWeight
                                .w600,

                            color: AppColors
                                .textPrimary,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 60,

                        child: TextField(
                          controller:
                          _quizCountController,

                          keyboardType:
                          TextInputType
                              .number,

                          textAlign:
                          TextAlign.center,

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

                          style:
                          AppTextStyles.body
                              .copyWith(
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: AppSpacing.sm,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .play_circle_outline,
                        color:
                        AppColors.primary,
                        size: 20,
                      ),

                      const SizedBox(
                        width:
                        AppSpacing.sm,
                      ),

                      Expanded(
                        child: Text(
                          'Videos',

                          style:
                          AppTextStyles
                              .body
                              .copyWith(
                            fontWeight:
                            FontWeight
                                .w600,

                            color: AppColors
                                .textPrimary,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 60,

                        child: TextField(
                          controller:
                          _videoCountController,

                          keyboardType:
                          TextInputType
                              .number,

                          textAlign:
                          TextAlign.center,

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

                          style:
                          AppTextStyles.body
                              .copyWith(
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: AppSpacing.md,
                  ),

                  SizedBox(
                    width: double.infinity,

                    child:
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.quiz,
                        size: 18,
                      ),

                      label:
                      const Text(
                        'Start Quiz',
                      ),

                      style:
                      ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        AppColors
                            .primary,

                        foregroundColor:
                        AppColors
                            .surface,

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                        ),
                      ),

                      onPressed: () {
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

                            'qaPairs':
                            qaPairs,
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            // ================= VIDEOS =================

            SectionHeader(
              title: 'Recommended Videos',
              icon: Icons
                  .play_circle_outline_rounded,
            ),

            const SizedBox(
              height: AppSpacing.sm,
            ),

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
              padding:
              EdgeInsets.symmetric(
                vertical:
                AppSpacing.lg,
              ),

              child: Center(
                child: Text(
                  'No videos found for this content.',

                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: AppSpacing.xxl,
            ),
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
      padding:
      const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),

      decoration: BoxDecoration(
        color: color,

        borderRadius:
        BorderRadius.circular(20),
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
            AppTextStyles.caption
                .copyWith(
              color: AppColors.primary,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}