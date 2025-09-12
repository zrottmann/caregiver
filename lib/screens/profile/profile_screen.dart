import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/edit-profile'),
          ),
        ],
      ),
      body: userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            backgroundImage: userProfile.profileImageUrl != null
                                ? NetworkImage(userProfile.profileImageUrl!)
                                : null,
                            child: userProfile.profileImageUrl == null
                                ? Text(
                                    userProfile.name.isNotEmpty
                                        ? userProfile.name[0].toUpperCase()
                                        : 'U',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userProfile.email,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: userProfile.isCaregiver
                                        ? Colors.green.withAlpha((255 * 0.1).round())
                                        : Colors.blue.withAlpha((255 * 0.1).round()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    userProfile.isCaregiver ? 'Caregiver' : 'Patient/Family',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: userProfile.isCaregiver ? Colors.green : Colors.blue,
                                      fontWeight: FontWeight.w500,
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
                  
                  const SizedBox(height: 24),
                  
                  // Profile Information
                  Text(
                    'Profile Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (userProfile.bio?.isNotEmpty == true) ...[
                    _buildInfoCard(
                      context,
                      icon: Icons.info_outline,
                      title: 'Bio',
                      content: userProfile.bio!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  if (userProfile.location?.isNotEmpty == true) ...[
                    _buildInfoCard(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      content: userProfile.location!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  if (userProfile.phoneNumber?.isNotEmpty == true) ...[
                    _buildInfoCard(
                      context,
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      content: userProfile.phoneNumber!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Caregiver Specific Information
                  if (userProfile.isCaregiver) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Professional Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (userProfile.services.isNotEmpty) ...[
                      _buildInfoCard(
                        context,
                        icon: Icons.work_outline,
                        title: 'Services Offered',
                        content: userProfile.services.join(', '),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    if (userProfile.hourlyRate != null) ...[
                      _buildInfoCard(
                        context,
                        icon: Icons.attach_money,
                        title: 'Hourly Rate',
                        content: '\$${userProfile.hourlyRate!.toStringAsFixed(2)}/hour',
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    if (userProfile.rating != null && userProfile.reviewCount != null) ...[
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.star_outline),
                          title: const Text('Rating'),
                          subtitle: Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < userProfile.rating!.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${userProfile.rating!.toStringAsFixed(1)} (${userProfile.reviewCount} reviews)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Profile Completeness
                  if (!_isProfileComplete(userProfile)) ...[
                    Card(
                      color: Colors.orange.withAlpha((255 * 0.1).round()),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Complete Your Profile',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add more information to get better matches',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/edit-profile'),
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Action Buttons
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit Profile'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/edit-profile'),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showChangePasswordDialog(context, ref),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Help & Support'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showFeatureNotAvailable(context),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            'Logout',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onTap: () => _showLogoutDialog(context, ref),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(content),
      ),
    );
  }

  bool _isProfileComplete(userProfile) {
    if (userProfile.isCaregiver) {
      return userProfile.bio?.isNotEmpty == true &&
          userProfile.location?.isNotEmpty == true &&
          userProfile.phoneNumber?.isNotEmpty == true &&
          userProfile.services.isNotEmpty &&
          userProfile.hourlyRate != null;
    } else {
      return userProfile.bio?.isNotEmpty == true &&
          userProfile.location?.isNotEmpty == true &&
          userProfile.phoneNumber?.isNotEmpty == true;
    }
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ref.read(authNotifierProvider.notifier).updatePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showFeatureNotAvailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}