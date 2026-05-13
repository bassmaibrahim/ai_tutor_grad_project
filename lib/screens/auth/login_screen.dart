// lib/screens/auth/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_routes.dart';
import '../../../constants/app_typography.dart';
import '../../constants/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/AuthCard.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/button/button_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if this user already has a role stored in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      final role = doc.data()?['role'];

      if (role != null) {
        // Role exists – go straight to the correct home
        final route = role == 'student'
            ? AppRoutes.studentHome
            : AppRoutes.teacherHome;
        Navigator.pushReplacementNamed(context, route);
      } else {
        // No role yet (shouldn't happen after sign‑up, but handle gracefully)
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelect);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'No account found with this email.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Incorrect password.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      title: 'Welcome back',
      subtitle: 'Continue your academic mastery',
      formContent: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              labelText: 'Email Address',
              hintText: 'scholar@university.edu',
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email required';
                if (!Validators.isValidEmail(v)) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            AuthTextField(
              labelText: 'Password',
              hintText: '••••••••',
              obscureText: _obscurePassword,
              controller: _passwordController,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password required';
                if (!Validators.hasMinLength(v, 6)) return 'Min 6 characters';
                return null;
              },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password reset feature coming soon.')),
                  );
                },
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.caption.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AppButton(
                  variant: AppButtonVariant.primary,
                  text: 'Login to Account',
                  onPressed: _handleLogin,
                ),
              ),
          ],
        ),
      ),
      bottomLink: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "New to Eshrhly?",
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.signup),
            child: Text(
              'Sign Up instead',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}