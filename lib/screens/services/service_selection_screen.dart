import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/service.dart';
import '../../providers/booking_provider.dart';

class ServiceSelectionScreen extends ConsumerStatefulWidget {
  final String caregiverId;

  const ServiceSelectionScreen({
    super.key,
    required this.caregiverId,
  });

  @override
  ConsumerState<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends ConsumerState<ServiceSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedCategoryId;
  final Set<String> _selectedServiceIds = {};
  final Map<String, int> _serviceQuantities = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    ref.read(bookingProvider.notifier).loadServiceCategories();
    ref.read(bookingProvider.notifier).loadServices();
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
    });
    ref.read(bookingProvider.notifier).loadServices(categoryId: categoryId);
  }

  void _toggleServiceSelection(String serviceId) {
    setState(() {
      if (_selectedServiceIds.contains(serviceId)) {
        _selectedServiceIds.remove(serviceId);
        _serviceQuantities.remove(serviceId);
      } else {
        _selectedServiceIds.add(serviceId);
        _serviceQuantities[serviceId] = 1;
      }
    });
  }

  void _updateServiceQuantity(String serviceId, int quantity) {
    setState(() {
      if (quantity > 0) {
        _serviceQuantities[serviceId] = quantity;
        if (!_selectedServiceIds.contains(serviceId)) {
          _selectedServiceIds.add(serviceId);
        }
      } else {
        _selectedServiceIds.remove(serviceId);
        _serviceQuantities.remove(serviceId);
      }
    });
  }

  void _proceedToBooking() {
    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to booking form with selected services
    final selectedServices = <BookingService>[];
    final allServices = ref.read(bookingProvider).services;
    
    for (final serviceId in _selectedServiceIds) {
      final service = allServices.firstWhere((s) => s.id == serviceId);
      final quantity = _serviceQuantities[serviceId] ?? 1;
      
      selectedServices.add(BookingService.fromCareService(service, quantity: quantity));
    }

    // Navigate to booking form screen with selected services
    context.pushNamed(
      'booking-form',
      pathParameters: {'caregiverId': widget.caregiverId},
      extra: selectedServices,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final categories = bookingState.categories;
    final services = bookingState.services;

    // Update tab controller when categories change
    if (categories.isNotEmpty && _tabController.length != categories.length + 1) {
      _tabController.dispose();
      _tabController = TabController(length: categories.length + 1, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Services'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: categories.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                onTap: (index) {
                  _onCategorySelected(index == 0 ? null : categories[index - 1].id);
                },
                tabs: [
                  const Tab(text: 'All Services'),
                  ...categories.map((category) => Tab(text: category.name)),
                ],
              )
            : null,
      ),
      body: bookingState.isLoadingServices
          ? const Center(child: CircularProgressIndicator())
          : bookingState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load services',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bookingState.error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Service List
                    Expanded(
                      child: services.isEmpty
                          ? const Center(
                              child: Text(
                                'No services available',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: services.length,
                              itemBuilder: (context, index) {
                                final service = services[index];
                                return _buildServiceCard(service);
                              },
                            ),
                    ),

                    // Selected Services Summary
                    if (_selectedServiceIds.isNotEmpty) _buildSelectedServicesSummary(),

                    // Continue Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedServiceIds.isNotEmpty ? _proceedToBooking : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _selectedServiceIds.isEmpty
                                ? 'Select Services to Continue'
                                : 'Continue to Booking (${_selectedServiceIds.length} ${_selectedServiceIds.length == 1 ? 'service' : 'services'})',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildServiceCard(CareService service) {
    final isSelected = _selectedServiceIds.contains(service.id);
    final quantity = _serviceQuantities[service.id] ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: () => _toggleServiceSelection(service.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Header
              Row(
                children: [
                  // Service Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: service.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              service.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.medical_services,
                                  size: 32,
                                  color: Colors.grey[600],
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.medical_services,
                            size: 32,
                            color: Colors.grey[600],
                          ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Service Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.formattedPrice,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          service.formattedDuration,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Selection Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleServiceSelection(service.id),
                  ),
                ],
              ),

              // Service Description
              const SizedBox(height: 12),
              Text(
                service.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),

              // Requirements
              if (service.requirements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: service.requirements
                      .map((requirement) => Chip(
                            label: Text(
                              requirement,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.grey[100],
                            side: BorderSide(color: Colors.grey[300]!),
                          ))
                      .toList(),
                ),
              ],

              // Quantity Selector
              if (isSelected) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Quantity:'),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: quantity > 1
                          ? () => _updateServiceQuantity(service.id, quantity - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quantity.toString(),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateServiceQuantity(service.id, quantity + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedServicesSummary() {
    final services = ref.read(bookingProvider).services;
    double totalCost = 0;
    int totalDuration = 0;

    for (final serviceId in _selectedServiceIds) {
      final service = services.firstWhere((s) => s.id == serviceId);
      final quantity = _serviceQuantities[serviceId] ?? 1;
      totalCost += service.basePrice * quantity;
      totalDuration += service.durationMinutes * quantity;
    }

    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    final durationText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Services Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Cost:'),
              Text(
                '\$${totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Duration:'),
              Text(
                durationText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}