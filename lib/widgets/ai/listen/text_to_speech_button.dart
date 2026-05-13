// lib/widgets/ai/text_to_speech_button.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';

class TextToSpeechButton extends StatelessWidget {
  final String text;
  final VoidCallback onListen;   // new callback

  const TextToSpeechButton({
    Key? key,
    required this.text,
    required this.onListen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.volume_up),
        label: const Text(
          'Listen with AI Tutor',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onListen,    // use the new callback
      ),
    );
  }
}