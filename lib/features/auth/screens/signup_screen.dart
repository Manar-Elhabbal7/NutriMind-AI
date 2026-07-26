import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_form_field.dart';
import '../services/auth_service.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_form_card.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/auth_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

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
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final account = await AuthService.instance.signInWithGoogle();
      if (!mounted || account == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${account.displayName ?? account.email}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _handleSignUp() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBackButton: true,
      child: Column(
        children: [
          AuthBrandHeader(
            subtitle: 'Create your account to start your nutrition journey.',
          ),
          const SizedBox(height: 20),
          AuthFormCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Full Name',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppFormField(
                    controller: _nameController,
                    hintText: 'Manar Elhabbal',
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Email',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppFormField(
                    controller: _emailController,
                    hintText: 'elhabbal@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Password',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppFormField(
                    controller: _passwordController,
                    hintText: 'Create a password',
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Confirm Password',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppFormField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  AuthButton(
                    text: 'Create Account',
                    isLoading: _isLoading,
                    onPressed: _handleSignUp,
                  ),
                  const SizedBox(height: 20),
                  const AuthDivider(),
                  const SizedBox(height: 20),
                  GoogleSignInButton(
                    isLoading: _isGoogleLoading,
                    onPressed: _handleGoogleSignIn,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'Sign In',
                  style: AppTextStyles.textLink.copyWith(
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
