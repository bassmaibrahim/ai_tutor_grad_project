// lib/screens/student_screens/all_enrolled_classes_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_routes.dart';

class AllEnrolledClassesScreen extends StatefulWidget {
  const AllEnrolledClassesScreen({Key? key}) : super(key: key);

  @override
  State<AllEnrolledClassesScreen> createState() => _AllEnrolledClassesScreenState();
}

class _AllEnrolledClassesScreenState extends State<AllEnrolledClassesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  Stream<List<Map<String, dynamic>>> _enrolledClassesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('enrolledClasses')
        .snapshots()
        .asyncMap((snap) async {
      final list = <Map<String, dynamic>>[];
      for (var doc in snap.docs) {
        final data = doc.data();
        final globalDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(data['classId'] as String)
            .get();
        if (globalDoc.exists) {
          final globalData = globalDoc.data()!;
          list.add({
            'classId': data['classId'],
            'className': globalData['className'] ?? data['className'],
            'code': globalData['code'] ?? data['code'],
            'teacherName': data['teacherName'] ?? 'Unknown',
          });
        }
      }
      return list;
    });
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
        title: Text('My Classes', style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.primary),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.studentHome, (route) => false),
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
                hintText: 'Search by name or code...',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                filled: true, fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _enrolledClassesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final classes = snapshot.data ?? [];
                if (classes.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.class_outlined, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: AppSpacing.md),
                      Text('No enrolled classes', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    ]),
                  );
                }
                var filtered = classes;
                if (_query.isNotEmpty) {
                  filtered = classes.where((c) {
                    final name = (c['className'] ?? '').toString().toLowerCase();
                    final code = (c['code'] ?? '').toString().toLowerCase();
                    return name.contains(_query) || code.contains(_query);
                  }).toList();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return _EnrolledClassCard(
                      classData: c,
                      onTap: () => Navigator.pushNamed(
                        context, AppRoutes.studentClassView,
                        arguments: {'classId': c['classId'], 'classData': c},
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

class _EnrolledClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final VoidCallback onTap;
  const _EnrolledClassCard({required this.classData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(classData['code'] ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(classData['className'] ?? '', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Teacher: ${classData['teacherName']}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View Lessons'),
              onPressed: onTap,
            ),
          ),
        ]),
      ),
    );
  }
}