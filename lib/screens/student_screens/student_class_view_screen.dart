// lib/screens/student_screens/student_class_view_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_routes.dart';

class StudentClassViewScreen extends StatelessWidget {
  const StudentClassViewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final classId = args['classId'] as String;
    final classData = args['classData'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(classData['className'] ?? 'Class',
            style: AppTextStyles.heading3.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(classData['code'] ?? '',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(classData['className'] ?? '',
                    style: AppTextStyles.heading1.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.sm),
                // Description
                if ((classData['description'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      classData['description'],
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.8)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // Subject chip
                if ((classData['subject'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        classData['subject'],
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                // Professor name
                Text(
                  'Teacher: ${classData['teacherName'] ?? 'Unknown'}',
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(classId)
                  .collection('lessons')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined,
                              size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: AppSpacing.md),
                          Text('No lessons yet',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary)),
                        ]),
                  );
                }
                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final lesson = docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lesson['title'] ?? 'Untitled Lesson',
                                style: AppTextStyles.heading3.copyWith(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(lesson['description'] ?? '',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Icon(Icons.quiz_outlined,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                    '${(lesson['qa']?['qa_pairs'] ?? []).length} Questions',
                                    style: AppTextStyles.caption),
                                const Spacer(),
                                TextButton.icon(
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: const Text('View Lesson'),
                                  onPressed: () {
                                    final lessonWithId = Map<String, dynamic>.from(lesson);
                                    lessonWithId['_id'] = docId;
                                    Navigator.pushNamed(context,
                                        AppRoutes.studentLessonDetail,
                                        arguments: {
                                          'lesson': lessonWithId,
                                          'classId': classId,
                                        });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}