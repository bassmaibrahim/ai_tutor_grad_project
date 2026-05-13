// lib/widgets/home/upload_section.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_routes.dart';

class UploadSection extends StatefulWidget {
  const UploadSection({Key? key}) : super(key: key);

  @override
  State<UploadSection> createState() => _UploadSectionState();
}

class _UploadSectionState extends State<UploadSection> {
  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? bytes = file.bytes;

      if (!kIsWeb && bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      final sizeMB = (bytes?.length ?? 0) / (1024 * 1024);
      if (sizeMB > 50) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF must be less than 50 MB')),
          );
        }
        return;
      }

      if (mounted && bytes != null) {
        Navigator.pushNamed(context, AppRoutes.pdfViewScreen, arguments: {
          'bytes': bytes,
          'title': file.name,
        });
      }
    } catch (e) {
      debugPrint('PDF picker error: $e');
    }
  }

  Future<void> _pickHandwrittenPDF() async {
    // Same as PDF, but with a note to the user
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? bytes = file.bytes;

      if (!kIsWeb && bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      final sizeMB = (bytes?.length ?? 0) / (1024 * 1024);
      if (sizeMB > 50) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF must be less than 50 MB')),
          );
        }
        return;
      }

      if (mounted && bytes != null) {
        Navigator.pushNamed(context, AppRoutes.pdfViewScreen, arguments: {
          'bytes': bytes,
          'title': file.name,
          'isHandwritten': true,
        });
      }
    } catch (e) {
      debugPrint('Handwritten PDF picker error: $e');
    }
  }

  void _pasteText() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Paste Text'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Enter at least 50 words…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: AppColors.scaffoldBackground,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              final wordCount = text.split(RegExp(r'\s+')).length;
              if (wordCount < 50) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Text must be at least 50 words')),
                );
                return;
              }
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.textViewer, arguments: {
                'title': 'Pasted Text',
                'text': text,
              });
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Three upload cards
        _UploadCard(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Upload PDF',
          subtitle: 'Upload study materials and let AI generate summaries and quizzes.',
          buttonLabel: 'Upload PDF',
          onTap: _pickPDF,
          color: AppColors.softRed,
          iconColor: Colors.red,
        ),
        const SizedBox(height: AppSpacing.md),
        _UploadCard(
          icon: Icons.document_scanner_rounded,
          title: 'Handwritten Notes',
          subtitle: 'Upload PDFs with handwritten notes and convert them into digital study guides.',
          buttonLabel: 'Scan Notes',
          onTap: _pickHandwrittenPDF,
          color: AppColors.softOrange,
          iconColor: Colors.orange,
        ),
        const SizedBox(height: AppSpacing.md),
        _UploadCard(
          icon: Icons.text_fields_rounded,
          title: 'Paste Text',
          subtitle: 'Paste study text directly to start an interactive tutoring session.',
          buttonLabel: 'Paste Text',
          onTap: _pasteText,
          color: AppColors.softGreen,
          iconColor: Colors.green,
        ),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  const _UploadCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}