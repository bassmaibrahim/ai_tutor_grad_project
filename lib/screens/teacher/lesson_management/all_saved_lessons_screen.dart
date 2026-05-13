import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';

class AllSavedLessonsScreen extends StatefulWidget {
  const AllSavedLessonsScreen({Key? key}) : super(key: key);

  @override
  State<AllSavedLessonsScreen> createState() => _AllSavedLessonsScreenState();
}

class _AllSavedLessonsScreenState extends State<AllSavedLessonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  Stream<QuerySnapshot> _stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('teachers')
        .doc(user.uid)
        .collection('saved_lessons')
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
        title: Text('Saved Lessons',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.primary),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.teacherHome, (route) => false),
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
                hintText: 'Search lessons...',
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
                        Icon(Icons.auto_stories_outlined,
                            size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: AppSpacing.md),
                        Text('No saved lessons',
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
                    return title.contains(_query);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _SavedLessonCard(
                      data: data,
                      docId: docs[index].id,
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
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary)),
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