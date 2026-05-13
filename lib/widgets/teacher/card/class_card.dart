import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';
import '../chip/publish_status_chip.dart';

class ClassCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onUpdate;   // called after delete to refresh the parent

  const ClassCard({
    Key? key,
    required this.data,
    required this.docId,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Untitled';
    final code = data['code'] ?? '------';
    final lessons = data['lessonCount'] ?? 0;
    final students = data['studentCount'] ?? 0;
    final isPublished = data['isPublished'] ?? false;
    final updatedAt = data['updatedAt'] as Timestamp?;
    final updated = updatedAt != null ? _timeAgo(updatedAt.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(code,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          PublishStatusChip(isPublished: isPublished),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(name,
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700)),

        // --- After Text(name, ...) ---
        const SizedBox(height: AppSpacing.sm),
        if ((data['description'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              data['description'],
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if ((data['subject'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data['subject'],
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        // --- End inserted block ---

        Row(children: [
          _MiniStat(icon: Icons.menu_book_rounded, value: '$lessons Lessons'),
          const SizedBox(width: AppSpacing.md),
          _MiniStat(icon: Icons.people_rounded, value: '$students Students'),
          const Spacer(),
          Text(updated,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          // Only Delete button – Edit removed
          _ActionButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              onTap: () => _confirmDelete(context),
              color: Colors.red),
          const Spacer(),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('View Lessons',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.classWorkspace,
                arguments: {'classData': data, 'classId': docId},
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ---------- Confirm & Delete ----------
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Class'),
        content: const Text(
            'This will permanently delete this class and all its lessons.\nThis action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                Navigator.pop(ctx); // close dialog

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                // 1) Delete from teacher's own collection
                await FirebaseFirestore.instance
                    .collection('teachers')
                    .doc(user.uid)
                    .collection('classes')
                    .doc(docId)
                    .delete();

                // 2) Delete from global lookup
                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(docId)
                    .delete();

                // 3) Optionally, delete all lessons inside the class
                final lessonsSnap = await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(docId)
                    .collection('lessons')
                    .get();
                for (var doc in lessonsSnap.docs) {
                  await doc.reference.delete();
                }

                // Notify parent to refresh
                onUpdate();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class deleted')),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MiniStat({required this.icon, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(value,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionButton(
      {required this.icon,
        required this.label,
        required this.onTap,
        this.color});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color ?? AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: color ?? AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}