import 'caregiver.dart';
import 'search_filter.dart';

class SearchResult {
  final List<Caregiver> caregivers;
  final int totalCount;
  final SearchFilter appliedFilter;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final int totalPages;

  SearchResult({
    this.caregivers = const [],
    this.totalCount = 0,
    required this.appliedFilter,
    this.isLoading = false,
    this.error,
    this.hasMore = false,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  SearchResult copyWith({
    List<Caregiver>? caregivers,
    int? totalCount,
    SearchFilter? appliedFilter,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    int? totalPages,
  }) {
    return SearchResult(
      caregivers: caregivers ?? this.caregivers,
      totalCount: totalCount ?? this.totalCount,
      appliedFilter: appliedFilter ?? this.appliedFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  SearchResult loading() {
    return copyWith(isLoading: true, error: null);
  }

  SearchResult withError(String errorMessage) {
    return copyWith(isLoading: false, error: errorMessage);
  }

  SearchResult withData({
    required List<Caregiver> caregivers,
    required int totalCount,
    bool? hasMore,
    int? currentPage,
    int? totalPages,
  }) {
    return copyWith(
      caregivers: caregivers,
      totalCount: totalCount,
      isLoading: false,
      error: null,
      hasMore: hasMore,
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }

  SearchResult appendData({
    required List<Caregiver> newCaregivers,
    required int newTotalCount,
    bool? hasMore,
    int? currentPage,
    int? totalPages,
  }) {
    return copyWith(
      caregivers: [...caregivers, ...newCaregivers],
      totalCount: newTotalCount,
      isLoading: false,
      error: null,
      hasMore: hasMore,
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }

  bool get isEmpty => caregivers.isEmpty && !isLoading;
  bool get isNotEmpty => caregivers.isNotEmpty;
  bool get hasError => error != null;
  bool get isSuccess => !isLoading && !hasError;

  Map<String, dynamic> toJson() {
    return {
      'caregivers': caregivers.map((c) => c.toJson()).toList(),
      'totalCount': totalCount,
      'appliedFilter': appliedFilter.toJson(),
      'isLoading': isLoading,
      'error': error,
      'hasMore': hasMore,
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      caregivers: (json['caregivers'] as List<dynamic>?)
          ?.map((c) => Caregiver.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      totalCount: json['totalCount'] ?? 0,
      appliedFilter: SearchFilter.fromJson(json['appliedFilter'] ?? {}),
      isLoading: json['isLoading'] ?? false,
      error: json['error'],
      hasMore: json['hasMore'] ?? false,
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class SearchHistory {
  final String id;
  final String query;
  final SearchFilter filter;
  final DateTime searchedAt;
  final int resultsCount;

  SearchHistory({
    required this.id,
    required this.query,
    required this.filter,
    required this.searchedAt,
    required this.resultsCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'filter': filter.toJson(),
      'searchedAt': searchedAt.toIso8601String(),
      'resultsCount': resultsCount,
    };
  }

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'] ?? '',
      query: json['query'] ?? '',
      filter: SearchFilter.fromJson(json['filter'] ?? {}),
      searchedAt: DateTime.parse(json['searchedAt'] ?? DateTime.now().toIso8601String()),
      resultsCount: json['resultsCount'] ?? 0,
    );
  }
}

class FavoriteCaregiver {
  final String id;
  final String caregiverId;
  final String userId;
  final DateTime favoritedAt;
  final Caregiver? caregiver; // Populated when needed

  FavoriteCaregiver({
    required this.id,
    required this.caregiverId,
    required this.userId,
    required this.favoritedAt,
    this.caregiver,
  });

  FavoriteCaregiver copyWith({
    String? id,
    String? caregiverId,
    String? userId,
    DateTime? favoritedAt,
    Caregiver? caregiver,
  }) {
    return FavoriteCaregiver(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      userId: userId ?? this.userId,
      favoritedAt: favoritedAt ?? this.favoritedAt,
      caregiver: caregiver ?? this.caregiver,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caregiverId': caregiverId,
      'userId': userId,
      'favoritedAt': favoritedAt.toIso8601String(),
    };
  }

  factory FavoriteCaregiver.fromJson(Map<String, dynamic> json) {
    return FavoriteCaregiver(
      id: json['\$id'] ?? json['id'] ?? '',
      caregiverId: json['caregiverId'] ?? '',
      userId: json['userId'] ?? '',
      favoritedAt: DateTime.parse(json['favoritedAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String()),
      caregiver: json['caregiver'] != null ? Caregiver.fromJson(json['caregiver']) : null,
    );
  }
}