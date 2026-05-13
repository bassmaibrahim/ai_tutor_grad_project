import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_routes.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_typography.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/AuthCard.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/button/button_widget.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Create Firebase Auth user
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Step 2: Update display name in Auth
      await userCredential.user!.updateDisplayName(_nameController.text.trim());
      await userCredential.user!.reload();

      // ✅ Step 3: SAVE USER TO FIRESTORE (THIS WAS MISSING!)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid) // Use auth UID as document ID
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': null, // Will be set in role selection screen
        'createdAt': FieldValue.serverTimestamp(),
        'profilePicUrl': null,
        'enrolledClasses': [], // Empty array for students
      });

      // Step 4: Navigate to role selection
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelect);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'Email already in use';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'Password is too weak';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Invalid email address';
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
      title: 'Create Account',
      subtitle: 'Start your learning journey today.',
      formContent: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              controller: _nameController,
              validator: (v) =>
              v == null || v.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            AuthTextField(
              labelText: 'Email',
              hintText: 'example@scholar.com',
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
              hintText: 'Create a strong password',
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
            const SizedBox(height: AppSpacing.md),

            AuthTextField(
              labelText: 'Confirm Password',
              hintText: '••••••••',
              obscureText: _obscureConfirmPassword,
              controller: _confirmPasswordController,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return 'Please confirm your password';
                if (v != _passwordController.text)
                  return 'Passwords do not match';
                return null;
              },
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.caption.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AppButton(
                  variant: AppButtonVariant.primary,
                  text: 'Sign Up →',
                  onPressed: _handleSignUp,
                ),
              ),
          ],
        ),
      ),
      bottomLink: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
            child: Text(
              'Log In',
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