import 'package:appwrite/models.dart' as models;

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? bio;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory UserProfile.fromDocument(models.Document document) {
    final data = document.data;
    return UserProfile(
      userId: data['userId'] ?? document.$id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? 'patient',
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      metadata: data['metadata'] is Map ? data['metadata'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? bio,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, name: $name, email: $email, role: $role)';
  }
}