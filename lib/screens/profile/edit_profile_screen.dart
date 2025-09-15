import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final bool isFirstTime;

  const EditProfileScreen({super.key, this.isFirstTime = false});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _licenseController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  bool _isAvailable = true;
  List<String> _selectedSpecializations = [];
  bool _isLoading = false;

  final List<String> _availableSpecializations = [
    'Elderly Care',
    'Child Care',
    'Medical Care',
    'Disability Support',
    'Companionship',
    'Personal Care',
    'Housekeeping',
    'Meal Preparation',
    'Transportation',
    'Medication Management',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    if (!widget.isFirstTime) {
      final profile = ref.read(currentUserProfileProvider);
      if (profile != null) {
        _nameController.text = profile.name;
        _phoneController.text = profile.phone ?? '';
        _bioController.text = profile.bio ?? '';
        _selectedRole = profile.role;
        _isAvailable = profile.isAvailable ?? true;
        _selectedSpecializations = profile.specializations ?? [];
        _hourlyRateController.text = profile.hourlyRate?.toString() ?? '';
        _yearsExperienceController.text = profile.yearsExperience?.toString() ?? '';
        _licenseController.text = profile.license ?? '';
        setState(() {});
      }
    } else {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _nameController.text = user.name;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _yearsExperienceController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstTime ? 'Create Profile' : 'Edit Profile'),
        backgroundColor: const Color(0xFF2E7D8A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFirstTime) ...[
                const Text(
                  'Welcome to Christy Cares!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D8A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please complete your profile to get started.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
              ],

              // Basic Information
              _buildSection(
                'Basic Information',
                [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      border: OutlineInputBorder(),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(),
                      hintText: 'Tell us about yourself...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),

              // Caregiver Specific Fields
              if (_selectedRole == UserRole.caregiver) ...[
                const SizedBox(height: 24),
                _buildSection(
                  'Caregiver Information',
                  [
                    // Specializations
                    const Text(
                      'Specializations',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSpecializations.map((spec) {
                        final isSelected = _selectedSpecializations.contains(spec);
                        return FilterChip(
                          label: Text(spec),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSpecializations.add(spec);
                              } else {
                                _selectedSpecializations.remove(spec);
                              }
                            });
                          },
                          selectedColor: const Color(0xFF2E7D8A).withOpacity(0.3),
                          checkmarkColor: const Color(0xFF2E7D8A),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hourlyRateController,
                      decoration: const InputDecoration(
                        labelText: 'Hourly Rate (\$)',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearsExperienceController,
                      decoration: const InputDecoration(
                        labelText: 'Years of Experience',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(
                        labelText: 'License/Certification',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Available for appointments'),
                      subtitle: const Text('Toggle your availability status'),
                      value: _isAvailable,
                      onChanged: (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                      activeColor: const Color(0xFF2E7D8A),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.isFirstTime ? 'Create Profile' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D8A),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please log in again.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = UserProfile(
        uid: user.$id,
        name: _nameController.text.trim(),
        email: user.email,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        role: _selectedRole,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        specializations: _selectedRole == UserRole.caregiver && _selectedSpecializations.isNotEmpty
            ? _selectedSpecializations
            : null,
        hourlyRate: _selectedRole == UserRole.caregiver && _hourlyRateController.text.isNotEmpty
            ? double.tryParse(_hourlyRateController.text)
            : null,
        yearsExperience: _selectedRole == UserRole.caregiver && _yearsExperienceController.text.isNotEmpty
            ? int.tryParse(_yearsExperienceController.text)
            : null,
        license: _selectedRole == UserRole.caregiver && _licenseController.text.trim().isNotEmpty
            ? _licenseController.text.trim()
            : null,
        isAvailable: _selectedRole == UserRole.caregiver ? _isAvailable : null,
      );

      final notifier = ref.read(profileNotifierProvider.notifier);
      if (widget.isFirstTime) {
        await notifier.createProfile(profile);
      } else {
        await notifier.updateProfile(user.$id, profile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isFirstTime ? 'Profile created successfully!' : 'Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}