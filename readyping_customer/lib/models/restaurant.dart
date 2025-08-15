class Restaurant {
  final String id;
  final String name;
  final String description;
  final String address;
  final String phoneNumber;
  final String qrCode;
  final List<String> categories;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final bool isOpen;
  final Map<String, dynamic> settings;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.phoneNumber,
    required this.qrCode,
    required this.categories,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.imageUrl = '',
    this.isOpen = true,
    this.settings = const {},
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      qrCode: json['qrCode'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      isOpen: json['isOpen'] ?? true,
      settings: json['settings'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phoneNumber': phoneNumber,
      'qrCode': qrCode,
      'categories': categories,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'isOpen': isOpen,
      'settings': settings,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    String? qrCode,
    List<String>? categories,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    bool? isOpen,
    Map<String, dynamic>? settings,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      qrCode: qrCode ?? this.qrCode,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      isOpen: isOpen ?? this.isOpen,
      settings: settings ?? this.settings,
    );
  }
} 