// lib/widgets/pdf/document_info_header.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';

class DocumentInfoHeader extends StatelessWidget {
  final String fileName;
  final int currentPage;
  final int totalPages;
  final int? wordCount;
  final String? detectedTopic;
  final bool isAnalyzing;

  const DocumentInfoHeader({
    Key? key,
    required this.fileName,
    required this.currentPage,
    required this.totalPages,
    this.wordCount,
    this.detectedTopic,
    this.isAnalyzing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File name
                Text(
                  fileName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Page count
                Text(
                  totalPages > 0
                      ? 'Page $currentPage of $totalPages'
                      : 'Loading...',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),

                // Analyzing indicator
                if (isAnalyzing)
                  const Text(
                    "Analyzing PDF...",
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),

                // Detected topic
                if (detectedTopic != null && detectedTopic!.isNotEmpty)
                  Text(
                    "Topic: $detectedTopic",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                // Word count
                if (wordCount != null)
                  Text(
                    "Words: $wordCount",
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}