// lib/widgets/teacher/publish_status_chip.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';

class PublishStatusChip extends StatelessWidget {
  final bool isPublished;
  const PublishStatusChip({Key? key, required this.isPublished}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: AppTextStyles.caption.copyWith(
          color: isPublished ? AppColors.success : AppColors.warning,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}