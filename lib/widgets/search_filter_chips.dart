import 'package:flutter/material.dart';

import '../models/search_filter.dart';
import '../models/service_category.dart';

class SearchFilterChips extends StatelessWidget {
  final SearchFilter filter;
  final Function(SearchFilter) onFilterChanged;

  const SearchFilterChips({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeFilters = _buildActiveFilterChips(context);

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Active Filters',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                onFilterChanged(filter.clearAllFilters());
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: activeFilters,
        ),
      ],
    );
  }

  List<Widget> _buildActiveFilterChips(BuildContext context) {
    final chips = <Widget>[];

    // Query chip
    if (filter.query.isNotEmpty) {
      chips.add(_buildFilterChip(
        context: context,
        label: '"${filter.query}"',
        icon: Icons.search,
        onDeleted: () {
          onFilterChanged(filter.copyWith(query: ''));
        },
      ));
    }

    // Service category chips
    for (final categoryId in filter.serviceCategories) {
      final category = ServiceCategory.getCategoryById(categoryId);
      if (category != null) {
        chips.add(_buildFilterChip(
          context: context,
          label: category.name,
          icon: category.icon,
          color: category.color,
          onDeleted: () {
            final updatedCategories = filter.serviceCategories
                .where((id) => id != categoryId)
                .toList();
            onFilterChanged(filter.copyWith(serviceCategories: updatedCategories));
          },
        ));
      }
    }

    // Price range chip
    if (filter.priceRange != PriceRange.any) {
      chips.add(_buildFilterChip(
        context: context,
        label: filter.priceRangeLabel,
        icon: Icons.attach_money,
        onDeleted: () {
          onFilterChanged(filter.copyWith(priceRange: PriceRange.any));
        },
      ));
    }

    // Custom price range chip
    if (filter.minPrice != null || filter.maxPrice != null) {
      String priceLabel = '';
      if (filter.minPrice != null && filter.maxPrice != null) {
        priceLabel = '\$${filter.minPrice!.toStringAsFixed(0)}-\$${filter.maxPrice!.toStringAsFixed(0)}';
      } else if (filter.minPrice != null) {
        priceLabel = 'From \$${filter.minPrice!.toStringAsFixed(0)}';
      } else if (filter.maxPrice != null) {
        priceLabel = 'Up to \$${filter.maxPrice!.toStringAsFixed(0)}';
      }

      chips.add(_buildFilterChip(
        context: context,
        label: priceLabel,
        icon: Icons.attach_money,
        onDeleted: () {
          onFilterChanged(filter.copyWith(minPrice: null, maxPrice: null));
        },
      ));
    }

    // Rating chip
    if (filter.minRating != null) {
      chips.add(_buildFilterChip(
        context: context,
        label: '${filter.minRating!.toStringAsFixed(1)}+ stars',
        icon: Icons.star,
        color: Colors.amber,
        onDeleted: () {
          onFilterChanged(filter.copyWith(minRating: null));
        },
      ));
    }

    // Distance chip
    if (filter.maxDistance != null) {
      chips.add(_buildFilterChip(
        context: context,
        label: 'Within ${filter.maxDistance} km',
        icon: Icons.location_on,
        color: Colors.green,
        onDeleted: () {
          onFilterChanged(filter.copyWith(maxDistance: null));
        },
      ));
    }

    // Available now chip
    if (filter.availableNow) {
      chips.add(_buildFilterChip(
        context: context,
        label: 'Available Now',
        icon: Icons.schedule,
        color: Colors.green,
        onDeleted: () {
          onFilterChanged(filter.copyWith(availableNow: false));
        },
      ));
    }

    // Language chips
    for (final language in filter.languages) {
      chips.add(_buildFilterChip(
        context: context,
        label: language,
        icon: Icons.language,
        color: Colors.blue,
        onDeleted: () {
          final updatedLanguages = filter.languages
              .where((lang) => lang != language)
              .toList();
          onFilterChanged(filter.copyWith(languages: updatedLanguages));
        },
      ));
    }

    // Certification chips
    for (final certification in filter.certifications) {
      chips.add(_buildFilterChip(
        context: context,
        label: certification,
        icon: Icons.verified,
        color: Colors.indigo,
        onDeleted: () {
          final updatedCertifications = filter.certifications
              .where((cert) => cert != certification)
              .toList();
          onFilterChanged(filter.copyWith(certifications: updatedCertifications));
        },
      ));
    }

    // Experience chip
    if (filter.minExperience != null) {
      chips.add(_buildFilterChip(
        context: context,
        label: '${filter.minExperience}+ years experience',
        icon: Icons.work,
        color: Colors.orange,
        onDeleted: () {
          onFilterChanged(filter.copyWith(minExperience: null));
        },
      ));
    }

    // Location chip
    if (filter.location != null && filter.location!.isNotEmpty) {
      chips.add(_buildFilterChip(
        context: context,
        label: filter.location!,
        icon: Icons.place,
        color: Colors.red,
        onDeleted: () {
          onFilterChanged(filter.copyWith(location: null));
        },
      ));
    }

    // Availability days chips
    for (final day in filter.availability) {
      chips.add(_buildFilterChip(
        context: context,
        label: day,
        icon: Icons.calendar_today,
        color: Colors.purple,
        onDeleted: () {
          final updatedAvailability = filter.availability
              .where((d) => d != day)
              .toList();
          onFilterChanged(filter.copyWith(availability: updatedAvailability));
        },
      ));
    }

    return chips;
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onDeleted,
  }) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: chipColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor.withAlpha((255 * 0.1).round()),
      deleteIcon: Icon(
        Icons.close,
        size: 16,
        color: chipColor,
      ),
      onDeleted: onDeleted,
      side: BorderSide(
        color: chipColor.withAlpha((255 * 0.3).round()),
        width: 1,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}