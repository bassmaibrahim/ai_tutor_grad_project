// lib/screens/quiz/flip_quiz_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_routes.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';

class FlipQuizScreen extends StatefulWidget {
  const FlipQuizScreen({Key? key}) : super(key: key);

  @override
  State<FlipQuizScreen> createState() => _FlipQuizScreenState();
}

class _FlipQuizScreenState extends State<FlipQuizScreen> {
  late List<Map<String, dynamic>> _questions;
  late List<bool?> _answers;
  int _currentIndex = 0;
  bool _revealed = false;
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _finished = false;

  // NEW: IDs for saving the attempt
  String? _classId;
  String? _quizId;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final qaPairs = List<Map<String, dynamic>>.from(args['qaPairs'] ?? []);
    final count = (args['questionCount'] as int?) ?? 5;
    _questions = qaPairs.take(count).toList();
    _answers = List.filled(_questions.length, null);

    // Capture classId & quizId (optional but used for saving)
    _classId = args['classId'] as String?;
    _quizId = args['quizId'] as String?;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_finished && mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  void _revealAnswer() {
    setState(() => _revealed = true);
  }

  void _submitAnswer(bool isCorrect) {
    setState(() {
      _answers[_currentIndex] = isCorrect;
    });

    if (_currentIndex < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _currentIndex++;
          _revealed = false;
        });
      });
    } else {
      _finishQuiz();
    }
  }

  // ------- UPDATED: save attempt to Firestore ----------
  void _finishQuiz() {
    _finished = true;
    _timer?.cancel();
    final correctCount = _answers.where((a) => a == true).length;
    final incorrectCount = _questions.length - correctCount;

    // Save attempt if classId and quizId are present
    _saveAttempt(correctCount, _questions.length);

    Navigator.pushReplacementNamed(context, AppRoutes.quizReview, arguments: {
      'questions': _questions,
      'answers': _answers,
      'correct': correctCount,
      'incorrect': incorrectCount,
      'total': _questions.length,
      'timeTaken': _secondsElapsed,
    });
  }

  Future<void> _saveAttempt(int score, int total) async {
    if (_classId == null || _quizId == null) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // 1. Write the attempt
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(_classId)
          .collection('quizzes')
          .doc(_quizId)
          .collection('attempts')
          .doc(userId)
          .set({
        'score': score,
        'total': total,
        'answers': _answers,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Increment attempt counter on quiz document
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(_classId)
          .collection('quizzes')
          .doc(_quizId)
          .update({
        'attemptCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Failed to save quiz attempt: $e');
    }
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary),
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text('Quiz', style: AppTextStyles.heading3.copyWith(color: AppColors.primary)),
            Text(_formatTime(_secondsElapsed), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight - 150),
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Text('${_currentIndex + 1}/${_questions.length}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.divider,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Question card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(q['question'] ?? '', style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary, height: 1.4), textAlign: TextAlign.center),
                ]),
              ),

              const SizedBox(height: AppSpacing.lg),

              if (!_revealed)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('Show Answer', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _revealAnswer,
                  ),
                ),

              if (_revealed) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.success, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Answer', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    Text(q['answer'] ?? '', style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, height: 1.5), textAlign: TextAlign.center),
                  ]),
                ),
                const SizedBox(height: AppSpacing.md),

                Text('Did you get this right?', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  Expanded(
                    child: _AssessmentButton(
                      icon: Icons.check_circle_rounded,
                      label: 'I Got It Right',
                      color: AppColors.success,
                      onTap: () => _submitAnswer(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _AssessmentButton(
                      icon: Icons.refresh_rounded,
                      label: 'Needs Review',
                      color: AppColors.error,
                      onTap: () => _submitAnswer(false),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssessmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AssessmentButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}