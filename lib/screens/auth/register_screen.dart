import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gap/gap.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../config/app_config.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String _selectedRole = AppConfig.rolePatient;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _phoneFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showErrorSnackBar('Please accept the Terms of Service and Privacy Policy');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );
      
      if (mounted) {
        _showSuccessSnackBar('Account created successfully! Welcome aboard!');
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Registration failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const Gap(12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, 
                color: Theme.of(context).colorScheme.onPrimary),
            const Gap(12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter a password';
    }
    if (value!.length < AppConfig.passwordMinLength) {
      return 'Password must be at least ${AppConfig.passwordMinLength} characters long';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and a number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    // Listen to auth state for errors
    ref.listen<String?>(authErrorProvider, (previous, error) {
      if (error != null) {
        _showErrorSnackBar(error);
      }
    });

    return LoadingOverlay(
      isLoading: _isLoading || ref.watch(isAuthLoadingProvider),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWideScreen ? 32 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and title
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha((255 * 0.1).round()),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_add,
                                size: 40,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Gap(24),
                            Text(
                              'Create Account',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              'Join the caregiving community',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Gap(40),

                      // Role selection
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I am a:',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Gap(12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRoleCard(
                                    role: AppConfig.rolePatient,
                                    title: 'Patient/Family',
                                    subtitle: 'Looking for care',
                                    icon: Icons.health_and_safety,
                                    isSelected: _selectedRole == AppConfig.rolePatient,
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: _buildRoleCard(
                                    role: AppConfig.roleCaregiver,
                                    title: 'Caregiver',
                                    subtitle: 'Providing care',
                                    icon: Icons.volunteer_activism,
                                    isSelected: _selectedRole == AppConfig.roleCaregiver,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Gap(24),

                      // Full name field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: CustomTextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.person_outlined,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Please enter your full name';
                            }
                            if (value!.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                        ),
                      ),

                      const Gap(20),

                      // Email field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: CustomTextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          labelText: 'Email Address',
                          hintText: 'Enter your email address',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Please enter your email address';
                            }
                            if (!AppConfig.isValidEmail(value!)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                      ),

                      const Gap(20),

                      // Password field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: CustomTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          labelText: 'Password',
                          hintText: 'Create a strong password',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.lock_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                        ),
                      ),

                      const Gap(20),

                      // Confirm password field
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: CustomTextField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          labelText: 'Confirm Password',
                          hintText: 'Re-enter your password',
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.lock_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: _validateConfirmPassword,
                          onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                        ),
                      ),

                      const Gap(20),

                      // Phone number field (optional)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: CustomTextField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          labelText: 'Phone Number (Optional)',
                          hintText: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.phone_outlined,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!AppConfig.isValidPhone(value)) {
                                return 'Please enter a valid phone number';
                              }
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _locationFocus.requestFocus(),
                        ),
                      ),

                      const Gap(20),

                      // Location field (optional)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 700),
                        child: CustomTextField(
                          controller: _locationController,
                          focusNode: _locationFocus,
                          labelText: 'Location (Optional)',
                          hintText: 'City, State',
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          prefixIcon: Icons.location_on_outlined,
                          onFieldSubmitted: (_) => _handleRegister(),
                        ),
                      ),

                      const Gap(24),

                      // Terms and conditions
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 800),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: RichText(
                                  text: TextSpan(
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                                    ),
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Gap(32),

                      // Register button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 900),
                        child: FilledButton(
                          onPressed: (_isLoading || !_acceptTerms) ? null : _handleRegister,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const Gap(24),

                      // Sign in link
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 1000),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withAlpha((255 * 0.5).round()),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withAlpha((255 * 0.7).round()),
            ),
            const Gap(8),
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.primary.withAlpha((255 * 0.8).round())
                    : colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}