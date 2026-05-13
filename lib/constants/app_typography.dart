import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Large title – 28px, semibold
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Section title – 22px, semibold
  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Small title – 18px, medium
  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Body – 16px, regular
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,        // more breathing room
  );

  // Caption / small text – 14px, regular
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,   // optional default color
  );

  // Overline / tiny labels – 12px, medium
  static const TextStyle overline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
}