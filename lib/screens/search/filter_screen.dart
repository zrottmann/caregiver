import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/search_filter.dart';
import '../../models/service_category.dart';
import '../../providers/search_provider.dart';

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  late SearchFilter _currentFilter;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilter = ref.read(searchFilterProvider);
    _locationController.text = _currentFilter.location ?? '';
    _minPriceController.text = _currentFilter.minPrice?.toStringAsFixed(0) ?? '';
    _maxPriceController.text = _currentFilter.maxPrice?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(searchFilterProvider.notifier).state = _currentFilter;
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = SearchFilter();
      _locationController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear All'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Categories
            _buildSection(
              title: 'Service Categories',
              child: _buildServiceCategoriesFilter(),
            ),

            // Price Range
            _buildSection(
              title: 'Price Range',
              child: _buildPriceRangeFilter(),
            ),

            // Custom Price Range
            _buildSection(
              title: 'Custom Price Range',
              child: _buildCustomPriceFilter(),
            ),

            // Rating
            _buildSection(
              title: 'Minimum Rating',
              child: _buildRatingFilter(),
            ),

            // Distance
            _buildSection(
              title: 'Maximum Distance',
              child: _buildDistanceFilter(),
            ),

            // Location
            _buildSection(
              title: 'Location',
              child: _buildLocationFilter(),
            ),

            // Availability
            _buildSection(
              title: 'Availability',
              child: _buildAvailabilityFilter(),
            ),

            // Languages
            _buildSection(
              title: 'Languages',
              child: _buildLanguagesFilter(),
            ),

            // Certifications
            _buildSection(
              title: 'Certifications',
              child: _buildCertificationsFilter(),
            ),

            // Experience
            _buildSection(
              title: 'Minimum Experience',
              child: _buildExperienceFilter(),
            ),

            // Available Days
            _buildSection(
              title: 'Available Days',
              child: _buildAvailableDaysFilter(),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Apply Filters'),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildServiceCategoriesFilter() {
    final categories = ServiceCategory.getAllCategories();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _currentFilter.serviceCategories.contains(category.id);
        return FilterChip(
          label: Text(category.name),
          avatar: Icon(category.icon, size: 16),
          selected: isSelected,
          selectedColor: category.color.withAlpha((255 * 0.3).round()),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _currentFilter = _currentFilter.copyWith(
                  serviceCategories: [..._currentFilter.serviceCategories, category.id],
                );
              } else {
                _currentFilter = _currentFilter.copyWith(
                  serviceCategories: _currentFilter.serviceCategories
                      .where((id) => id != category.id)
                      .toList(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      children: PriceRange.values.map((priceRange) {
        return RadioListTile<PriceRange>(
          title: Text(_getPriceRangeLabel(priceRange)),
          value: priceRange,
          groupValue: _currentFilter.priceRange,
          onChanged: (value) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(
                priceRange: value,
                minPrice: null,
                maxPrice: null,
              );
              _minPriceController.clear();
              _maxPriceController.clear();
            });
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildCustomPriceFilter() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _minPriceController,
            decoration: const InputDecoration(
              labelText: 'Min Price (\$)',
              border: OutlineInputBorder(),
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final price = double.tryParse(value);
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  minPrice: price,
                  priceRange: PriceRange.any,
                );
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _maxPriceController,
            decoration: const InputDecoration(
              labelText: 'Max Price (\$)',
              border: OutlineInputBorder(),
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final price = double.tryParse(value);
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  maxPrice: price,
                  priceRange: PriceRange.any,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      children: [1.0, 2.0, 3.0, 4.0, 4.5].map((rating) {
        return RadioListTile<double?>(
          title: Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < rating.floor()
                      ? Icons.star
                      : (index < rating ? Icons.star_half : Icons.star_border),
                  color: Colors.amber,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text('$rating & up'),
            ],
          ),
          value: rating,
          groupValue: _currentFilter.minRating,
          onChanged: (value) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(minRating: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList()
        ..insert(0, RadioListTile<double?>(
          title: const Text('Any Rating'),
          value: null,
          groupValue: _currentFilter.minRating,
          onChanged: (value) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(minRating: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        )),
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      children: [5, 10, 25, 50, 100].map((distance) {
        return RadioListTile<int?>(
          title: Text('Within $distance km'),
          value: distance,
          groupValue: _currentFilter.maxDistance,
          onChanged: (value) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(maxDistance: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList()
        ..insert(0, RadioListTile<int?>(
          title: const Text('Any Distance'),
          value: null,
          groupValue: _currentFilter.maxDistance,
          onChanged: (value) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(maxDistance: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        )),
    );
  }

  Widget _buildLocationFilter() {
    return TextField(
      controller: _locationController,
      decoration: const InputDecoration(
        labelText: 'Search Location',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
        hintText: 'Enter city, state, or zip code',
      ),
      onChanged: (value) {
        setState(() {
          _currentFilter = _currentFilter.copyWith(location: value.isEmpty ? null : value);
        });
      },
    );
  }

  Widget _buildAvailabilityFilter() {
    return SwitchListTile(
      title: const Text('Available Now'),
      subtitle: const Text('Show only caregivers available immediately'),
      value: _currentFilter.availableNow,
      onChanged: (value) {
        setState(() {
          _currentFilter = _currentFilter.copyWith(availableNow: value);
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLanguagesFilter() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Italian', 'Chinese', 'Japanese', 'Korean'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: languages.map((language) {
        final isSelected = _currentFilter.languages.contains(language);
        return FilterChip(
          label: Text(language),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _currentFilter = _currentFilter.copyWith(
                  languages: [..._currentFilter.languages, language],
                );
              } else {
                _currentFilter = _currentFilter.copyWith(
                  languages: _currentFilter.languages
                      .where((lang) => lang != language)
                      .toList(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCertificationsFilter() {
    final certifications = [
      'CPR Certified',
      'First Aid',
      'CNA License',
      'RN License',
      'Home Health Aide',
      'Certified Nursing Assistant',
      'Physical Therapy Assistant',
      'Mental Health First Aid',
      'Dementia Care Certified',
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: certifications.map((cert) {
        final isSelected = _currentFilter.certifications.contains(cert);
        return FilterChip(
          label: Text(cert),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _currentFilter = _currentFilter.copyWith(
                  certifications: [..._currentFilter.certifications, cert],
                );
              } else {
                _currentFilter = _currentFilter.copyWith(
                  certifications: _currentFilter.certifications
                      .where((c) => c != cert)
                      .toList(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildExperienceFilter() {
    return Column(
      children: [1, 2, 5, 10, 15].map((years) {
        return RadioListTile<int?>(
          title: Text('$years+ years'),
          value: years,
          groupValue: _currentFilter.minExperience,
          onChanged: (value) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(minExperience: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList()
        ..insert(0, RadioListTile<int?>(
          title: const Text('Any Experience'),
          value: null,
          groupValue: _currentFilter.minExperience,
          onChanged: (value) {
            setState(() {
              _currentFilter = _currentFilter.copyWith(minExperience: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        )),
    );
  }

  Widget _buildAvailableDaysFilter() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        final isSelected = _currentFilter.availability.contains(day);
        return FilterChip(
          label: Text(day),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _currentFilter = _currentFilter.copyWith(
                  availability: [..._currentFilter.availability, day],
                );
              } else {
                _currentFilter = _currentFilter.copyWith(
                  availability: _currentFilter.availability
                      .where((d) => d != day)
                      .toList(),
                );
              }
            });
          },
        );
      }).toList(),
    );
  }

  String _getPriceRangeLabel(PriceRange priceRange) {
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
}