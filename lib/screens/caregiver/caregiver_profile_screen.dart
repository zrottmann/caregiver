import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/caregiver.dart';
import '../../models/service_category.dart';
import '../../providers/search_provider.dart';

class CaregiverProfileScreen extends ConsumerWidget {
  final String caregiverId;

  const CaregiverProfileScreen({super.key, required this.caregiverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caregiverAsync = ref.watch(caregiverProvider(caregiverId));
    final isFavorite = ref.watch(favoriteCaregiversProvider).contains(caregiverId);

    return Scaffold(
      body: caregiverAsync.when(
        data: (caregiver) => _buildProfileContent(context, ref, caregiver, isFavorite),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Caregiver not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, Caregiver caregiver, bool isFavorite) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeaderSection(context, caregiver),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: () {
                ref.read(favoriteCaregiversProvider.notifier).toggleFavorite(caregiverId);
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfo(context, caregiver),
                const SizedBox(height: 24),
                _buildServicesSection(context, caregiver),
                const SizedBox(height: 24),
                _buildAboutSection(context, caregiver),
                const SizedBox(height: 24),
                _buildExperienceSection(context, caregiver),
                const SizedBox(height: 24),
                _buildCertificationsSection(context, caregiver),
                const SizedBox(height: 24),
                _buildAvailabilitySection(context, caregiver),
                const SizedBox(height: 24),
                _buildLanguagesSection(context, caregiver),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context, Caregiver caregiver) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withAlpha((255 * 0.8).round()),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.2).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: caregiver.profileImageUrl != null
                      ? Image.network(
                          caregiver.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar(caregiver.name);
                          },
                        )
                      : _buildDefaultAvatar(caregiver.name),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                caregiver.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (caregiver.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      caregiver.location!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'C',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context, Caregiver caregiver) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context: context,
            icon: Icons.star,
            title: 'Rating',
            value: '${caregiver.rating.toStringAsFixed(1)}/5',
            subtitle: '${caregiver.reviewCount} reviews',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            context: context,
            icon: Icons.attach_money,
            title: 'Rate',
            value: caregiver.hourlyRate != null ? '\$${caregiver.hourlyRate!.toStringAsFixed(0)}' : 'N/A',
            subtitle: 'per hour',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            context: context,
            icon: Icons.work,
            title: 'Experience',
            value: '${caregiver.experienceYears}',
            subtitle: caregiver.experienceYears == 1 ? 'year' : 'years',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context, Caregiver caregiver) {
    if (caregiver.services.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context: context,
      title: 'Services Offered',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: caregiver.services.map((serviceId) {
          final category = ServiceCategory.getCategoryById(serviceId);
          return Chip(
            avatar: Icon(
              category?.icon ?? Icons.help_outline,
              size: 16,
              color: category?.color ?? Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              category?.name ?? serviceId.replaceAll('_', ' '),
              style: TextStyle(
                color: category?.color ?? Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: (category?.color ?? Theme.of(context).colorScheme.primary).withAlpha((255 * 0.1).round()),
            side: BorderSide(
              color: (category?.color ?? Theme.of(context).colorScheme.primary).withAlpha((255 * 0.3).round()),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, Caregiver caregiver) {
    if (caregiver.bio == null && caregiver.description == null) return const SizedBox.shrink();

    return _buildSection(
      context: context,
      title: 'About',
      child: Text(
        caregiver.description ?? caregiver.bio ?? '',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildExperienceSection(BuildContext context, Caregiver caregiver) {
    return _buildSection(
      context: context,
      title: 'Experience & Availability',
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline, size: 20),
              const SizedBox(width: 8),
              Text(
                '${caregiver.experienceYears} ${caregiver.experienceYears == 1 ? 'year' : 'years'} of professional experience',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: caregiver.isAvailable ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                caregiver.isAvailable ? 'Currently Available' : 'Currently Busy',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: caregiver.isAvailable ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection(BuildContext context, Caregiver caregiver) {
    if (caregiver.certifications.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context: context,
      title: 'Certifications',
      child: Column(
        children: caregiver.certifications.map((cert) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cert,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvailabilitySection(BuildContext context, Caregiver caregiver) {
    if (caregiver.availability.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context: context,
      title: 'Available Days',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: caregiver.availability.map((day) {
          return Chip(
            label: Text(day),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguagesSection(BuildContext context, Caregiver caregiver) {
    if (caregiver.languages.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      context: context,
      title: 'Languages',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: caregiver.languages.map((language) {
          return Chip(
            avatar: const Icon(Icons.language, size: 16),
            label: Text(language),
            backgroundColor: Colors.blue.withAlpha((255 * 0.1).round()),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}