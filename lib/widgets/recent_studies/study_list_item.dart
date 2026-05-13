// lib/widgets/recent_studies/study_list_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';

class StudyListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onTap;

  const StudyListItem({
    Key? key,
    required this.data,
    required this.docId,
    required this.onTap,
  }) : super(key: key);

  List<Color> _cardColors() {
    final title = (data['title'] ?? '').toString().toLowerCase();
    if (title.contains('pdf')) return [AppColors.cardBlue, AppColors.softBlue];
    if (title.contains('text')) return [AppColors.cardGreen, AppColors.softGreen];
    if (title.contains('image')) return [AppColors.cardOrange, AppColors.softOrange];
    return [AppColors.surface, AppColors.scaffoldBackground];
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final summary = data['summary']?['summary'] ?? '';
    final timestamp = data['createdAt'] as Timestamp?;
    final dateFormatted = timestamp != null
        ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
        : '';
    final colors = _cardColors();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getIcon(title.toString()),
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (summary.toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      summary.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateFormatted,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('text') || t.contains('paste')) return Icons.text_snippet;
    if (t.contains('image')) return Icons.image;
    return Icons.article;
  }
}