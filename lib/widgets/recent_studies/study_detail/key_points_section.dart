// lib/widgets/recent_studies/study_detail/key_points_section.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';
import 'section_title.dart';

class KeyPointsSection extends StatelessWidget {
  final List<String> keyPoints;

  const KeyPointsSection({Key? key, required this.keyPoints}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle(title: 'Key Points'),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.headphones,
                    color: AppColors.primary, size: 18),
              ),
              onPressed: () {
                final allPoints = keyPoints.join('. ');
                Navigator.pushNamed(
                  context,
                  AppRoutes.listen,
                  arguments: {'text': allPoints},
                );
              },
              tooltip: 'Listen to key points',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...keyPoints.asMap().entries.map((entry) => _KeyPointTile(
          index: entry.key,
          text: entry.value,
        )),
      ],
    );
  }
}

class _KeyPointTile extends StatelessWidget {
  final int index;
  final String text;

  const _KeyPointTile({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
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
                '${index + 1}',
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
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}