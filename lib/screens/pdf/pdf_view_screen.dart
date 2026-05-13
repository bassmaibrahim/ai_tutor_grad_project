// lib/screens/pdf/pdf_view_screen.dart

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
import '../../widgets/document/DocumentInfoHeader.dart';
import '../../widgets/document/PdfViewerWidget.dart';

class PdfViewScreen extends StatefulWidget {
  const PdfViewScreen({Key? key}) : super(key: key);

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  Uint8List? _bytes;
  String? _filePath;
  String _fileName = 'Document';

  int _currentPage = 1;
  int _totalPages = 0;

  bool _initialized = false;
  bool _isAnalyzing = false;
  bool _isSaved = false;

  String? _error;

  Map<String, dynamic>? _apiResult;

  int? _wordCount;
  String? _detectedTopic;

  bool get isReady => _apiResult != null && !_isAnalyzing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final args =
    ModalRoute.of(context)?.settings.arguments
    as Map<String, dynamic>?;

    _bytes = args?['bytes'];
    _filePath = args?['path'];
    _fileName = args?['title'] ?? 'Document';

    if (_bytes != null && _bytes!.isNotEmpty) {
      _analyzePdf();
    } else {
      setState(() {
        _error = 'No PDF file received. Please try again.';
      });
    }
  }

  Future<void> _analyzePdf() async {
    if (_bytes == null || _bytes!.isEmpty) {
      setState(() {
        _error = 'No document data to process.';
        _isAnalyzing = false;
      });
      return;
    }

    try {
      setState(() {
        _isAnalyzing = true;
        _error = null;
      });

      debugPrint('========== PDF ANALYSIS START ==========');
      debugPrint('File Name: $_fileName');
      debugPrint('Bytes Length: ${_bytes!.length}');
      debugPrint('========================================');

      final result = await ApiService.processDocument(
        fileBytes: _bytes!,
        fileName: _fileName,
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
        _wordCount = result['word_count'];
        _detectedTopic = result['detected_topic'];
        _isAnalyzing = false;
      });

      await _saveToRecentStudies();
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        _error =
        'The server is starting up or processing a large PDF. Please try again in a moment.';
      });
    } catch (e) {
      debugPrint('========== ANALYSIS ERROR ==========');
      debugPrint(e.toString());
      debugPrint('====================================');

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        _error = _friendlyErrorMessage(e.toString());
      });
    }
  }

  String _friendlyErrorMessage(String raw) {
    debugPrint('RAW ERROR: $raw');

    if (raw.contains('TimeoutException')) {
      return 'Server is waking up. Please try again shortly.';
    }

    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }

    if (raw.contains('API Failed: 404') ||
        raw.contains('detail not found')) {
      return 'The AI service is temporarily unavailable.';
    }

    if (raw.contains('API Failed: 413') ||
        raw.contains('too large')) {
      return 'This file is too large (max 50MB). Please choose a smaller file.';
    }

    if (raw.contains('500')) {
      return 'Server error while processing the document.';
    }

    if (raw.length > 120) {
      return 'Something went wrong while analyzing the PDF.';
    }

    return raw;
  }

  Future<void> _saveToRecentStudies() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null ||
          _apiResult == null ||
          _bytes == null) {
        return;
      }

      final Map<String, dynamic> data = {
        'userId': user.uid,
        'title': _fileName,
        'type': 'pdf',

        'summary': _apiResult!['summary'] ?? '',
        'key_points': _apiResult!['key_points'] ?? [],
        'explanation': _apiResult!['explanation'] ?? '',

        'youtube': _apiResult!['youtube'] ?? {},
        'qa': _apiResult!['qa'] ?? {},

        'detected_topic': _detectedTopic,
        'word_count': _wordCount,

        'fileUrl': '',

        'createdAt': FieldValue.serverTimestamp(),
      };

      // Prevent huge memory usage
      if (_bytes!.length < 600000) {
        final base64Pdf = base64Encode(_bytes!);
        data['fileBytes'] = base64Pdf;
      } else {
        debugPrint(
          '⚠️ PDF too large for Firestore base64 storage',
        );
      }

      await FirebaseFirestore.instance
          .collection('user_studies')
          .add(data);

      if (!mounted) return;

      setState(() {
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF saved to Recent Studies'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('SAVE ERROR: $e');
    }
  }

  void _onLoaded(int pages) {
    if (!mounted) return;

    setState(() {
      _totalPages = pages;
    });
  }

  void _onPageChanged(int page) {
    if (!mounted) return;

    setState(() {
      _currentPage = page;
    });
  }

  void _onLoadFailed(String error) {
    if (!mounted) return;

    setState(() {
      _error = error;
    });
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
          _fileName,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primary,
          ),
        ),

        centerTitle: true,

        actions: [
          if (_isSaved)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(
                Icons.bookmark,
                color: AppColors.primary,
              ),
            ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),

          child: Column(
            children: [
              DocumentInfoHeader(
                fileName: _fileName,
                currentPage: _currentPage,
                totalPages: _totalPages,
                wordCount: _wordCount,
                detectedTopic: _detectedTopic,
                isAnalyzing: _isAnalyzing,
              ),

              const SizedBox(height: AppSpacing.md),

              if (_isAnalyzing)
                Column(
                  children: [
                    LinearProgressIndicator(
                      color: AppColors.primary,
                      backgroundColor:
                      AppColors.primary.withOpacity(0.1),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Analyzing PDF with AI...\nThis may take up to 2 minutes.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.sm,
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),

                    child: _bytes != null
                        ? PdfViewerWidget(
                      fileBytes: _bytes,
                      filePath: _filePath,

                      onDocumentLoaded: _onLoaded,
                      onPageChanged: _onPageChanged,
                      onLoadFailed: _onLoadFailed,
                    )
                        : const Center(
                      child: Text(
                        'No PDF to display',
                        style: TextStyle(
                          color: Colors.grey,
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

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),

        child: SmartAIActionButton(
          onTap: () {
            if (!isReady) {
              ScaffoldMessenger.of(context).showSnackBar(
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
                'title': _fileName,
                'apiResult': _apiResult,
              },
            );
          },
        ),
      ),
    );
  }
}