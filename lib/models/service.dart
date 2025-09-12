class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int order;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'order': order,
    };
  }

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconPath: json['iconPath'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

class CareService {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final int durationMinutes;
  final String categoryId;
  final List<String> requirements;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareService({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.durationMinutes,
    required this.categoryId,
    required this.requirements,
    this.isActive = true,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedPrice => '\$${basePrice.toStringAsFixed(2)}';
  
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'durationMinutes': durationMinutes,
      'categoryId': categoryId,
      'requirements': requirements,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CareService.fromJson(Map<String, dynamic> json) {
    return CareService(
      id: json['\$id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      basePrice: json['basePrice']?.toDouble() ?? 0.0,
      durationMinutes: json['durationMinutes'] ?? 60,
      categoryId: json['categoryId'] ?? '',
      requirements: List<String>.from(json['requirements'] ?? []),
      isActive: json['isActive'] ?? true,
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['\$createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? json['\$updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  CareService copyWith({
    String? id,
    String? name,
    String? description,
    double? basePrice,
    int? durationMinutes,
    String? categoryId,
    List<String>? requirements,
    bool? isActive,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CareService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      categoryId: categoryId ?? this.categoryId,
      requirements: requirements ?? this.requirements,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BookingService {
  final String serviceId;
  final String serviceName;
  final double price;
  final int durationMinutes;
  final int quantity;
  final String? notes;

  BookingService({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.durationMinutes,
    this.quantity = 1,
    this.notes,
  });

  double get totalPrice => price * quantity;
  int get totalDuration => durationMinutes * quantity;

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'durationMinutes': durationMinutes,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory BookingService.fromJson(Map<String, dynamic> json) {
    return BookingService(
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      durationMinutes: json['durationMinutes'] ?? 0,
      quantity: json['quantity'] ?? 1,
      notes: json['notes'],
    );
  }

  factory BookingService.fromCareService(CareService service, {int quantity = 1, String? notes}) {
    return BookingService(
      serviceId: service.id,
      serviceName: service.name,
      price: service.basePrice,
      durationMinutes: service.durationMinutes,
      quantity: quantity,
      notes: notes,
    );
  }

  BookingService copyWith({
    String? serviceId,
    String? serviceName,
    double? price,
    int? durationMinutes,
    int? quantity,
    String? notes,
  }) {
    return BookingService(
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}