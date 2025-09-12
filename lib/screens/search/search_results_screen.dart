import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/search_filter.dart';
import '../../models/caregiver.dart';
import '../../providers/search_provider.dart';
import '../../widgets/caregiver_card.dart';
import '../../widgets/search_filter_chips.dart';
import 'filter_screen.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more results when reaching the bottom
      ref.read(searchResultsProvider.notifier).search(loadMore: true);
    }
  }

  void _openFilters() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FilterScreen(),
      ),
    );
  }

  void _navigateToCaregiverProfile(String caregiverId) {
    Navigator.of(context).pushNamed(
      '/caregiver-profile',
      arguments: caregiverId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResult = ref.watch(searchResultsProvider);
    final searchFilter = ref.watch(searchFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilters,
            tooltip: 'Filters',
          ),
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (sortBy) {
              ref.read(searchFilterProvider.notifier).updateSorting(sortBy: sortBy);
              ref.read(searchResultsProvider.notifier).search();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortBy.relevance,
                child: Row(
                  children: [
                    Icon(
                      searchFilter.sortBy == SortBy.relevance
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    const SizedBox(width: 8),
                    const Text('Relevance'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.rating,
                child: Row(
                  children: [
                    Icon(
                      searchFilter.sortBy == SortBy.rating
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    const SizedBox(width: 8),
                    const Text('Rating'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.price,
                child: Row(
                  children: [
                    Icon(
                      searchFilter.sortBy == SortBy.price
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    const SizedBox(width: 8),
                    const Text('Price'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.distance,
                child: Row(
                  children: [
                    Icon(
                      searchFilter.sortBy == SortBy.distance
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    const SizedBox(width: 8),
                    const Text('Distance'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortBy.experience,
                child: Row(
                  children: [
                    Icon(
                      searchFilter.sortBy == SortBy.experience
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    const SizedBox(width: 8),
                    const Text('Experience'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search filter chips
          if (searchFilter.hasActiveFilters)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: SearchFilterChips(
                filter: searchFilter,
                onFilterChanged: (newFilter) {
                  ref.read(searchFilterProvider.notifier).state = newFilter;
                  ref.read(searchResultsProvider.notifier).search();
                },
              ),
            ),

          // Results count and sort info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  searchResult.isEmpty && !searchResult.isLoading
                      ? 'No results found'
                      : searchResult.isLoading && searchResult.caregivers.isEmpty
                          ? 'Searching...'
                          : '${searchResult.totalCount} caregiver${searchResult.totalCount == 1 ? '' : 's'} found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                  ),
                ),
                const Spacer(),
                if (searchResult.isNotEmpty)
                  Text(
                    'Sorted by ${searchFilter.sortByLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
                    ),
                  ),
              ],
            ),
          ),

          // Results list
          Expanded(
            child: _buildResultsList(searchResult, searchFilter),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(dynamic searchResult, SearchFilter searchFilter) {
    if (searchResult.isLoading && searchResult.caregivers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (searchResult.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              searchResult.error ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(searchResultsProvider.notifier).search();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (searchResult.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.3).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'No caregivers found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(searchFilterProvider.notifier).clearAllFilters();
                ref.read(searchResultsProvider.notifier).search();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: searchResult.caregivers.length + (searchResult.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == searchResult.caregivers.length) {
          // Loading indicator for pagination
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final caregiver = searchResult.caregivers[index];
        double? distance;

        // Calculate distance if user location is available
        if (searchFilter.userLatitude != null && searchFilter.userLongitude != null) {
          distance = (caregiver as Caregiver).distanceFrom(
            searchFilter.userLatitude!,
            searchFilter.userLongitude!,
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CaregiverCard(
            caregiver: caregiver,
            showDistance: distance != null,
            distance: distance,
            onTap: () => _navigateToCaregiverProfile(caregiver.id),
          ),
        );
      },
    );
  }
}