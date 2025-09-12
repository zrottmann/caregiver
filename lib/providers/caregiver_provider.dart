import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class CaregiverState {
  final List<UserProfile> caregivers;
  final bool isLoading;
  final String? error;

  CaregiverState({
    this.caregivers = const [],
    this.isLoading = false,
    this.error,
  });

  CaregiverState copyWith({
    List<UserProfile>? caregivers,
    bool? isLoading,
    String? error,
  }) {
    return CaregiverState(
      caregivers: caregivers ?? this.caregivers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CaregiverNotifier extends StateNotifier<CaregiverState> {
  final ProfileService _profileService = ProfileService.instance;

  CaregiverNotifier() : super(CaregiverState());

  Future<void> loadFeaturedCaregivers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final caregivers = await _profileService.getFeaturedCaregivers();
      
      state = state.copyWith(
        caregivers: caregivers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> searchCaregivers({
    String? location,
    List<String>? services,
    double? maxHourlyRate,
    double? minRating,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final caregivers = await _profileService.searchCaregivers(
        location: location,
        services: services,
        maxHourlyRate: maxHourlyRate,
        minRating: minRating,
      );
      
      state = state.copyWith(
        caregivers: caregivers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  UserProfile? getCaregiverById(String id) {
    try {
      return state.caregivers.firstWhere((caregiver) => caregiver.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final caregiverProvider = StateNotifierProvider<CaregiverNotifier, CaregiverState>((ref) {
  return CaregiverNotifier();
});

// Alias for backward compatibility
final caregiversProvider = caregiverProvider;