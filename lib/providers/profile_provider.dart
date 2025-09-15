import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final userProfileProvider = FutureProvider.autoDispose.family<UserProfile, String>((ref, userId) async {
  final service = ref.read(profileServiceProvider);
  return service.getUserProfile(userId);
});


final caregiversProvider = FutureProvider.autoDispose.family<List<UserProfile>, CaregiverFilters?>((ref, filters) async {
  final service = ref.read(profileServiceProvider);
  return service.getCaregivers(
    specializations: filters?.specializations,
    minRating: filters?.minRating,
    maxHourlyRate: filters?.maxHourlyRate,
    isAvailable: filters?.isAvailable,
  );
});

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  final ProfileService _service;
  final Ref _ref;

  Future<UserProfile> createProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      final createdProfile = await _service.createUserProfile(profile);

      _ref.invalidate(userProfileProvider(profile.uid));

      state = const AsyncValue.data(null);
      return createdProfile;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<UserProfile> updateProfile(String userId, UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      final updatedProfile = await _service.updateUserProfile(userId, profile);

      _ref.invalidate(userProfileProvider(userId));
      _ref.invalidate(caregiversProvider);

      state = const AsyncValue.data(null);
      return updatedProfile;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteUserProfile(userId);

      _ref.invalidate(userProfileProvider(userId));
      _ref.invalidate(caregiversProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  final service = ref.read(profileServiceProvider);
  return ProfileNotifier(service, ref);
});

class CaregiverFilters {
  final List<String>? specializations;
  final double? minRating;
  final double? maxHourlyRate;
  final bool? isAvailable;

  const CaregiverFilters({
    this.specializations,
    this.minRating,
    this.maxHourlyRate,
    this.isAvailable,
  });
}