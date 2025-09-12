import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> subServices;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.subServices = const [],
  });

  static List<ServiceCategory> getAllCategories() {
    return [
      ServiceCategory(
        id: 'senior_care',
        name: 'Senior Care',
        description: 'Comprehensive care for elderly patients',
        icon: Icons.elderly,
        color: Colors.blue,
        subServices: [
          'Daily Living Assistance',
          'Medication Management',
          'Mobility Support',
          'Companionship',
          'Meal Preparation',
          'Light Housekeeping',
        ],
      ),
      ServiceCategory(
        id: 'child_care',
        name: 'Child Care',
        description: 'Professional childcare services',
        icon: Icons.child_care,
        color: Colors.orange,
        subServices: [
          'Babysitting',
          'Nanny Services',
          'After School Care',
          'Educational Support',
          'Meal Preparation',
          'Transportation',
        ],
      ),
      ServiceCategory(
        id: 'medical_care',
        name: 'Medical Care',
        description: 'Licensed medical assistance',
        icon: Icons.medical_services,
        color: Colors.red,
        subServices: [
          'Nursing Care',
          'Physical Therapy',
          'Wound Care',
          'Injection Administration',
          'Vital Signs Monitoring',
          'Post-Surgery Care',
        ],
      ),
      ServiceCategory(
        id: 'disability_care',
        name: 'Disability Care',
        description: 'Specialized care for individuals with disabilities',
        icon: Icons.accessible,
        color: Colors.purple,
        subServices: [
          'Personal Care Assistance',
          'Mobility Support',
          'Communication Assistance',
          'Daily Living Skills',
          'Community Integration',
          'Respite Care',
        ],
      ),
      ServiceCategory(
        id: 'mental_health',
        name: 'Mental Health Support',
        description: 'Mental health and emotional support services',
        icon: Icons.psychology,
        color: Colors.teal,
        subServices: [
          'Emotional Support',
          'Crisis Intervention',
          'Medication Reminders',
          'Therapeutic Activities',
          'Social Interaction',
          'Counseling Support',
        ],
      ),
      ServiceCategory(
        id: 'post_surgery',
        name: 'Post-Surgery Care',
        description: 'Recovery assistance after surgical procedures',
        icon: Icons.healing,
        color: Colors.green,
        subServices: [
          'Wound Monitoring',
          'Medication Management',
          'Mobility Assistance',
          'Physical Therapy Support',
          'Pain Management',
          'Recovery Planning',
        ],
      ),
      ServiceCategory(
        id: 'companion_care',
        name: 'Companion Care',
        description: 'Social companionship and emotional support',
        icon: Icons.favorite,
        color: Colors.pink,
        subServices: [
          'Social Companionship',
          'Conversation',
          'Reading Assistance',
          'Entertainment Activities',
          'Light Housekeeping',
          'Errands',
        ],
      ),
      ServiceCategory(
        id: 'respite_care',
        name: 'Respite Care',
        description: 'Temporary relief for primary caregivers',
        icon: Icons.schedule,
        color: Colors.indigo,
        subServices: [
          'Short-term Care',
          'Emergency Coverage',
          'Overnight Care',
          'Weekend Care',
          'Holiday Coverage',
          'Scheduled Breaks',
        ],
      ),
    ];
  }

  static ServiceCategory? getCategoryById(String id) {
    try {
      return getAllCategories().firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<ServiceCategory> getCategoriesByIds(List<String> ids) {
    return getAllCategories().where((category) => ids.contains(category.id)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subServices': subServices,
    };
  }

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    // For data from backend, we'll match with predefined categories
    final predefinedCategory = getCategoryById(json['id'] ?? '');
    if (predefinedCategory != null) {
      return predefinedCategory;
    }

    // Fallback for custom categories
    return ServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: Icons.help_outline, // Default icon
      color: Colors.grey, // Default color
      subServices: List<String>.from(json['subServices'] ?? []),
    );
  }
}