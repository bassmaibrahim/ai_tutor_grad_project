// lib/screens/teacher/ai_processing_screen.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_routes.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';

import '../../../services/api_service.dart';

class AIProcessingScreen extends StatefulWidget {
  const AIProcessingScreen({Key? key}) : super(key: key);

  @override
  State<AIProcessingScreen> createState() =>
      _AIProcessingScreenState();
}

class _AIProcessingScreenState
    extends State<AIProcessingScreen> {
  int _currentStep = 0;

  final List<String> _steps = [
    'Extracting Content',
    'Analyzing Text',
    'Generating Summary',
    'Creating Questions',
    'Finding Videos',
    'Finalizing Lesson',
  ];

  bool _completed = false;

  String? _errorMessage;

  Map<String, dynamic>? _apiResult;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  Future<void> _startProcessing() async {
    final args =
    ModalRoute.of(context)?.settings.arguments
    as Map<String, dynamic>?;

    final lessonData =
    args?['lessonData'] as Map<String, dynamic>?;

    if (lessonData == null) {
      _handleError('No lesson data provided');
      return;
    }

    final fileBytes =
    lessonData['fileBytes'] as List<int>?;

    final fileName =
        lessonData['fileName'] as String? ??
            'lesson_content.pdf';

    if (fileBytes == null || fileBytes.isEmpty) {
      _handleError('No file to process');
      return;
    }

    try {
      debugPrint('========== TEACHER PROCESS START ==========');
      debugPrint('File Name: $fileName');
      debugPrint('Bytes Length: ${fileBytes.length}');
      debugPrint('===========================================');

      final stepFuture = _runStepAnimation();

      final apiFuture = _callApi(
        fileBytes,
        fileName,
        lessonData,
      ).timeout(
        const Duration(minutes: 2),
      );

      await Future.wait([
        stepFuture,
        apiFuture,
      ]);

      if (!mounted) return;

      setState(() {
        _completed = true;

        if (_apiResult == null) {
          _errorMessage =
          'The AI could not fully process this lesson.';
        }
      });
    } on TimeoutException {
      debugPrint('PROCESS TIMEOUT');

      if (!mounted) return;

      setState(() {
        _completed = true;

        _errorMessage =
        'The server is starting up or processing a large document. You can still preview the lesson.';
      });
    } catch (e) {
      debugPrint('PROCESS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _completed = true;

        _errorMessage =
        'Something went wrong during AI processing.';
      });
    }
  }

  Future<void> _runStepAnimation() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(
        const Duration(milliseconds: 1500),
      );

      if (!mounted) return;

      setState(() {
        _currentStep = i + 1;
      });
    }
  }

  Future<void> _callApi(
      List<int> fileBytes,
      String fileName,
      Map<String, dynamic> lessonData,
      ) async {
    try {
      final bytes = Uint8List.fromList(fileBytes);

      final videosCount =
          int.tryParse(
            '${lessonData['videosCount'] ?? 10}',
          ) ??
              10;

      final questionsCount =
          int.tryParse(
            '${lessonData['questionsCount'] ?? 10}',
          ) ??
              10;

      debugPrint('========== API CALL ==========');
      debugPrint('File: $fileName');
      debugPrint('Size: ${bytes.length} bytes');
      debugPrint('Videos: $videosCount');
      debugPrint('Questions: $questionsCount');
      debugPrint('==============================');

      final result =
      await ApiService.processDocument(
        fileBytes: bytes,
        fileName: fileName,

        includeSummary: true,
        includeQA: true,
        includeYoutube: true,
        includeExplanation: true,

        numVideos: videosCount,
        numQuestions: questionsCount,
      );

      debugPrint('========== API RESULT ==========');
      debugPrint(result.toString());
      debugPrint('================================');

      _apiResult = result;
    } catch (e) {
      debugPrint('API CALL FAILED: $e');

      _apiResult = null;
    }
  }

  void _handleError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    Navigator.pop(context);
  }

  void _goToPreview() {
    final args =
    ModalRoute.of(context)?.settings.arguments
    as Map<String, dynamic>?;

    final classData = args?['classData'];

    final lessonData =
    args?['lessonData'];

    final result = _apiResult ??
        {
          'summary': '',
          'key_points': [],
          'explanation': '',
          'qa': {
            'qa_pairs': [],
          },
          'youtube': {
            'videos': [],
          },
        };

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.lessonPreview,
      arguments: {
        'classData': classData,
        'result': result,
        'lessonTitle':
        lessonData?['title'] ??
            'Untitled Lesson',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.scaffoldBackground,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        centerTitle: true,

        title: Text(
          'AI Processing',
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
          ),

          child: Column(
            children: [
              const Spacer(flex: 1),

              Text(
                _completed
                    ? 'Processing Complete!'
                    : 'AI is processing your lesson',

                textAlign: TextAlign.center,

                style:
                AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              if (!_completed)
                Text(
                  'This may take up to 2 minutes depending on the document size.',
                  textAlign: TextAlign.center,
                  style:
                  AppTextStyles.caption.copyWith(
                    color:
                    AppColors.textSecondary,
                  ),
                ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                  ),

                  child: Text(
                    _errorMessage!,

                    textAlign: TextAlign.center,

                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              ..._steps
                  .asMap()
                  .entries
                  .map((entry) {
                final stepIndex =
                    entry.key + 1;

                final isActive =
                    _currentStep >= stepIndex;

                final isCurrent =
                    _currentStep ==
                        stepIndex - 1 &&
                        !_completed;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.sm,
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          color: isActive
                              ? AppColors.success
                              .withOpacity(
                              0.15)
                              : (isCurrent
                              ? AppColors
                              .primary
                              .withOpacity(
                              0.15)
                              : AppColors
                              .divider
                              .withOpacity(
                              0.4)),
                        ),

                        child: Center(
                          child: isActive
                              ? const Icon(
                            Icons.check,
                            color:
                            AppColors
                                .success,
                            size: 18,
                          )
                              : (isCurrent
                              ? SizedBox(
                            width: 16,
                            height: 16,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2,
                              color:
                              AppColors
                                  .primary,
                            ),
                          )
                              : Text(
                            '$stepIndex',
                            style:
                            AppTextStyles
                                .caption
                                .copyWith(
                              color: AppColors
                                  .textSecondary,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          )),
                        ),
                      ),

                      const SizedBox(
                        width: AppSpacing.md,
                      ),

                      Expanded(
                        child: Text(
                          entry.value,

                          style:
                          AppTextStyles.body
                              .copyWith(
                            color: isActive
                                ? AppColors
                                .success
                                : (isCurrent
                                ? AppColors
                                .primary
                                : AppColors
                                .textSecondary),

                            fontWeight:
                            isCurrent
                                ? FontWeight
                                .w600
                                : FontWeight
                                .w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const Spacer(flex: 1),

              if (_completed)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.xl,
                  ),

                  child: SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton.icon(
                      onPressed: _goToPreview,

                      icon: const Icon(
                        Icons.visibility_rounded,
                      ),

                      label: const Text(
                        'View Lesson',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        AppColors.primary,

                        foregroundColor:
                        Colors.white,

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}