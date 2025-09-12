import 'dart:math';
import '../config/app_config.dart';
import '../models/caregiver.dart';
import '../models/search_filter.dart';
import '../models/search_result.dart';

class SearchService {
  static const int defaultPageSize = 20;

  // Mock data - in a real app, this would come from your backend
  static List<Caregiver> _mockCaregivers = [];

  static void initializeMockData() {
    if (_mockCaregivers.isNotEmpty) return;

    final random = Random();
    final names = [
      'Sarah Johnson', 'Michael Smith', 'Emily Davis', 'David Wilson',
      'Jessica Brown', 'Christopher Jones', 'Amanda Taylor', 'Matthew Miller',
      'Ashley Anderson', 'Joshua Thomas', 'Samantha Jackson', 'Andrew White',
      'Jennifer Harris', 'Daniel Martin', 'Nicole Thompson', 'Ryan Garcia',
      'Michelle Martinez', 'Kevin Rodriguez', 'Stephanie Lewis', 'Tyler Lee'
    ];

    final services = [
      'senior_care', 'child_care', 'medical_care', 'disability_care',
      'mental_health', 'post_surgery', 'companion_care', 'respite_care'
    ];

    final locations = [
      'New York, NY', 'Los Angeles, CA', 'Chicago, IL', 'Houston, TX',
      'Phoenix, AZ', 'Philadelphia, PA', 'San Antonio, TX', 'San Diego, CA',
      'Dallas, TX', 'San Jose, CA', 'Austin, TX', 'Jacksonville, FL',
      'San Francisco, CA', 'Columbus, OH', 'Fort Worth, TX', 'Indianapolis, IN',
      'Charlotte, NC', 'Seattle, WA', 'Denver, CO', 'Boston, MA'
    ];

    final certifications = [
      'CPR Certified', 'First Aid', 'CNA License', 'RN License',
      'Home Health Aide', 'Certified Nursing Assistant', 'Physical Therapy Assistant',
      'Mental Health First Aid', 'Dementia Care Certified', 'Child Development Associate'
    ];

    final languages = ['English', 'Spanish', 'French', 'German', 'Italian', 'Chinese'];

    final availability = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    for (int i = 0; i < 50; i++) {
      final name = names[i % names.length];
      final location = locations[i % locations.length];
      
      // Generate mock coordinates for location-based search
      final baseLatitude = 40.7128 + (random.nextDouble() - 0.5) * 10;
      final baseLongitude = -74.0060 + (random.nextDouble() - 0.5) * 10;

      _mockCaregivers.add(
        Caregiver(
          id: 'caregiver_$i',
          userId: 'user_$i',
          name: name,
          email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
          bio: 'Experienced caregiver with a passion for helping others. Dedicated to providing compassionate and professional care.',
          location: location,
          phoneNumber: '+1${random.nextInt(9000000000) + 1000000000}',
          profileImageUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random',
          services: [
            services[random.nextInt(services.length)],
            if (random.nextBool()) services[random.nextInt(services.length)],
          ],
          hourlyRate: 20.0 + random.nextDouble() * 60.0, // $20-80/hour
          rating: 3.5 + random.nextDouble() * 1.5, // 3.5-5.0 rating
          reviewCount: random.nextInt(100) + 1,
          isAvailable: random.nextBool(),
          certifications: [
            certifications[random.nextInt(certifications.length)],
            if (random.nextBool()) certifications[random.nextInt(certifications.length)],
          ],
          experienceYears: random.nextInt(15) + 1,
          languages: [
            'English',
            if (random.nextBool()) languages[random.nextInt(languages.length)],
          ],
          address: '$location, USA',
          latitude: baseLatitude,
          longitude: baseLongitude,
          availability: List.generate(
            random.nextInt(4) + 3, // 3-6 days available
            (index) => availability[random.nextInt(availability.length)],
          ).toSet().toList(),
          description: 'Professional caregiver with extensive experience in ${services[random.nextInt(services.length)].replaceAll('_', ' ')}. Committed to providing high-quality, compassionate care.',
          createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
          updatedAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        ),
      );
    }
  }

  Future<SearchResult> searchCaregivers({
    required SearchFilter filter,
    int page = 1,
    int pageSize = defaultPageSize,
  }) async {
    try {
      initializeMockData();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Start with all caregivers
      List<Caregiver> results = List.from(_mockCaregivers);

      // Apply text search filter
      if (filter.query.isNotEmpty) {
        results = results.where((caregiver) {
          return caregiver.matchesSearchQuery(filter.query);
        }).toList();
      }

      // Apply service category filters
      if (filter.serviceCategories.isNotEmpty) {
        results = results.where((caregiver) {
          return caregiver.services.any((service) => filter.serviceCategories.contains(service));
        }).toList();
      }

      // Apply specific service filters
      if (filter.specificServices.isNotEmpty) {
        results = results.where((caregiver) {
          return filter.specificServices.every((service) => caregiver.services.contains(service));
        }).toList();
      }

      // Apply price range filter
      if (filter.priceRange != PriceRange.any) {
        results = results.where((caregiver) {
          if (caregiver.hourlyRate == null) return false;
          final rate = caregiver.hourlyRate!;
          final minPrice = filter.priceRangeMin;
          final maxPrice = filter.priceRangeMax;
          
          if (minPrice != null && rate < minPrice) return false;
          if (maxPrice != null && rate > maxPrice) return false;
          return true;
        }).toList();
      }

      // Apply custom price filters
      if (filter.minPrice != null) {
        results = results.where((caregiver) {
          return caregiver.hourlyRate != null && caregiver.hourlyRate! >= filter.minPrice!;
        }).toList();
      }

      if (filter.maxPrice != null) {
        results = results.where((caregiver) {
          return caregiver.hourlyRate != null && caregiver.hourlyRate! <= filter.maxPrice!;
        }).toList();
      }

      // Apply rating filter
      if (filter.minRating != null) {
        results = results.where((caregiver) {
          return caregiver.rating >= filter.minRating!;
        }).toList();
      }

      // Apply availability filter
      if (filter.availableNow) {
        results = results.where((caregiver) => caregiver.isAvailable).toList();
      }

      // Apply language filter
      if (filter.languages.isNotEmpty) {
        results = results.where((caregiver) {
          return filter.languages.any((language) => caregiver.languages.contains(language));
        }).toList();
      }

      // Apply certification filter
      if (filter.certifications.isNotEmpty) {
        results = results.where((caregiver) {
          return filter.certifications.any((cert) => caregiver.certifications.contains(cert));
        }).toList();
      }

      // Apply experience filter
      if (filter.minExperience != null) {
        results = results.where((caregiver) {
          return caregiver.experienceYears >= filter.minExperience!;
        }).toList();
      }

      // Apply location filter
      if (filter.location != null && filter.location!.isNotEmpty) {
        results = results.where((caregiver) {
          return caregiver.location?.toLowerCase().contains(filter.location!.toLowerCase()) ?? false;
        }).toList();
      }

      // Apply distance filter
      if (filter.maxDistance != null && filter.userLatitude != null && filter.userLongitude != null) {
        results = results.where((caregiver) {
          final distance = caregiver.distanceFrom(filter.userLatitude, filter.userLongitude);
          return distance != null && distance <= filter.maxDistance!;
        }).toList();
      }

      // Apply availability days filter
      if (filter.availability.isNotEmpty) {
        results = results.where((caregiver) {
          return filter.availability.any((day) => caregiver.availability.contains(day));
        }).toList();
      }

      // Sort results
      results = _sortCaregivers(results, filter);

      // Calculate pagination
      final totalCount = results.length;
      final startIndex = (page - 1) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, totalCount);
      
      final paginatedResults = results.sublist(
        startIndex.clamp(0, totalCount),
        endIndex,
      );

      final totalPages = (totalCount / pageSize).ceil();
      final hasMore = page < totalPages;

      return SearchResult(
        caregivers: paginatedResults,
        totalCount: totalCount,
        appliedFilter: filter,
        isLoading: false,
        hasMore: hasMore,
        currentPage: page,
        totalPages: totalPages,
      );
    } catch (error) {
      return SearchResult(
        appliedFilter: filter,
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  List<Caregiver> _sortCaregivers(List<Caregiver> caregivers, SearchFilter filter) {
    caregivers.sort((a, b) {
      int comparison = 0;

      switch (filter.sortBy) {
        case SortBy.relevance:
          // Relevance based on query match and rating
          if (filter.query.isNotEmpty) {
            final aRelevance = _calculateRelevance(a, filter.query);
            final bRelevance = _calculateRelevance(b, filter.query);
            comparison = bRelevance.compareTo(aRelevance);
          } else {
            comparison = b.rating.compareTo(a.rating);
          }
          break;

        case SortBy.rating:
          comparison = b.rating.compareTo(a.rating);
          if (comparison == 0) {
            comparison = b.reviewCount.compareTo(a.reviewCount);
          }
          break;

        case SortBy.price:
          final aPrice = a.hourlyRate ?? double.maxFinite;
          final bPrice = b.hourlyRate ?? double.maxFinite;
          comparison = aPrice.compareTo(bPrice);
          break;

        case SortBy.distance:
          if (filter.userLatitude != null && filter.userLongitude != null) {
            final aDistance = a.distanceFrom(filter.userLatitude, filter.userLongitude) ?? double.maxFinite;
            final bDistance = b.distanceFrom(filter.userLatitude, filter.userLongitude) ?? double.maxFinite;
            comparison = aDistance.compareTo(bDistance);
          } else {
            comparison = a.name.compareTo(b.name);
          }
          break;

        case SortBy.experience:
          comparison = b.experienceYears.compareTo(a.experienceYears);
          break;
      }

      return filter.sortDescending ? -comparison : comparison;
    });

    return caregivers;
  }

  int _calculateRelevance(Caregiver caregiver, String query) {
    final queryLower = query.toLowerCase();
    int score = 0;

    // Name match gets highest score
    if (caregiver.name.toLowerCase().contains(queryLower)) {
      score += 10;
    }

    // Service match
    if (caregiver.services.any((service) => service.toLowerCase().contains(queryLower))) {
      score += 8;
    }

    // Location match
    if (caregiver.location?.toLowerCase().contains(queryLower) ?? false) {
      score += 6;
    }

    // Bio match
    if (caregiver.bio?.toLowerCase().contains(queryLower) ?? false) {
      score += 4;
    }

    // Certification match
    if (caregiver.certifications.any((cert) => cert.toLowerCase().contains(queryLower))) {
      score += 3;
    }

    // Language match
    if (caregiver.languages.any((lang) => lang.toLowerCase().contains(queryLower))) {
      score += 2;
    }

    return score;
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];

    initializeMockData();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final suggestions = <String>{};
    final queryLower = query.toLowerCase();

    // Add matching caregiver names
    for (final caregiver in _mockCaregivers) {
      if (caregiver.name.toLowerCase().contains(queryLower)) {
        suggestions.add(caregiver.name);
      }

      // Add matching services
      for (final service in caregiver.services) {
        final serviceName = service.replaceAll('_', ' ');
        if (serviceName.toLowerCase().contains(queryLower)) {
          suggestions.add(serviceName);
        }
      }

      // Add matching locations
      if (caregiver.location?.toLowerCase().contains(queryLower) ?? false) {
        suggestions.add(caregiver.location!);
      }
    }

    return suggestions.take(5).toList();
  }

  Future<List<Caregiver>> getFeaturedCaregivers({int limit = 10}) async {
    initializeMockData();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Get top-rated available caregivers
    final featured = _mockCaregivers
        .where((caregiver) => caregiver.isAvailable && caregiver.rating >= 4.0)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return featured.take(limit).toList();
  }

  Future<List<Caregiver>> getNearbyCaregivers({
    required double latitude,
    required double longitude,
    double maxDistance = 50, // kilometers
    int limit = 20,
  }) async {
    initializeMockData();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    final nearby = <Caregiver>[];
    
    for (final caregiver in _mockCaregivers) {
      final distance = caregiver.distanceFrom(latitude, longitude);
      if (distance != null && distance <= maxDistance) {
        nearby.add(caregiver);
      }
    }

    // Sort by distance
    nearby.sort((a, b) {
      final distanceA = a.distanceFrom(latitude, longitude) ?? double.maxFinite;
      final distanceB = b.distanceFrom(latitude, longitude) ?? double.maxFinite;
      return distanceA.compareTo(distanceB);
    });

    return nearby.take(limit).toList();
  }
}