import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF2E7D8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: profile == null
          ? _buildCreateProfilePrompt(context, ref, user)
          : _buildProfileContent(context, profile),
    );
  }

  Widget _buildCreateProfilePrompt(BuildContext context, WidgetRef ref, user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add,
              size: 80,
              color: Color(0xFF2E7D8A),
            ),
            const SizedBox(height: 24),
            const Text(
              'Complete Your Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D8A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Set up your profile to get started with Christy Cares',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(isFirstTime: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfile profile) {
    return SingleChildScrollView(
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
                    backgroundColor: const Color(0xFF2E7D8A),
                    backgroundImage: profile.profileImageUrl != null
                        ? NetworkImage(profile.profileImageUrl!)
                        : null,
                    child: profile.profileImageUrl == null
                        ? Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                          profile.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(profile.role),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile.role.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

          const SizedBox(height: 16),

          // Basic Information
          _buildSection(
            'Basic Information',
            [
              _buildInfoTile('Phone', profile.phone ?? 'Not provided', Icons.phone),
              if (profile.bio != null)
                _buildInfoTile('Bio', profile.bio!, Icons.info),
            ],
          ),

          // Caregiver Specific Information
          if (profile.isCaregiver) ...[
            const SizedBox(height: 16),
            _buildSection(
              'Caregiver Information',
              [
                if (profile.specializations != null && profile.specializations!.isNotEmpty)
                  _buildInfoTile(
                    'Specializations',
                    profile.specializations!.join(', '),
                    Icons.star,
                  ),
                if (profile.rating != null)
                  _buildInfoTile(
                    'Rating',
                    '${profile.rating!.toStringAsFixed(1)} ⭐',
                    Icons.star_rate,
                  ),
                if (profile.hourlyRate != null)
                  _buildInfoTile(
                    'Hourly Rate',
                    '\$${profile.hourlyRate!.toStringAsFixed(2)}/hour',
                    Icons.attach_money,
                  ),
                if (profile.yearsExperience != null)
                  _buildInfoTile(
                    'Experience',
                    '${profile.yearsExperience} years',
                    Icons.work,
                  ),
                if (profile.license != null)
                  _buildInfoTile('License', profile.license!, Icons.verified),
                _buildInfoTile(
                  'Availability',
                  profile.isAvailable == true ? 'Available' : 'Not Available',
                  Icons.schedule,
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Account Information
          _buildSection(
            'Account Information',
            [
              _buildInfoTile(
                'Member Since',
                _formatDate(profile.createdAt),
                Icons.calendar_today,
              ),
              _buildInfoTile(
                'Last Updated',
                _formatDate(profile.updatedAt),
                Icons.update,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D8A),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return Colors.blue;
      case UserRole.caregiver:
        return Colors.green;
      case UserRole.admin:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;

    return '$month $day, $year';
  }
}