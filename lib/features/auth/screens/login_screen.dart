import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  void _handleSignIn() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed in successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        children: [
          AuthBrandHeader(
                subtitle:
                    'Welcome back! Sign in to continue your nutrition journey',
              )
              .animate()
              .fade(duration: 500.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
          const SizedBox(height: 20),
          AuthFormCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: AppTextStyles.textLink.copyWith(
                                fontSize: 12,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppFormField(
                        controller: _passwordController,
                        hintText: 'Enter your password',
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
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      AuthButton(
                        text: 'Sign In',
                        isLoading: _isLoading,
                        onPressed: _handleSignIn,
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
              )
              .animate()
              .fade(delay: 150.ms, duration: 600.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SignUpScreen(),
                    ),
                  );
                },
                child: Text(
                  'Sign Up',
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
