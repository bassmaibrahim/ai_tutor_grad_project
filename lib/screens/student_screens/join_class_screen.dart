// lib/screens/student/join_class_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_typography.dart';
import '../../constants/app_routes.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({Key? key}) : super(key: key);

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _codeController = TextEditingController();
  bool _isJoining = false;

  Future<void> _joinClass() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isJoining = true);

    try {
      // Look up the class in the global collection
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('code', isEqualTo: code)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class not found. Check the code.')),
        );
        setState(() => _isJoining = false);
        return;
      }

      final classDoc = snapshot.docs.first;
      final classId = classDoc.id;
      final globalData = classDoc.data();

      // Get teacher info to complete the class data for the student
      final teacherId = globalData['teacherId'] as String?;
      String teacherName = 'Unknown';

      if (teacherId != null) {
        final teacherDoc = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(teacherId)
            .get();
        teacherName = teacherDoc.data()?['name'] ?? 'Professor';
      }

      final user = FirebaseAuth.instance.currentUser!;

      // 1. Add student to the class's student list
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(user.uid)
          .set({
        'studentId': user.uid,
        'studentName': user.displayName ?? 'Student',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // 2. Add the class to the student's enrolled classes
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrolledClasses')
          .doc(classId)
          .set({
        'classId': classId,
        'className': globalData['className'] ?? globalData['name'] ?? '',
        'code': code,
        'teacherName': teacherName,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update the student count on the teacher's class document
      if (teacherId != null) {
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(teacherId)
            .collection('classes')
            .doc(classId)
            .update({
          'studentCount': FieldValue.increment(1),
        });
      }

      // Build classData to pass to the student view
      final classData = {
        'className': globalData['className'] ?? globalData['name'] ?? '',
        'code': code,
        'teacherName': teacherName,
        'teacherId': teacherId ?? '',
        'lessonCount': 0,  // will be updated by lesson streams
        'studentCount': 1,  // just added this student
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined the class!')),
      );

      // Navigate to the student class view
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.studentClassView,
        arguments: {
          'classId': classId,
          'classData': classData,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Join Class',
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle),
                child: Icon(Icons.vpn_key_rounded,
                    color: AppColors.primary, size: 48)),
            const SizedBox(height: AppSpacing.xl),
            Text('Enter Class Code',
                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text('Ask your teacher for the 5‑character code',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: AppTextStyles.heading1.copyWith(
                    fontSize: 32,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
                decoration: InputDecoration(
                    hintText: 'XXXXX',
                    hintStyle: AppTextStyles.heading1.copyWith(
                        fontSize: 32,
                        letterSpacing: 6,
                        color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none))),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                    onPressed: _isJoining ? null : _joinClass,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: _isJoining
                        ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Text('Join Class',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)))),
          ]),
        ),
      ),
    );
  }
}