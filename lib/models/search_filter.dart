enum SortBy {
  relevance,
  rating,
  price,
  distance,
  experience,
}

enum PriceRange {
  any,
  under25,
  range25to50,
  range50to75,
  over75,
}

class SearchFilter {
  final String query;
  final List<String> serviceCategories;
  final List<String> specificServices;
  final PriceRange priceRange;
  final double? maxPrice;
  final double? minPrice;
  final double? minRating;
  final int? maxDistance; // in kilometers
  final bool availableNow;
  final List<String> languages;
  final List<String> certifications;
  final int? minExperience;
  final SortBy sortBy;
  final bool sortDescending;
  final String? location;
  final double? userLatitude;
  final double? userLongitude;
  final List<String> availability; // Days of the week

  SearchFilter({
    this.query = '',
    this.serviceCategories = const [],
    this.specificServices = const [],
    this.priceRange = PriceRange.any,
    this.maxPrice,
    this.minPrice,
    this.minRating,
    this.maxDistance,
    this.availableNow = false,
    this.languages = const [],
    this.certifications = const [],
    this.minExperience,
    this.sortBy = SortBy.relevance,
    this.sortDescending = false,
    this.location,
    this.userLatitude,
    this.userLongitude,
    this.availability = const [],
  });

  SearchFilter copyWith({
    String? query,
    List<String>? serviceCategories,
    List<String>? specificServices,
    PriceRange? priceRange,
    double? maxPrice,
    double? minPrice,
    double? minRating,
    int? maxDistance,
    bool? availableNow,
    List<String>? languages,
    List<String>? certifications,
    int? minExperience,
    SortBy? sortBy,
    bool? sortDescending,
    String? location,
    double? userLatitude,
    double? userLongitude,
    List<String>? availability,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      specificServices: specificServices ?? this.specificServices,
      priceRange: priceRange ?? this.priceRange,
      maxPrice: maxPrice ?? this.maxPrice,
      minPrice: minPrice ?? this.minPrice,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      availableNow: availableNow ?? this.availableNow,
      languages: languages ?? this.languages,
      certifications: certifications ?? this.certifications,
      minExperience: minExperience ?? this.minExperience,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      location: location ?? this.location,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      availability: availability ?? this.availability,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'serviceCategories': serviceCategories,
      'specificServices': specificServices,
      'priceRange': priceRange.index,
      'maxPrice': maxPrice,
      'minPrice': minPrice,
      'minRating': minRating,
      'maxDistance': maxDistance,
      'availableNow': availableNow,
      'languages': languages,
      'certifications': certifications,
      'minExperience': minExperience,
      'sortBy': sortBy.index,
      'sortDescending': sortDescending,
      'location': location,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'availability': availability,
    };
  }

  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter(
      query: json['query'] ?? '',
      serviceCategories: List<String>.from(json['serviceCategories'] ?? []),
      specificServices: List<String>.from(json['specificServices'] ?? []),
      priceRange: PriceRange.values[json['priceRange'] ?? 0],
      maxPrice: json['maxPrice']?.toDouble(),
      minPrice: json['minPrice']?.toDouble(),
      minRating: json['minRating']?.toDouble(),
      maxDistance: json['maxDistance'],
      availableNow: json['availableNow'] ?? false,
      languages: List<String>.from(json['languages'] ?? []),
      certifications: List<String>.from(json['certifications'] ?? []),
      minExperience: json['minExperience'],
      sortBy: SortBy.values[json['sortBy'] ?? 0],
      sortDescending: json['sortDescending'] ?? false,
      location: json['location'],
      userLatitude: json['userLatitude']?.toDouble(),
      userLongitude: json['userLongitude']?.toDouble(),
      availability: List<String>.from(json['availability'] ?? []),
    );
  }

  bool get hasActiveFilters {
    return query.isNotEmpty ||
        serviceCategories.isNotEmpty ||
        specificServices.isNotEmpty ||
        priceRange != PriceRange.any ||
        maxPrice != null ||
        minPrice != null ||
        minRating != null ||
        maxDistance != null ||
        availableNow ||
        languages.isNotEmpty ||
        certifications.isNotEmpty ||
        minExperience != null ||
        location != null ||
        availability.isNotEmpty;
  }

  SearchFilter clearAllFilters() {
    return SearchFilter(
      sortBy: sortBy,
      sortDescending: sortDescending,
    );
  }

  // Helper methods for price range
  double? get priceRangeMin {
    switch (priceRange) {
      case PriceRange.any:
        return null;
      case PriceRange.under25:
        return null;
      case PriceRange.range25to50:
        return 25.0;
      case PriceRange.range50to75:
        return 50.0;
      case PriceRange.over75:
        return 75.0;
    }
  }

  double? get priceRangeMax {
    switch (priceRange) {
      case PriceRange.any:
        return null;
      case PriceRange.under25:
        return 25.0;
      case PriceRange.range25to50:
        return 50.0;
      case PriceRange.range50to75:
        return 75.0;
      case PriceRange.over75:
        return null;
    }
  }

  String get priceRangeLabel {
    switch (priceRange) {
      case PriceRange.any:
        return 'Any Price';
      case PriceRange.under25:
        return 'Under \$25/hr';
      case PriceRange.range25to50:
        return '\$25-50/hr';
      case PriceRange.range50to75:
        return '\$50-75/hr';
      case PriceRange.over75:
        return 'Over \$75/hr';
    }
  }

  String get sortByLabel {
    switch (sortBy) {
      case SortBy.relevance:
        return 'Relevance';
      case SortBy.rating:
        return 'Rating';
      case SortBy.price:
        return 'Price';
      case SortBy.distance:
        return 'Distance';
      case SortBy.experience:
        return 'Experience';
    }
  }
}