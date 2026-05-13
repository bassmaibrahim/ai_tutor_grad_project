// lib/widgets/home/recent_studies_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_routes.dart';

class RecentStudiesSection extends StatelessWidget {
  const RecentStudiesSection({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('user_studies')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();
  }

  Future<void> _deleteStudy(String docId) async {
    await FirebaseFirestore.instance
        .collection('user_studies')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Studies',
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.textPrimary)),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.savedStudies),
              child: Text('View All',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        StreamBuilder<QuerySnapshot>(
          stream: _stream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _EmptyState(
                icon: Icons.auto_stories_rounded,
                title: 'Your recent AI studies will appear here.',
              );
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _RecentStudyCard(
                  data: data,
                  docId: doc.id,
                  onDelete: () => _deleteStudy(doc.id),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RecentStudyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onDelete;

  const _RecentStudyCard({
    required this.data,
    required this.docId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final type = data['type'] ?? 'text';

    // ✅ Handle summary: could be String (new) or Map (old)
    dynamic summaryField = data['summary'];
    String summaryText = '';
    String explanation = (data['explanation'] ?? '').toString();

    if (summaryField is String) {
      summaryText = summaryField;
    } else if (summaryField is Map) {
      // Old format: summary was stored as {'summary': '...', 'explanation': '...'}
      summaryText = summaryField['summary'] ?? '';
      // Override explanation if present inside the summary map
      if (summaryField.containsKey('explanation')) {
        explanation = summaryField['explanation'].toString();
      }
    }

    final previewText = summaryText.isNotEmpty ? summaryText : explanation;
    final timestamp = data['createdAt'] as Timestamp?;
    final date = timestamp != null ? _timeAgo(timestamp.toDate()) : '';

    return GestureDetector(
      onTap: () {
        // Navigate to detail view – not to the list again
        Navigator.pushNamed(
          context,
          AppRoutes.savedStudyDetail,
          arguments: {'data': data},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: type == 'pdf' ? AppColors.softRed : AppColors.softGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                type == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.text_snippet_rounded,
                color: type == 'pdf' ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (previewText.isNotEmpty)
                    Text(previewText,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (date.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(date,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary, fontSize: 11)),
              ),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyState({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: AppSpacing.md),
          Text(title,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}