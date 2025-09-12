import 'dart:math';

class Caregiver {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? bio;
  final String? location;
  final String? phoneNumber;
  final String? profileImageUrl;
  final List<String> services;
  final double? hourlyRate;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final List<String> certifications;
  final int experienceYears;
  final List<String> languages;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> availability; // Days of the week
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Caregiver({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.bio,
    this.location,
    this.phoneNumber,
    this.profileImageUrl,
    this.services = const [],
    this.hourlyRate,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isAvailable = true,
    this.certifications = const [],
    this.experienceYears = 0,
    this.languages = const [],
    this.address,
    this.latitude,
    this.longitude,
    this.availability = const [],
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'bio': bio,
      'location': location,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'services': services,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'certifications': certifications,
      'experienceYears': experienceYears,
      'languages': languages,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'availability': availability,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Caregiver.fromJson(Map<String, dynamic> json) {
    return Caregiver(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      location: json['location'],
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      services: List<String>.from(json['services'] ?? []),
      hourlyRate: json['hourlyRate']?.toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      certifications: List<String>.from(json['certifications'] ?? []),
      experienceYears: json['experienceYears'] ?? 0,
      languages: List<String>.from(json['languages'] ?? ['English']),
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      availability: List<String>.from(json['availability'] ?? []),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Caregiver copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? bio,
    String? location,
    String? phoneNumber,
    String? profileImageUrl,
    List<String>? services,
    double? hourlyRate,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    List<String>? certifications,
    int? experienceYears,
    List<String>? languages,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? availability,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Caregiver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      services: services ?? this.services,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      certifications: certifications ?? this.certifications,
      experienceYears: experienceYears ?? this.experienceYears,
      languages: languages ?? this.languages,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      availability: availability ?? this.availability,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate distance from given coordinates (in kilometers)
  double? distanceFrom(double? fromLatitude, double? fromLongitude) {
    if (latitude == null || longitude == null || fromLatitude == null || fromLongitude == null) {
      return null;
    }
    
    // Haversine formula for calculating distance between two points
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double lat1Rad = fromLatitude * (3.14159265359 / 180);
    final double lat2Rad = latitude! * (3.14159265359 / 180);
    final double deltaLatRad = (latitude! - fromLatitude) * (3.14159265359 / 180);
    final double deltaLngRad = (longitude! - fromLongitude) * (3.14159265359 / 180);
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  // Check if caregiver matches search criteria
  bool matchesSearchQuery(String query) {
    if (query.isEmpty) return true;
    
    final searchQuery = query.toLowerCase();
    return name.toLowerCase().contains(searchQuery) ||
        (bio?.toLowerCase().contains(searchQuery) ?? false) ||
        (location?.toLowerCase().contains(searchQuery) ?? false) ||
        services.any((service) => service.toLowerCase().contains(searchQuery)) ||
        certifications.any((cert) => cert.toLowerCase().contains(searchQuery)) ||
        languages.any((lang) => lang.toLowerCase().contains(searchQuery));
  }
}