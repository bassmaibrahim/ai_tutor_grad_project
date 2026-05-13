import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({Key? key}) : super(key: key);

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  bool _isSaving = false;

  Future<void> _addQuestion() async {
    if (_questionController.text.trim().isEmpty ||
        _answerController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final classId = args['classId'] as String;
    final quizId = args['quizId'] as String;

    final newPair = {
      'question': _questionController.text.trim(),
      'answer': _answerController.text.trim(),
    };

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .doc(quizId)
        .update({
      'questions': FieldValue.arrayUnion([newPair]),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question added successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Add Question',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question',
                style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _questionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter the question...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Answer',
                style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _answerController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter the answer...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_circle_outline),
                label: Text(
                    _isSaving ? 'Adding...' : 'Add Question',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _addQuestion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}