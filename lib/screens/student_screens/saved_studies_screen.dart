// lib/screens/student_screens/saved_studies_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_routes.dart';

class SavedStudiesScreen extends StatefulWidget {
  const SavedStudiesScreen({Key? key}) : super(key: key);

  @override
  State<SavedStudiesScreen> createState() => _SavedStudiesScreenState();
}

class _SavedStudiesScreenState extends State<SavedStudiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  Stream<QuerySnapshot> _stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('user_studies')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Recent Studies',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.primary),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.studentHome, (route) => false),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by title or topic...',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_stories,
                            size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: AppSpacing.md),
                        Text('No saved studies',
                            style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;
                if (_query.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title =
                    (data['title'] ?? '').toString().toLowerCase();
                    final topic =
                    (data['detected_topic'] ?? '').toString().toLowerCase();
                    return title.contains(_query) || topic.contains(_query);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _StudyTile(
                      data: data,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.savedStudyDetail,
                          arguments: {'data': data},
                        );
                      },
                      onDelete: () async {
                        await FirebaseFirestore.instance
                            .collection('user_studies')
                            .doc(docs[index].id)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Study deleted')),
                        );
                      },
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

class _StudyTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StudyTile({
    required this.data,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final type = data['type'] ?? 'text';
    final topic = data['detected_topic'] ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final date = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
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
              type == 'pdf'
                  ? Icons.picture_as_pdf_rounded
                  : Icons.text_snippet_rounded,
              color: type == 'pdf' ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (topic.isNotEmpty)
                    Text(
                      topic,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          Text(
            date,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}