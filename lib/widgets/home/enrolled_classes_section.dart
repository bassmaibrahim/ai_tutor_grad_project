// lib/widgets/home/enrolled_classes_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_routes.dart';

class EnrolledClassesSection extends StatelessWidget {
  const EnrolledClassesSection({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('enrolledClasses')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Classes',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.allEnrolledClasses,
              ),
              child: Text(
                'View All',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // ───────────── Join Class Button (Always Visible) ─────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text(
              'Join Class',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.joinClass);
            },
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ───────────── Classes Stream ─────────────
        StreamBuilder<QuerySnapshot>(
          stream: _stream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _EmptyClassesState();
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return _EnrolledClassCard(
                  data: data,
                  docId: doc.id,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ────────────────────── Empty State ──────────────────────
class _EmptyClassesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              size: 36,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'No enrolled classes yet.',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Your academic journey is a blank canvas. Join your first class to start learning with AI.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ────────────────────── Class Card ──────────────────────
class _EnrolledClassCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _EnrolledClassCard({
    required this.data,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final className =
        data['name'] ?? data['className'] ?? 'Untitled Class';

    final profName =
        data['teacherName'] ?? 'Unknown Professor';

    final profImage = data['teacherImage'] as String?;

    final joinedAt = data['joinedAt'] ?? data['createdAt'];

    final joinDate = joinedAt is Timestamp
        ? '${joinedAt.toDate().day} '
        '${_monthName(joinedAt.toDate().month)} '
        '${joinedAt.toDate().year}'
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status & Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'IN PROGRESS',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              GestureDetector(
                onTap: () =>
                    _confirmDelete(context, docId, className),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color:
                  AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Class Name
          Text(
            className,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Description
          if ((data['description'] ?? '')
              .toString()
              .isNotEmpty)
            Padding(
              padding:
              const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                data['description'],
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Subject
          if ((data['subject'] ?? '').toString().isNotEmpty)
            Padding(
              padding:
              const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  data['subject'],
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.sm),

          // Professor Info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                AppColors.primary.withOpacity(0.1),
                backgroundImage:
                profImage != null && profImage.isNotEmpty
                    ? NetworkImage(profImage)
                    : null,
                child: profImage == null || profImage.isEmpty
                    ? Text(
                  profName.isNotEmpty
                      ? profName[0].toUpperCase()
                      : '?',
                  style:
                  AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                )
                    : null,
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      profName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Joined $joinDate',
                      style:
                      AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Open Class Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.studentClassView,
                  arguments: {
                    'classId': docId,
                    'classData': {
                      'className': className,
                      'code': data['code'] ?? '',
                      'teacherName': profName,
                      'teacherId': data['teacherId'] ?? '',
                      'description':
                      data['description'] ?? '',
                      'lessonCount':
                      data['lessonCount'] ?? 0,
                      'studentCount':
                      data['studentCount'] ?? 0,
                    },
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Open Class'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context,
      String docId,
      String className,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Remove Class'),
        content: Text(
          'Are you sure you want to remove "$className"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('enrolledClasses')
                  .doc(docId)
                  .delete();

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Class removed'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return months[month - 1];
  }
}