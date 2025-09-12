import '../config/app_config.dart';

class UserProfile {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String role; // 'patient' or 'caregiver'
  final String? bio;
  final String? location;
  final String? phoneNumber;
  final String? profileImageUrl;
  final List<String> services; // For caregivers
  final double? hourlyRate; // For caregivers
  final double? rating; // For caregivers
  final int? reviewCount; // For caregivers
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.bio,
    this.location,
    this.phoneNumber,
    this.profileImageUrl,
    this.services = const [],
    this.hourlyRate,
    this.rating,
    this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCaregiver => role == AppConfig.roleCaregiver;
  bool get isPatient => role == AppConfig.rolePatient;
  
  // Convenience getters for backward compatibility and UI convenience
  String get fullName => name;
  String? get profilePictureUrl => profileImageUrl;
  List<String> get specializations => services;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'bio': bio,
      'location': location,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'services': services,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? AppConfig.rolePatient,
      bio: json['bio'],
      location: json['location'],
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      services: List<String>.from(json['services'] ?? []),
      hourlyRate: json['hourlyRate']?.toDouble(),
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? role,
    String? bio,
    String? location,
    String? phoneNumber,
    String? profileImageUrl,
    List<String>? services,
    double? hourlyRate,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      services: services ?? this.services,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}