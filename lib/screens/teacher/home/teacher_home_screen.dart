// lib/screens/teacher/teacher_home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';
import '../../../widgets/teacher/sections/greeting_header.dart';
import '../../../widgets/teacher/card/create_class_card.dart';
import '../../../widgets/teacher/card/ai_quick_tip_card.dart';
import '../../../widgets/teacher/sections/stats_overview.dart';
import '../../../widgets/teacher/sections/teacher_classes_section.dart';
import '../../../widgets/teacher/sections/saved_lessons_section.dart';
import '../../../widgets/home/AccountTab.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({Key? key}) : super(key: key);

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _hasClasses = false;
  int _totalStudents = 0;
  int _aiInsights = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final classesSnapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(user.uid)
          .collection('classes')
          .get();

      int totalStudents = 0;
      int totalInsights = 0;
      for (var doc in classesSnapshot.docs) {
        final data = doc.data();
        totalStudents += (data['studentCount'] ?? 0) as int;
        totalInsights += (data['insightsCount'] ?? 0) as int;
      }

      final insightsCount = await FirebaseFirestore.instance
          .collection('user_studies')
          .where('userId', isEqualTo: user.uid)
          .count()
          .get();

      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _totalStudents = totalStudents;
          _aiInsights = (insightsCount.count ?? 0) + totalInsights;
          _hasClasses = classesSnapshot.docs.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const AccountTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    final userName = _userData?['name'] ?? 'Professor';

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeacherGreetingHeader(userName: userName),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CreateClassCard(),
                    const SizedBox(height: AppSpacing.lg),
                    const AIQuickTipCard(),
                    const SizedBox(height: AppSpacing.xl),

                    // Stats (only if classes exist)
                    if (_hasClasses) ...[
                      StatsOverview(
                        totalStudents: _totalStudents,
                        aiInsights: _aiInsights,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Your Classes (self‑fetching, shows cards)
                    const TeacherClassesSection(),
                    const SizedBox(height: AppSpacing.xl),

                    // Saved Lessons (personal AI‑generated library)
                    const SavedLessonsSection(),
                    const SizedBox(height: AppSpacing.xl),


                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.account_circle_rounded,
                label: 'Account',
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}