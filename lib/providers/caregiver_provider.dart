import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

// Mock caregiver provider for now
final caregiversProvider = FutureProvider<List<UserProfile>>((ref) async {
  // For now, return a mock list of caregivers
  return [
    UserProfile(
      uid: 'caregiver1',
      email: 'sarah@example.com',
      name: 'Sarah Johnson',
      role: UserRole.caregiver,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    UserProfile(
      uid: 'caregiver2',
      email: 'mike@example.com',
      name: 'Mike Wilson',
      role: UserRole.caregiver,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    UserProfile(
      uid: 'caregiver3',
      email: 'emma@example.com',
      name: 'Emma Davis',
      role: UserRole.caregiver,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
});

final caregiverProvider = FutureProvider.family<UserProfile?, String>((ref, caregiverId) async {
  final caregivers = await ref.watch(caregiversProvider.future);
  return caregivers.firstWhere(
    (caregiver) => caregiver.uid == caregiverId,
    orElse: () => UserProfile(
      uid: caregiverId,
      email: 'unknown@example.com',
      name: 'Unknown Caregiver',
      role: UserRole.caregiver,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );
});