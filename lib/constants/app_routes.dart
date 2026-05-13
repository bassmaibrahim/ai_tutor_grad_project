// lib/constants/app_routes.dart
import 'package:ai_tutor_grad_project/screens/teacher/lesson_management/ai_processing_screen.dart';
import 'package:flutter/material.dart';
// --- AI & Quiz Screens ---
import '../screens/ai/AIFeaturesScreen.dart';
import '../screens/ai/listen_screen.dart';
import '../screens/ai/qa_screen.dart';
import '../screens/ai/quiz/flip_quiz_screen.dart';
import '../screens/ai/quiz/quiz_review_screen.dart';
// --- Onboarding & Auth ---
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
// --- Role Selection ---
import '../screens/role/RoleSelectScreen.dart';
// --- Document & Text ---
import '../screens/pdf/pdf_view_screen.dart';
import '../screens/student_screens/all_enrolled_classes_screen.dart';
import '../screens/student_screens/student_class_view_screen.dart';
import '../screens/student_screens/student_lesson_detail_screen.dart';
import '../screens/teacher/class_management/all_classes_screen.dart';
import '../screens/teacher/class_management/create_class_screen.dart';
import '../screens/teacher/lesson_management/all_saved_lessons_screen.dart';
import '../screens/teacher/lesson_management/lesson_view_screen.dart';
import '../screens/teacher/lesson_management/saved_lesson_detail_screen.dart';
import '../screens/teacher/quiz_management/add_question_screen.dart';
import '../screens/teacher/quiz_management/quiz_detail_screen.dart';
import '../screens/text/text_preview_screen.dart';
// --- Student Screens ---
import '../screens/student_screens/home/student_home_screen.dart';
import '../screens/student_screens/join_class_screen.dart';
import '../screens/student_screens/saved_studies_screen.dart';
import '../screens/student_screens/saved_study_detail_screen.dart';
// --- Teacher Screens ---
import '../screens/teacher/home/teacher_home_screen.dart';
import '../screens/teacher/class_management/class_workspace_screen.dart';  // <-- added
import '../screens/teacher/lesson_management/create_lesson_screen.dart';    // <-- added
import '../screens/teacher/lesson_management/lesson_preview_screen.dart';   // <-- added
import '../screens/teacher/how_it_works_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Route constants
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String roleSelect = '/roleselect';
  static const String studentHome = '/studentHome';
  static const String teacherHome = '/teacherHome';
  static const String imageViewer = '/imageViewer';
  static const String pdfViewScreen = '/pdf-view-screen';
  static const String textViewer = '/textViewer';
  static const String aiFeatures = '/aiFeatures';
  static const String listen = '/listen';
  static const String createClass = '/createClass';
  static const String recentStudies = '/recentStudies';
  static const String joinClass = '/joinClass';
  static const String classDetail = '/classDetail';
  static const String howItWorks = '/howItWorks';
  static const String flipQuiz = '/flipQuiz';
  static const String quizReview = '/quizReview';
  static const String savedStudies = '/savedStudies';
  static const String savedStudyDetail = '/savedStudyDetail';
  static const String qaScreen = '/qaScreen';
  static const String classWorkspace = '/classWorkspace';
  static const String createLesson = '/createLesson';
  static const String aiProcessing = '/aiProcessing';
  static const String lessonPreview = '/lessonPreview';
  static const String studentClassView = '/studentClassView';
  static const String allClasses = '/allClasses';
  static const String allSavedLessons = '/allSavedLessons';
  static const String savedLessonDetail = '/savedLessonDetail';
  static const String quizDetail = '/quizDetail';
  static const String addQuestion = '/addQuestion';
  static const String lessonView = '/lessonView';
  static const String studentLessonDetail = '/studentLessonDetail';
  static const String allEnrolledClasses = '/allEnrolledClasses';




  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case signup:
        return _buildRoute(const SignUpScreen(), settings);
      case roleSelect:
        return _buildRoute(const RoleSelectScreen(), settings);
      case studentHome:
        return _buildRoute(const StudentHomeScreen(), settings);
      case textViewer:
        return _buildRoute(const TextPreviewScreen(), settings);
      case pdfViewScreen:
        return _buildRoute(const PdfViewScreen(), settings);
      case aiFeatures:
        return MaterialPageRoute(
            builder: (_) => const AIFeaturesScreen(), settings: settings);
      case listen:
        return _buildRoute(const ListenScreen(), settings);
      case teacherHome:
        return _buildRoute(const TeacherHomeScreen(), settings);
      case joinClass:
        return MaterialPageRoute(
            builder: (_) => const JoinClassScreen(), settings: settings);
      case quizReview:
        return MaterialPageRoute(
            builder: (_) => const QuizReviewScreen(), settings: settings);
      case flipQuiz:
        return MaterialPageRoute(
            builder: (_) => const FlipQuizScreen(), settings: settings);
      case howItWorks:
        return MaterialPageRoute(
            builder: (_) => const HowItWorksScreen(), settings: settings);
      case savedStudies:
        return MaterialPageRoute(
            builder: (_) => const SavedStudiesScreen(), settings: settings);
      case savedStudyDetail:
        return MaterialPageRoute(
            builder: (_) => const SavedStudyDetailScreen(), settings: settings);
      case qaScreen:
        return MaterialPageRoute(
            builder: (_) => const QAScreen(), settings: settings);
      case classWorkspace:
        return MaterialPageRoute(
            builder: (_) => const ClassWorkspaceScreen(), settings: settings);
      case createLesson:
        return MaterialPageRoute(
            builder: (_) => const CreateLessonScreen(), settings: settings);
      case lessonPreview:
        return MaterialPageRoute(
            builder: (_) => const LessonPreviewScreen(), settings: settings);
      case createClass:
        return _buildRoute(const CreateClassScreen(), settings);
      case aiProcessing:
        return _buildRoute(const AIProcessingScreen(), settings);
      case allClasses:
        return MaterialPageRoute(
          builder: (_) => const AllClassesScreen(),
          settings: settings,
        );
      case allSavedLessons:
        return MaterialPageRoute(
          builder: (_) => const AllSavedLessonsScreen(),
          settings: settings,
        );
      case savedLessonDetail:
        return MaterialPageRoute(
            builder: (_) => const SavedLessonDetailScreen(), settings: settings);
      case quizDetail:
        return MaterialPageRoute(builder: (_) => const QuizDetailScreen(), settings: settings);
      case addQuestion:
        return MaterialPageRoute(builder: (_) => const AddQuestionScreen(), settings: settings);
      case lessonView:
        return MaterialPageRoute(builder: (_) => const LessonViewScreen(), settings: settings);
      case studentClassView:
        return MaterialPageRoute(
            builder: (_) => const StudentClassViewScreen(), settings: settings);
      case studentLessonDetail:
        return MaterialPageRoute(
            builder: (_) => const StudentLessonDetailScreen(), settings: settings);
      case allEnrolledClasses:
        return MaterialPageRoute(
            builder: (_) => const AllEnrolledClassesScreen(), settings: settings);

        default:
        return _buildRoute(
            Scaffold(
                body: Center(
                    child: Text('No route for ${settings.name}'))),
            settings);
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}