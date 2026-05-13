// lib/screens/teacher/lesson_management/create_lesson_screen.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';

// ---------- UploadOptionCard (PDF & Text only) ----------
class UploadOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;

  const UploadOptionCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.divider,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- CreateLessonScreen ----------
class CreateLessonScreen extends StatefulWidget {
  const CreateLessonScreen({Key? key}) : super(key: key);

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _questionsController = TextEditingController(text: "10");
  final _videosController = TextEditingController(text: "10");
  Uint8List? _uploadedBytes;
  String? _uploadedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _questionsController.dispose();
    _videosController.dispose();
    super.dispose();
  }

  // ---------- Fetch teacher name ----------
  Future<String> _getTeacherName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Professor';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data()?['name'] ?? user.displayName ?? 'Professor';
    } catch (_) {
      return user.displayName ?? 'Professor';
    }
  }

  // ---------- Pick PDF ----------
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

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load PDF')),
          );
        }
        return;
      }

      final sizeMB = bytes.length / (1024 * 1024);
      if (sizeMB > 50) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF must be less than 50 MB')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _uploadedBytes = bytes;
          _uploadedFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ---------- Paste Text with 50-word validation ----------
  void _pasteText() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Paste Text Content'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste your text (min 50 words)...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                Navigator.pop(ctx);
                return;
              }
              final wordCount = text.split(RegExp(r'\s+')).length;
              if (wordCount < 50) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Text must contain at least 50 words')),
                );
                return;
              }
              final bytes = Uint8List.fromList(utf8.encode(text));
              Navigator.pop(ctx);
              setState(() {
                _uploadedFileName = 'pasted_text.txt';
                _uploadedBytes = bytes;
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ---------- Navigate to AI Processing ----------
  void _goToProcessing() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a lesson title')),
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.aiProcessing, arguments: {
      'classData':
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
      'lessonData': {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'questionsCount': int.tryParse(_questionsController.text) ?? 10,
        'videosCount': int.tryParse(_videosController.text) ?? 10,
        'fileBytes': _uploadedBytes,
        'fileName': _uploadedFileName,
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Create Lesson',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
            tooltip: 'Next',
            onPressed: _goToProcessing,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Professor greeting ----------
            FutureBuilder<String>(
              future: _getTeacherName(),
              builder: (context, snapshot) {
                final name = snapshot.data ?? 'Professor';
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, color: AppColors.primary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Creating as $name',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Lesson Title
            _SectionLabel('Lesson Title'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _titleController,
              style:
              AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
              decoration:
              _inputStyle('e.g. Introduction to Neural Networks'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Lesson Description
            _SectionLabel('Lesson Description'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: _inputStyle('Describe what this lesson covers...'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Upload Content
            _SectionLabel('Upload Content'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You can upload one PDF (handwritten or printed) or paste text.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: UploadOptionCard(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'Upload PDF',
                      subtitle: 'PDF, max 50 MB\n(handwritten or printed)',
                      onTap: _pickPDF,
                      isSelected: _uploadedFileName?.endsWith('.pdf') == true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: UploadOptionCard(
                      icon: Icons.text_fields_rounded,
                      label: 'Paste Text',
                      subtitle: 'Not less than 50 words',
                      onTap: _pasteText,
                      isSelected: _uploadedFileName == 'pasted_text.txt',
                    ),
                  ),
                ],
              ),
            ),
            if (_uploadedFileName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(_uploadedFileName!,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.success)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _uploadedBytes = null;
                      _uploadedFileName = null;
                    }),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.success),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            // AI Generation Settings
            _SectionLabel('AI Generation Settings'),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(children: [
                _SettingRow(
                    label: 'Number of Questions',
                    value: _questionsController),
                const SizedBox(height: AppSpacing.md),
                _SettingRow(
                    label: 'Number of Videos',
                    value: _videosController),
              ]),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Generate AI Content button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate AI Content',
                    style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _goToProcessing,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5));
}

class _SettingRow extends StatelessWidget {
  final String label;
  final TextEditingController value;
  const _SettingRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(label,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w600))),
      SizedBox(
          width: 60,
          child: TextField(
              controller: value,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10)))),
    ]);
  }
}