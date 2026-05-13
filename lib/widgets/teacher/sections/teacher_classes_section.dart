import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';
import '../card/class_card.dart';
import 'empty_classes_state.dart';

class TeacherClassesSection extends StatelessWidget {
  const TeacherClassesSection({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('teachers')
        .doc(user.uid)
        .collection('classes')
        .orderBy('createdAt', descending: true)
        .limit(5)                     // Show only 5 on home page
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
              'Your Classes',
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
            ),
            // “See More” button
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.allClasses),
              child: Text(
                'See More',
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
              return const EmptyClassesState();
            }

            final docs = snapshot.data!.docs;
            return Column(
              children: [
                // Total count
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
                  return ClassCard(
                    data: data,
                    docId: doc.id,
                    onUpdate: () {
                      // The home screen RefreshIndicator will pull fresh data
                    },
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