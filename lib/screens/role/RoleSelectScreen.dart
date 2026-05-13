// lib/screens/role_select/role_select_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../widgets/button/button_widget.dart';
import '../../widgets/role/RoleOptionCard.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String? _selectedRole; // 'student' or 'teacher'
  bool _isSaving = false; // show a loading state if needed

  Future<void> _continue() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ✅ Use update instead of set with merge
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'role': _selectedRole}); // Updates only the role field
      }

      // Navigate to appropriate home
      final String route = _selectedRole == 'student'
          ? AppRoutes.studentHome
          : AppRoutes.teacherHome;

      if (mounted) {
        Navigator.pushReplacementNamed(context, route);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),

              // Header
              Text(
                'Eshr7ly AI Tutor',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload notes. Understand faster.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Role cards
              RoleOptionCard(
                title: 'Student Mode',
                description:
                'Get personalized explanations and practice quizzes for your subjects.',
                icon: Icons.school,
                isSelected: _selectedRole == 'student',
                onTap: () => setState(() => _selectedRole = 'student'),
              ),
              RoleOptionCard(
                title: 'Teacher Mode',
                description:
                'Generate lesson plans, quiz banks, and summaries from your materials.',
                icon: Icons.cast_for_education,
                isSelected: _selectedRole == 'teacher',
                onTap: () => setState(() => _selectedRole = 'teacher'),
              ),

              const Spacer(flex: 2),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AppButton(
                  variant: AppButtonVariant.primary,
                  text: 'Continue',
                  onPressed: _continue,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}