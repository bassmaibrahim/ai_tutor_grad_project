import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';

class SavedLessonsSection extends StatelessWidget {
  const SavedLessonsSection({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('teachers')
        .doc(user.uid)
        .collection('saved_lessons')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Saved Lessons',
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.allSavedLessons),
              child: Text(
                'View More',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        StreamBuilder<QuerySnapshot>(
          stream: _stream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _EmptyState(
                icon: Icons.auto_stories_outlined,
                message: 'No saved lessons yet',
              );
            }

            final docs = snapshot.data!.docs;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${docs.length} Total',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _SavedLessonCard(
                    data: data,
                    docId: doc.id,
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SavedLessonCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _SavedLessonCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final summary = (data['summary']?['summary'] ?? '').toString();
    final createdAt = data['createdAt'] as Timestamp?;
    final date = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.w600)),
                ),
                // Delete icon
                GestureDetector(
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    await FirebaseFirestore.instance
                        .collection('teachers')
                        .doc(user.uid)
                        .collection('saved_lessons')
                        .doc(docId)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lesson deleted')),
                    );
                  },
                  child: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                  AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.quiz_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                    '${(data['qa']?['qa_pairs'] ?? []).length} Questions',
                    style: AppTextStyles.caption),
                const Spacer(),
                Text(date,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // View Details button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View'),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.savedLessonDetail,
                    arguments: {'lesson': data, 'docId': docId},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary.withOpacity(0.6)),
          const SizedBox(height: AppSpacing.md),
          Text(message,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}