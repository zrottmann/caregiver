import 'package:appwrite/models.dart' as models;

enum UserRole {
  patient,
  caregiver,
  admin
}

class UserProfile {
  final String uid;
  final String id; // Alias for uid for compatibility
  final String name;
  final String fullName; // Alias for name for compatibility
  final String email;
  final String? phone;
  final UserRole role;
  final String? bio;
  final String? profileImageUrl;
  final String? profilePictureUrl; // Alias for profileImageUrl for compatibility
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  // Caregiver-specific properties
  final List<String>? specializations;
  final double? rating;
  final double? hourlyRate;
  final bool? isAvailable;
  final String? license;
  final int? yearsExperience;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.specializations,
    this.rating,
    this.hourlyRate,
    this.isAvailable,
    this.license,
    this.yearsExperience,
  }) : id = uid,
       fullName = name,
       profilePictureUrl = profileImageUrl;

  factory UserProfile.fromDocument(models.Document document) {
    final data = document.data;
    return UserProfile(
      uid: data['userId'] ?? document.$id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: UserRole.values.firstWhere(
        (r) => r.name == (data['role'] ?? 'patient'),
        orElse: () => UserRole.patient,
      ),
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'] ?? data['profilePictureUrl'],
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      metadata: data['metadata'] is Map ? data['metadata'] : null,
      specializations: data['specializations'] != null
          ? List<String>.from(data['specializations'])
          : null,
      rating: data['rating']?.toDouble(),
      hourlyRate: data['hourlyRate']?.toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      license: data['license'],
      yearsExperience: data['yearsExperience'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'specializations': specializations,
      'rating': rating,
      'hourlyRate': hourlyRate,
      'isAvailable': isAvailable,
      'license': license,
      'yearsExperience': yearsExperience,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? bio,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<String>? specializations,
    double? rating,
    double? hourlyRate,
    bool? isAvailable,
    String? license,
    int? yearsExperience,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      specializations: specializations ?? this.specializations,
      rating: rating ?? this.rating,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isAvailable: isAvailable ?? this.isAvailable,
      license: license ?? this.license,
      yearsExperience: yearsExperience ?? this.yearsExperience,
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, name: $name, email: $email, role: ${role.name})';
  }
}