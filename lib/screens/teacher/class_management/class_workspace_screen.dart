// lib/screens/teacher/class_workspace_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../../constants/app_routes.dart';

class ClassWorkspaceScreen extends StatefulWidget {
  const ClassWorkspaceScreen({Key? key}) : super(key: key);

  @override
  State<ClassWorkspaceScreen> createState() => _ClassWorkspaceScreenState();
}

class _ClassWorkspaceScreenState extends State<ClassWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _classData;
  late String _classId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _classData = args['classData'];
    _classId = args['classId'];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonCount = _classData['lessonCount'] ?? 0;
    final studentCount = _classData['studentCount'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // ---- Gradient header (scrolls away) ----
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.home_outlined,
                                color: Colors.white),
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.teacherHome,
                                  (route) => false,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _classData['code'] ?? '',
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _classData['name'] ?? '',
                        style: AppTextStyles.heading1.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      // Description & subject
                      if ((_classData['description'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            _classData['description'],
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if ((_classData['subject'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _classData['subject'],
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.menu_book,
                            label: '$lessonCount Lessons',
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _StatChip(
                            icon: Icons.people,
                            label: '$studentCount Students',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ---- Pinned TabBar ----
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.6),
                tabs: const [
                  Tab(
                      text: 'Lessons',
                      icon: Icon(Icons.menu_book_rounded, size: 18)),
                  Tab(
                      text: 'Quizzes',
                      icon: Icon(Icons.quiz_rounded, size: 18)),
                  Tab(
                      text: 'Students',
                      icon: Icon(Icons.people_rounded, size: 18)),
                ],
              ),
            ),
          ),
          // ---- Tab content filling remaining space ----
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLessonsTab(),
                _buildQuizzesTab(),
                _buildStudentsTab(),
              ],
            ),
          ),
        ],
      ),
      // Only one "Create Lesson" button – the FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.createLesson,
          arguments: {'classId': _classId, 'classData': _classData},
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Create Lesson',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ---------- Lessons tab (empty state without button) ----------
  Widget _buildLessonsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(_classId)
          .collection('lessons')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          // No button here – only the icon, title and subtitle
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No lessons yet',
            subtitle: 'Tap the button below to create your first lesson',
          );
        }
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final docId = docs[i].id;
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
                          child: Text(data['title'] ?? 'Untitled Lesson',
                              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _deleteLesson(docId),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(data['description'] ?? '',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.quiz_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('${(data['qa']?['qa_pairs'] ?? []).length} Questions',
                            style: AppTextStyles.caption),
                        const Spacer(),
                        Icon(Icons.videocam_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('${(data['youtube']?['videos'] ?? []).length} Videos',
                            style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Preview'),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.lessonView,
                          arguments: {'lesson': data, 'classId': _classId},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- Quizzes tab ----------
  Widget _buildQuizzesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(_classId)
          .collection('quizzes')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text('No quizzes yet', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
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
                          child: Text(data['title'] ?? 'Untitled Quiz',
                              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _deleteQuiz(doc.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.quiz_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('${(data['questions'] as List?)?.length ?? 0} questions',
                            style: AppTextStyles.caption),
                        const Spacer(),
                        Icon(Icons.people, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('${data['attemptCount'] ?? 0} attempts',
                            style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Question'),
                            onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.addQuestion,
                              arguments: {'classId': _classId, 'quizId': doc.id},
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Details'),
                            onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.quizDetail,
                              arguments: {'classId': _classId, 'quizId': doc.id},
                            ),
                          ),
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
    );
  }

  // ---------- Delete helpers ----------
  Future<void> _deleteLesson(String lessonId) async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(_classId)
        .collection('lessons')
        .doc(lessonId)
        .delete();
  }

  Future<void> _deleteQuiz(String quizId) async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(_classId)
        .collection('quizzes')
        .doc(quizId)
        .delete();
  }

  // ---------- Students tab ----------
  Widget _buildStudentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(_classId)
          .collection('students')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 64, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text('No students yet',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        final studentDocs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: studentDocs.length,
          itemBuilder: (context, index) {
            final data = studentDocs[index].data() as Map<String, dynamic>;
            final studentId = data['studentId'] as String? ?? '';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(studentId)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const ListTile(title: Text('Loading...'));
                }
                final userData =
                userSnap.data!.data() as Map<String, dynamic>?;
                final name = userData?['name'] ?? 'Unknown';
                final email = userData?['email'] ?? '';
                final joinedAt = data['joinedAt'] as Timestamp?;
                final date = joinedAt != null
                    ? '${joinedAt.toDate().day}/${joinedAt.toDate().month}/${joinedAt.toDate().year}'
                    : '';
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600)),
                              if (email.isNotEmpty)
                                Text(email,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text(date,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ---------- Pinned TabBar delegate ----------
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate({required this.tabBar});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.primary,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

// ---------- Stat chip ----------
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ---------- Empty state (with optional button) ----------
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onTap;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            // Button only shown if both parameters are provided
            if (buttonLabel != null && onTap != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------- Unused cards kept for compatibility ----------
class _QuizCard extends StatelessWidget {
  final String quizId;
  final Map<String, dynamic> data;
  final String classId;
  const _QuizCard({
    required this.quizId,
    required this.data,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled Quiz';
    final questionCount = (data['questions'] as List?)?.length ?? 0;
    final attemptCount = data['attemptCount'] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.heading3
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.quiz_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('$questionCount questions',
                    style: AppTextStyles.caption),
                const Spacer(),
                Icon(Icons.people, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('$attemptCount attempts',
                    style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Question'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addQuestion,
                        arguments: {
                          'classId': classId,
                          'quizId': quizId,
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.quizDetail,
                        arguments: {
                          'classId': classId,
                          'quizId': quizId,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const LessonCard({Key? key, required this.data, required this.docId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? 'Untitled Lesson',
                style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.xs),
            Text(data['description'] ?? '',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.quiz_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                    '${(data['qa']?['qa_pairs'] ?? []).length} Questions',
                    style: AppTextStyles.caption),
                const Spacer(),
                Icon(Icons.videocam_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                    '${(data['youtube']?['videos'] ?? []).length} Videos',
                    style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}