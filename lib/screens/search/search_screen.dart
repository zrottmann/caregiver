import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../models/search_filter.dart';
import '../../models/service_category.dart';
import '../../providers/search_provider.dart';
import '../../widgets/caregiver_card.dart';
import '../../widgets/search_filter_chips.dart';
import 'search_results_screen.dart';
import 'filter_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    // Load featured caregivers on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(featuredCaregiversProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(currentSearchQueryProvider.notifier).state = query;
      ref.read(searchFilterProvider.notifier).updateQuery(query);
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addSearch(query);
    }
    
    ref.read(searchResultsProvider.notifier).search();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SearchResultsScreen(),
      ),
    );
  }

  void _openFilters() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FilterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchFilter = ref.watch(searchFilterProvider);
    final featuredCaregivers = ref.watch(featuredCaregiversProvider);
    final searchHistory = ref.watch(searchHistoryProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Find Caregivers'),
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSearchBar(),
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active filters
              if (searchFilter.hasActiveFilters) ...[
                SearchFilterChips(
                  filter: searchFilter,
                  onFilterChanged: (newFilter) {
                    ref.read(searchFilterProvider.notifier).state = newFilter;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Quick service categories
              _buildServiceCategories(),
              const SizedBox(height: 24),

              // Search history
              if (searchHistory.isNotEmpty) ...[
                _buildSearchHistory(searchHistory),
                const SizedBox(height: 24),
              ],

              // Featured caregivers
              _buildFeaturedSection(featuredCaregivers),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search caregivers, services, or locations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(currentSearchQueryProvider.notifier).state = '';
                        ref.read(searchFilterProvider.notifier).updateQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withAlpha((255 * 0.3).round()),
            ),
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: (_) => _performSearch(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.tune),
          onPressed: _openFilters,
          tooltip: 'Filters',
        ),
      ],
    );
  }

  Widget _buildServiceCategories() {
    final categories = ServiceCategory.getAllCategories();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse by Service',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildServiceCategoryCard(category);
          },
        ),
      ],
    );
  }

  Widget _buildServiceCategoryCard(ServiceCategory category) {
    return Card(
      elevation: 0,
      color: category.color.withAlpha((255 * 0.1).round()),
      child: InkWell(
        onTap: () {
          ref.read(searchFilterProvider.notifier).updateServiceCategories([category.id]);
          ref.read(searchResultsProvider.notifier).search();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SearchResultsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: category.color.withAlpha((255 * 0.8).round()),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHistory(List<String> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(searchHistoryProvider.notifier).clearHistory();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: history.map((query) => _buildHistoryChip(query)).toList(),
        ),
      ],
    );
  }

  Widget _buildHistoryChip(String query) {
    return ActionChip(
      label: Text(query),
      avatar: const Icon(Icons.history, size: 16),
      onPressed: () {
        _searchController.text = query;
        ref.read(searchFilterProvider.notifier).updateQuery(query);
        _performSearch();
      },
      onDeleted: () {
        ref.read(searchHistoryProvider.notifier).removeSearch(query);
      },
    );
  }

  Widget _buildFeaturedSection(AsyncValue<List<dynamic>> featuredCaregivers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Caregivers',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        featuredCaregivers.when(
          data: (caregivers) {
            if (caregivers.isEmpty) {
              return const Center(
                child: Text('No featured caregivers available'),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: caregivers.length.clamp(0, 3), // Show only top 3
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return CaregiverCard(caregiver: caregivers[index]);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 8),
                Text('Error loading featured caregivers'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.invalidate(featuredCaregiversProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}