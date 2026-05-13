// lib/widgets/ai/speed_selector.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';

class SpeedSelector extends StatelessWidget {
  final double selectedSpeed;
  final ValueChanged<double> onSpeedChanged;
  final List<double> speeds;

  const SpeedSelector({
    Key? key,
    required this.selectedSpeed,
    required this.onSpeedChanged,
    this.speeds = const [0.5, 1.0, 1.5, 2.0],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),   // large oval
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: speeds.map((speed) {
          final bool isSelected = speed == selectedSpeed;
          return GestureDetector(
            onTap: () => onSpeedChanged(speed),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${speed}x',
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}