// lib/screens/teacher/create_class_screen.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';  // make sure AppRoutes is imported

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({Key? key}) : super(key: key);

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isCreating = false;
  String? _bannerUrl;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  // ---------- Generate a random 5‑character class code ----------
  void _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random();
    _codeController.text =
        List.generate(5, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // ---------- Create the class in Firestore ----------
  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isCreating = true);

    try {
      // Check that the code is unique globally
      final existing = await FirebaseFirestore.instance
          .collection('classes')
          .where('code', isEqualTo: _codeController.text)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class code already exists. Generate a new one.')),
        );
        setState(() => _isCreating = false);
        return;
      }

      // 1. Create the class in the teacher's own subcollection
      final classRef = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(user.uid)
          .collection('classes')
          .add({
        'name': _nameController.text.trim(),
        'code': _codeController.text,
        'description': _descController.text.trim(),
        'subject': _subjectController.text.trim(),
        'bannerUrl': _bannerUrl ?? '',
        'teacherId': user.uid,
        'teacherName':
        FirebaseAuth.instance.currentUser?.displayName ?? 'Professor',
        'lessonCount': 0,
        'studentCount': 0,
        'isPublished': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Also add to the global "classes" collection for student lookup
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classRef.id)
          .set({
        'code': _codeController.text,
        'teacherId': user.uid,
        'className': _nameController.text.trim(),
      });

      // Show success dialog with the option to go to the workspace
      _showSuccessDialog(classRef.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // ---------- Success dialog with navigation to workspace ----------
  void _showSuccessDialog(String classId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
              const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Class Created!',
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Share code: ${_codeController.text}',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.of(ctx).pop();

                  // Replace the current screen with the workspace screen
                  Navigator.of(context).pushReplacementNamed(
                    AppRoutes.classWorkspace,
                    arguments: {
                      'classData': {
                        'name': _nameController.text.trim(),
                        'code': _codeController.text,
                        'description': _descController.text.trim(),
                        'subject': _subjectController.text.trim(),
                        'lessonCount': 0,
                        'studentCount': 0,
                        'isPublished': true,
                        'teacherName':
                        FirebaseAuth.instance.currentUser?.displayName ??
                            'Professor',
                      },
                      'classId': classId,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Go to Class Workspace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Create Class',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput(
                label: 'Class Name',
                hint: 'e.g. Advanced Mathematics',
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInput(
                label: 'Class Code',
                hint: 'Unique code',
                controller: _codeController,
                suffix: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generateCode,
                ),
                readOnly: true,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInput(
                label: 'Subject Category (Optional)',
                hint: 'e.g. Computer Science',
                controller: _subjectController,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInput(
                label: 'Description (Optional)',
                hint: 'Course description...',
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Create Class',
                      style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Reusable text field builder ----------
  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    Widget? suffix,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}