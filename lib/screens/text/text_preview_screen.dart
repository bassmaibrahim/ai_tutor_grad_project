// lib/screens/text/text_preview_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';

import '../../services/api_service.dart';

import '../../widgets/button/SmartAIActionButton.dart';

class TextPreviewScreen extends StatefulWidget {
  const TextPreviewScreen({Key? key}) : super(key: key);

  @override
  State<TextPreviewScreen> createState() =>
      _TextPreviewScreenState();
}

class _TextPreviewScreenState
    extends State<TextPreviewScreen> {
  bool _isAnalyzing = false;

  bool _isSaved = false;

  Map<String, dynamic>? _apiResult;

  String? _error;

  late String _text;
  late String _title;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
    ModalRoute.of(context)!
        .settings
        .arguments as Map<String, dynamic>;

    _text = args['text'] ?? '';
    _title = args['title'] ?? 'Pasted Text';
  }

  bool get isReady =>
      _apiResult != null && !_isAnalyzing;

  // ================= ANALYZE TEXT =================

  Future<void> _analyzeAndSave() async {
    try {
      setState(() {
        _isAnalyzing = true;
        _error = null;
      });

      debugPrint('========== TEXT ANALYSIS START ==========');
      debugPrint('Title: $_title');
      debugPrint('Characters: ${_text.length}');
      debugPrint('=========================================');

      // Convert text into bytes like txt file
      final Uint8List textBytes =
      Uint8List.fromList(
        utf8.encode(_text),
      );

      final result =
      await ApiService.processDocument(
        fileBytes: textBytes,
        fileName: '$_title.txt',

        includeSummary: true,
        includeQA: true,
        includeYoutube: true,
        includeExplanation: true,

        numVideos: 10,
        numQuestions: 10,
      ).timeout(
        const Duration(minutes: 2),
      );

      debugPrint('========== API RESULT ==========');
      debugPrint(result.toString());
      debugPrint('================================');

      if (!mounted) return;

      setState(() {
        _apiResult = result;
        _isAnalyzing = false;
      });

      await _saveToRecentStudies();
    } on TimeoutException {
      debugPrint('TEXT ANALYSIS TIMEOUT');

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;

        _error =
        'The server is starting up or processing your text. Please try again shortly.';
      });
    } catch (e) {
      debugPrint('TEXT ANALYSIS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        _error = _friendlyErrorMessage(
          e.toString(),
        );
      });
    }
  }

  // ================= FRIENDLY ERRORS =================

  String _friendlyErrorMessage(String raw) {
    debugPrint('RAW ERROR: $raw');

    if (raw.contains('TimeoutException')) {
      return 'Server is waking up. Please try again.';
    }

    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup')) {
      return 'No internet connection.';
    }

    if (raw.contains('413') ||
        raw.contains('too large')) {
      return 'The text is too large to process.';
    }

    if (raw.contains('500')) {
      return 'Server error while analyzing text.';
    }

    if (raw.length > 120) {
      return 'Something went wrong during text analysis.';
    }

    return raw;
  }

  // ================= SAVE TO FIRESTORE =================

  Future<void> _saveToRecentStudies() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null || _apiResult == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('user_studies')
          .add({
        'userId': user.uid,

        'title': _title,

        'type': 'text',

        'rawText': _text,

        'summary':
        _apiResult?['summary'] ?? '',

        'key_points':
        _apiResult?['key_points'] ?? [],

        'explanation':
        _apiResult?['explanation'] ?? '',

        'youtube':
        _apiResult?['youtube'] ?? {},

        'qa':
        _apiResult?['qa'] ?? {},

        'detected_topic':
        _apiResult?['detected_topic'] ?? '',

        'word_count':
        _apiResult?['word_count'] ?? 0,

        'createdAt':
        FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _isSaved = true;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Saved to Recent Studies',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint(
        'Failed to save text to Firestore: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,

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
          _title,

          overflow: TextOverflow.ellipsis,

          style:
          AppTextStyles.heading3.copyWith(
            color: AppColors.primary,
          ),
        ),

        centerTitle: true,

        actions: [
          if (_isSaved)
            const Padding(
              padding: EdgeInsets.only(
                right: AppSpacing.sm,
              ),
              child: Icon(
                Icons.bookmark,
                color: AppColors.primary,
              ),
            ),
        ],
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(AppSpacing.lg),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            if (_isAnalyzing) ...[
              LinearProgressIndicator(
                color: AppColors.primary,

                backgroundColor:
                AppColors.primary
                    .withOpacity(0.1),
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              Text(
                'Analyzing text with AI...\nThis may take up to 2 minutes.',

                style:
                AppTextStyles.caption
                    .copyWith(
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(
                height: AppSpacing.md,
              ),
            ],

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.sm,
                ),

                child: Text(
                  _error!,

                  style:
                  AppTextStyles.caption
                      .copyWith(
                    color: Colors.red,
                  ),
                ),
              ),

            Expanded(
              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(
                  AppSpacing.md,
                ),

                decoration: BoxDecoration(
                  color:
                  AppColors.scaffoldBackground,

                  borderRadius:
                  BorderRadius.circular(12),

                  border: Border.all(
                    color: AppColors.divider,
                  ),
                ),

                child: SingleChildScrollView(
                  child: Text(
                    _text,

                    style:
                    AppTextStyles.body
                        .copyWith(
                      color:
                      AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          if (!_isAnalyzing &&
              _apiResult == null)
            Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),

              child: SizedBox(
                width: double.infinity,
                height: 48,

                child: ElevatedButton.icon(
                  onPressed:
                  _analyzeAndSave,

                  icon: const Icon(
                    Icons.auto_awesome,
                  ),

                  label: const Text(
                    'Analyze with AI',
                  ),

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
                ),
              ),
            ),

          if (_apiResult != null ||
              _isAnalyzing)
            Padding(
              padding:
              const EdgeInsets.all(12),

              child: SmartAIActionButton(
                onTap: () {
                  if (!isReady) {
                    ScaffoldMessenger.of(
                        context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please wait for AI analysis to complete',
                        ),
                      ),
                    );

                    return;
                  }

                  Navigator.pushNamed(
                    context,
                    AppRoutes.aiFeatures,
                    arguments: {
                      'title': _title,
                      'apiResult': _apiResult,
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}