import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/caregiver.dart';
import '../models/search_filter.dart';
import '../models/search_result.dart';
import '../services/search_service.dart';

// Search service provider
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

// Current search filter provider
final searchFilterProvider = StateNotifierProvider<SearchFilterNotifier, SearchFilter>((ref) {
  return SearchFilterNotifier();
});

class SearchFilterNotifier extends StateNotifier<SearchFilter> {
  SearchFilterNotifier() : super(SearchFilter());

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  void updateServiceCategories(List<String> categories) {
    state = state.copyWith(serviceCategories: categories);
  }

  void addServiceCategory(String category) {
    if (!state.serviceCategories.contains(category)) {
      state = state.copyWith(
        serviceCategories: [...state.serviceCategories, category],
      );
    }
  }

  void removeServiceCategory(String category) {
    state = state.copyWith(
      serviceCategories: state.serviceCategories.where((c) => c != category).toList(),
    );
  }

  void updatePriceRange(PriceRange priceRange) {
    state = state.copyWith(priceRange: priceRange);
  }

  void updateCustomPriceRange({double? minPrice, double? maxPrice}) {
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      priceRange: PriceRange.any,
    );
  }

  void updateRating(double? minRating) {
    state = state.copyWith(minRating: minRating);
  }

  void updateDistance(int? maxDistance) {
    state = state.copyWith(maxDistance: maxDistance);
  }

  void updateAvailableNow(bool availableNow) {
    state = state.copyWith(availableNow: availableNow);
  }

  void updateLanguages(List<String> languages) {
    state = state.copyWith(languages: languages);
  }

  void updateCertifications(List<String> certifications) {
    state = state.copyWith(certifications: certifications);
  }

  void updateExperience(int? minExperience) {
    state = state.copyWith(minExperience: minExperience);
  }

  void updateSorting({SortBy? sortBy, bool? sortDescending}) {
    state = state.copyWith(
      sortBy: sortBy ?? state.sortBy,
      sortDescending: sortDescending ?? state.sortDescending,
    );
  }

  void updateLocation({String? location, double? latitude, double? longitude}) {
    state = state.copyWith(
      location: location,
      userLatitude: latitude,
      userLongitude: longitude,
    );
  }

  void updateAvailability(List<String> availability) {
    state = state.copyWith(availability: availability);
  }

  void clearAllFilters() {
    state = state.clearAllFilters();
  }

  void resetToDefault() {
    state = SearchFilter();
  }
}

// Search results provider
final searchResultsProvider = StateNotifierProvider<SearchResultsNotifier, SearchResult>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchResultsNotifier(searchService, ref);
});

class SearchResultsNotifier extends StateNotifier<SearchResult> {
  final SearchService _searchService;
  final Ref _ref;
  
  SearchResultsNotifier(this._searchService, this._ref) 
    : super(SearchResult(appliedFilter: SearchFilter()));

  Future<void> search({SearchFilter? filter, bool loadMore = false}) async {
    final searchFilter = filter ?? _ref.read(searchFilterProvider);
    
    if (loadMore) {
      if (!state.hasMore || state.isLoading) return;
      
      state = state.loading();
      
      try {
        final result = await _searchService.searchCaregivers(
          filter: searchFilter,
          page: state.currentPage + 1,
        );
        
        state = state.appendData(
          newCaregivers: result.caregivers,
          newTotalCount: result.totalCount,
          hasMore: result.hasMore,
          currentPage: result.currentPage,
          totalPages: result.totalPages,
        );
      } catch (error) {
        state = state.withError(error.toString());
      }
    } else {
      state = state.loading();
      
      try {
        final result = await _searchService.searchCaregivers(
          filter: searchFilter,
          page: 1,
        );
        
        state = result;
      } catch (error) {
        state = state.withError(error.toString());
      }
    }
  }

  void clearResults() {
    state = SearchResult(appliedFilter: _ref.read(searchFilterProvider));
  }
}

// Featured caregivers provider
final featuredCaregiversProvider = FutureProvider<List<Caregiver>>((ref) async {
  final searchService = ref.watch(searchServiceProvider);
  return searchService.getFeaturedCaregivers();
});

// Nearby caregivers provider
final nearbyCaregiversProvider = FutureProvider.family<List<Caregiver>, Map<String, double>>(
  (ref, coordinates) async {
    final searchService = ref.watch(searchServiceProvider);
    return searchService.getNearbyCaregivers(
      latitude: coordinates['latitude']!,
      longitude: coordinates['longitude']!,
    );
  },
);

// Search suggestions provider
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final searchService = ref.watch(searchServiceProvider);
  return searchService.getSearchSuggestions(query);
});

// Search history provider
final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]);
  
  static const int maxHistoryItems = 10;

  void addSearch(String query) {
    if (query.trim().isEmpty) return;
    
    final updatedHistory = state.where((item) => item != query).toList();
    updatedHistory.insert(0, query);
    
    state = updatedHistory.take(maxHistoryItems).toList();
  }

  void removeSearch(String query) {
    state = state.where((item) => item != query).toList();
  }

  void clearHistory() {
    state = [];
  }
}

// Favorite caregivers provider
final favoriteCaregiversProvider = StateNotifierProvider<FavoriteCaregiversNotifier, List<String>>((ref) {
  return FavoriteCaregiversNotifier();
});

class FavoriteCaregiversNotifier extends StateNotifier<List<String>> {
  FavoriteCaregiversNotifier() : super([]);

  void addFavorite(String caregiverId) {
    if (!state.contains(caregiverId)) {
      state = [...state, caregiverId];
    }
  }

  void removeFavorite(String caregiverId) {
    state = state.where((id) => id != caregiverId).toList();
  }

  void toggleFavorite(String caregiverId) {
    if (state.contains(caregiverId)) {
      removeFavorite(caregiverId);
    } else {
      addFavorite(caregiverId);
    }
  }

  bool isFavorite(String caregiverId) {
    return state.contains(caregiverId);
  }
}

// Quick filters provider for commonly used filter combinations
final quickFiltersProvider = Provider<List<SearchFilter>>((ref) {
  return [
    SearchFilter(
      query: '',
      serviceCategories: ['senior_care'],
      sortBy: SortBy.rating,
      sortDescending: true,
    ),
    SearchFilter(
      query: '',
      serviceCategories: ['child_care'],
      sortBy: SortBy.rating,
      sortDescending: true,
    ),
    SearchFilter(
      query: '',
      serviceCategories: ['medical_care'],
      sortBy: SortBy.experience,
      sortDescending: true,
    ),
    SearchFilter(
      query: '',
      availableNow: true,
      sortBy: SortBy.distance,
    ),
    SearchFilter(
      query: '',
      minRating: 4.5,
      sortBy: SortBy.rating,
      sortDescending: true,
    ),
  ];
});

// Provider for getting a specific caregiver by ID
final caregiverProvider = FutureProvider.family<Caregiver?, String>((ref, caregiverId) async {
  final searchService = ref.watch(searchServiceProvider);
  
  // Initialize mock data to ensure caregiver exists
  SearchService.initializeMockData();
  
  // Simulate API call delay
  await Future.delayed(const Duration(milliseconds: 300));
  
  // In a real app, this would be a separate API call to get caregiver by ID
  // For now, we'll search through the mock data
  final result = await searchService.searchCaregivers(
    filter: SearchFilter(),
    pageSize: 100, // Get all caregivers
  );
  
  final caregiver = result.caregivers.firstWhere(
    (c) => c.id == caregiverId,
    orElse: () => throw Exception('Caregiver not found'),
  );
  
  return caregiver;
});

// Current search query provider (for UI state)
final currentSearchQueryProvider = StateProvider<String>((ref) => '');

// Search loading state provider
final searchLoadingProvider = Provider<bool>((ref) {
  return ref.watch(searchResultsProvider).isLoading;
});

// Search error provider
final searchErrorProvider = Provider<String?>((ref) {
  return ref.watch(searchResultsProvider).error;
});

// Has search results provider
final hasSearchResultsProvider = Provider<bool>((ref) {
  final results = ref.watch(searchResultsProvider);
  return results.isNotEmpty;
});