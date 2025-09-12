import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gap/gap.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_config.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  List<String> _selectedServices = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(currentUserProfileProvider);
    if (profile == null) return;

    // Validate caregiver-specific requirements
    if (profile.isCaregiver) {
      if (_bioController.text.trim().isEmpty) {
        _showErrorSnackBar('Please provide a bio describing your experience');
        return;
      }
      if (_selectedServices.isEmpty) {
        _showErrorSnackBar('Please select at least one service you provide');
        return;
      }
    }

    if (_locationController.text.trim().isEmpty) {
      _showErrorSnackBar('Please provide your location');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'services': _selectedServices,
      };

      if (profile.isCaregiver && _hourlyRateController.text.trim().isNotEmpty) {
        updates['hourlyRate'] = double.tryParse(_hourlyRateController.text.trim());
      }

      await ref.read(authNotifierProvider.notifier).updateProfile(updates);
      
      if (mounted) {
        _showSuccessSnackBar('Profile completed successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update profile. Please try again.');
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(currentUserProfileProvider);
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    if (profile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Your Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWideScreen ? 32 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome message
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
                                profile.isCaregiver ? Icons.volunteer_activism : Icons.health_and_safety,
                                size: 40,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Gap(24),
                            Text(
                              'Welcome, ${profile.name}!',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              'Let\'s complete your profile to get started',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const Gap(40),

                      // Location field (required for all)
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 100),
                        child: CustomTextField(
                          controller: _locationController,
                          labelText: 'Location *',
                          hintText: 'Enter your city and state',
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          prefixIcon: Icons.location_on_outlined,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Please enter your location';
                            }
                            return null;
                          },
                        ),
                      ),

                      if (profile.isCaregiver) ...[
                        const Gap(20),

                        // Bio field (required for caregivers)
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 200),
                          child: CustomTextField(
                            controller: _bioController,
                            labelText: 'About You *',
                            hintText: 'Tell patients about your experience and qualifications',
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            prefixIcon: Icons.person_outlined,
                            maxLines: 4,
                            minLines: 3,
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Please provide information about yourself';
                              }
                              if (value!.trim().length < 50) {
                                return 'Please provide at least 50 characters';
                              }
                              return null;
                            },
                          ),
                        ),

                        const Gap(20),

                        // Hourly rate field (optional for caregivers)
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 300),
                          child: CustomTextField(
                            controller: _hourlyRateController,
                            labelText: 'Hourly Rate (Optional)',
                            hintText: 'Enter your hourly rate in USD',
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.attach_money,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final rate = double.tryParse(value);
                                if (rate == null || rate <= 0) {
                                  return 'Please enter a valid hourly rate';
                                }
                              }
                              return null;
                            },
                          ),
                        ),

                        const Gap(24),

                        // Services selection (required for caregivers)
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Services You Provide *',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                'Select all services you can provide',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                                ),
                              ),
                              const Gap(16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: AppConfig.serviceCategories.map((service) {
                                  final isSelected = _selectedServices.contains(service);
                                  return FilterChip(
                                    label: Text(service),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedServices.add(service);
                                        } else {
                                          _selectedServices.remove(service);
                                        }
                                      });
                                    },
                                    backgroundColor: colorScheme.surface,
                                    selectedColor: colorScheme.primaryContainer,
                                    checkmarkColor: colorScheme.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected 
                                          ? colorScheme.primary 
                                          : colorScheme.onSurface,
                                      fontWeight: isSelected 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                    side: BorderSide(
                                      color: isSelected 
                                          ? colorScheme.primary 
                                          : colorScheme.outline,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Gap(40),

                      // Complete profile button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleCompleteProfile,
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
                                  'Complete Profile',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const Gap(16),

                      // Skip for now button (only for optional fields)
                      if (!profile.isCaregiver)
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 600),
                          child: TextButton(
                            onPressed: () {
                              // Set minimal required data
                              _locationController.text = 'Not specified';
                              _handleCompleteProfile();
                            },
                            child: Text(
                              'Skip for Now',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                              ),
                            ),
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
}