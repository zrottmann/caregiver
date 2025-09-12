import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/caregiver.dart';
import '../models/user_profile.dart';
import '../providers/search_provider.dart';

class CaregiverCard extends ConsumerWidget {
  final dynamic caregiver; // Can be either Caregiver or UserProfile
  final VoidCallback? onTap;
  final bool showDistance;
  final double? distance;

  const CaregiverCard({
    super.key,
    required this.caregiver,
    this.onTap,
    this.showDistance = false,
    this.distance,
  });

  // Helper methods to handle both Caregiver and UserProfile
  String _getId() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).id;
    } else if (caregiver is UserProfile) {
      return (caregiver as UserProfile).id;
    }
    return '';
  }

  String _getName() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).name;
    } else if (caregiver is UserProfile) {
      return (caregiver as UserProfile).name;
    }
    return '';
  }

  String? _getLocation() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).location;
    } else if (caregiver is UserProfile) {
      return (caregiver as UserProfile).location;
    }
    return null;
  }

  double _getRating() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).rating;
    } else if (caregiver is UserProfile) {
      return (caregiver as UserProfile).rating ?? 0.0;
    }
    return 0.0;
  }

  int _getReviewCount() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).reviewCount;
    } else if (caregiver is UserProfile) {
      return (caregiver as UserProfile).reviewCount ?? 0;
    }
    return 0;
  }

  double? _getHourlyRate() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).hourlyRate;
    } else if (caregiver is UserProfile) {
      return (caregiver as UserProfile).hourlyRate;
    }
    return null;
  }

  String? _getBio() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).bio;
    } else if (caregiver is UserProfile) {
      return (caregiver as UserProfile).bio;
    }
    return null;
  }

  List<String> _getServices() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).services;
    } else if (caregiver is UserProfile) {
      return (caregiver as UserProfile).services;
    }
    return [];
  }

  bool _getAvailability() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).isAvailable;
    } else if (caregiver is UserProfile) {
      // UserProfile doesn't have isAvailable, assume true
      return true;
    }
    return true;
  }

  String? _getProfileImageUrl() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).profileImageUrl;
    } else if (caregiver is UserProfile) {
      return (caregiver as UserProfile).profileImageUrl;
    }
    return null;
  }

  int _getExperienceYears() {
    if (caregiver is Caregiver) {
      return (caregiver as Caregiver).experienceYears;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteCaregiversProvider).contains(_getId());
    final name = _getName();
    final location = _getLocation();
    final rating = _getRating();
    final reviewCount = _getReviewCount();
    final hourlyRate = _getHourlyRate();
    final bio = _getBio();
    final services = _getServices();
    final isAvailable = _getAvailability();
    final profileImageUrl = _getProfileImageUrl();
    final experienceYears = _getExperienceYears();

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap ?? () => _navigateToCaregiverProfile(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildProfileImage(profileImageUrl, name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                              onPressed: () {
                                ref.read(favoriteCaregiversProvider.notifier)
                                   .toggleFavorite(_getId());
                              },
                            ),
                          ],
                        ),
                        if (location != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                                  ),
                                ),
                              ),
                              if (showDistance && distance != null)
                                Text(
                                  '${distance!.toStringAsFixed(1)} km away',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Rating and experience
              Row(
                children: [
                  _buildRatingWidget(rating, reviewCount),
                  if (experienceYears > 0) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.work_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$experienceYears years exp.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Services
              if (services.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: services.take(3).map((service) {
                    return Chip(
                      label: Text(
                        service.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              
              // Bio
              if (bio != null && bio.isNotEmpty) ...[
                Text(
                  bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Bottom row with price and availability
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hourlyRate != null)
                    Text(
                      '\$${hourlyRate.toStringAsFixed(0)}/hour',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAvailable ? 'Available' : 'Busy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isAvailable ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? profileImageUrl, String name) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.grey.withAlpha((255 * 0.3).round()),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: profileImageUrl != null
            ? Image.network(
                profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar(name);
                },
              )
            : _buildDefaultAvatar(name),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'C',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingWidget(double rating, int reviewCount) {
    return Row(
      children: [
        const Icon(
          Icons.star,
          size: 16,
          color: Colors.amber,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          ' ($reviewCount)',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _navigateToCaregiverProfile(BuildContext context) {
    // Navigate to caregiver profile screen using go_router
    context.push('/caregiver-profile/${_getId()}');
  }
}