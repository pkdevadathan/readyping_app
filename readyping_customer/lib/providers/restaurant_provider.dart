import 'package:flutter/foundation.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class RestaurantProvider with ChangeNotifier {
  List<Restaurant> _restaurants = [];
  Restaurant? _selectedRestaurant;
  List<MenuItem> _menuItems = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Restaurant> get restaurants => _restaurants;
  Restaurant? get selectedRestaurant => _selectedRestaurant;
  List<MenuItem> get menuItems => _menuItems;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // Search restaurants
  Future<void> searchRestaurants(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      // For demo purposes, filter from existing restaurants
      final allRestaurants = [
        Restaurant(
          id: '1',
          name: 'Maa Ki Rasoi Tiffin',
          description: 'Homestyle Indian tiffin with authentic flavors',
          address: '123 MG Road, Bangalore',
          phoneNumber: '+91-9876543210',
          qrCode: 'maa_ki_rasoi_001',
          categories: ['Indian', 'Tiffin', 'Homestyle'],
          rating: 4.5,
          reviewCount: 128,
          imageUrl: '',
          isOpen: true,
        ),
        Restaurant(
          id: '2',
          name: 'Annapurna Tiffin Center',
          description: 'Traditional South Indian tiffin and meals',
          address: '456 Koramangala, Bangalore',
          phoneNumber: '+91-9876543211',
          qrCode: 'annapurna_tiffin_002',
          categories: ['South Indian', 'Tiffin', 'Vegetarian'],
          rating: 4.2,
          reviewCount: 89,
          imageUrl: '',
          isOpen: true,
        ),
        Restaurant(
          id: '3',
          name: 'Dabba Express',
          description: 'Quick and healthy tiffin delivery service',
          address: '789 Indiranagar, Bangalore',
          phoneNumber: '+91-9876543212',
          qrCode: 'dabba_express_003',
          categories: ['Tiffin', 'Healthy', 'Quick Service'],
          rating: 4.7,
          reviewCount: 156,
          imageUrl: '',
          isOpen: true,
        ),
        Restaurant(
          id: '4',
          name: 'Ghar Ka Khana',
          description: 'Home-cooked meals delivered fresh daily',
          address: '321 Jayanagar, Bangalore',
          phoneNumber: '+91-9876543213',
          qrCode: 'ghar_ka_khana_004',
          categories: ['Homestyle', 'Tiffin', 'North Indian'],
          rating: 4.3,
          reviewCount: 67,
          imageUrl: '',
          isOpen: true,
        ),
        Restaurant(
          id: '5',
          name: 'Tiffin Box',
          description: 'Variety of regional Indian cuisines',
          address: '654 Whitefield, Bangalore',
          phoneNumber: '+91-9876543214',
          qrCode: 'tiffin_box_005',
          categories: ['Multi-cuisine', 'Tiffin', 'Regional'],
          rating: 4.1,
          reviewCount: 94,
          imageUrl: '',
          isOpen: true,
        ),
      ];

      // Filter restaurants based on search query
      _restaurants = allRestaurants.where((restaurant) {
        final searchLower = query.toLowerCase();
        return restaurant.name.toLowerCase().contains(searchLower) ||
               restaurant.description.toLowerCase().contains(searchLower) ||
               restaurant.address.toLowerCase().contains(searchLower) ||
               restaurant.categories.any((category) => 
                 category.toLowerCase().contains(searchLower));
      }).toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to search restaurants: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get restaurant by QR code
  Future<bool> getRestaurantByQR(String qrCode) async {
    _setLoading(true);
    _setError(null);
    try {
      // For demo purposes, use local data instead of API call
      generateDemoData();
      
      // Find restaurant by QR code
      _selectedRestaurant = _restaurants.firstWhere(
        (restaurant) => restaurant.qrCode == qrCode,
        orElse: () => _restaurants.first, // Fallback to first restaurant
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to get restaurant: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get restaurant by ID
  Future<bool> getRestaurant(String restaurantId) async {
    _setLoading(true);
    _setError(null);
    try {
      // For demo purposes, use local data instead of API call
      generateDemoData();
      
      // Find restaurant by ID
      _selectedRestaurant = _restaurants.firstWhere(
        (restaurant) => restaurant.id == restaurantId,
        orElse: () => _restaurants.first, // Fallback to first restaurant
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to get restaurant: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load restaurant menu
  Future<void> _loadRestaurantMenu(String restaurantId) async {
    try {
      // Menu items are already loaded in generateDemoData()
      _selectedCategory = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load menu: $e');
    }
  }

  // Set selected category
  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Get menu items by category
  List<MenuItem> getMenuItemsByCategory(String category) {
    return _menuItems.where((item) => item.category == category).toList();
  }

  // Get available menu items
  List<MenuItem> get availableMenuItems {
    return _menuItems.where((item) => item.isAvailable).toList();
  }

  // Get menu items for selected category
  List<MenuItem> get filteredMenuItems {
    if (_selectedCategory == null) {
      return availableMenuItems;
    }
    return availableMenuItems.where((item) => item.category == _selectedCategory).toList();
  }

  // Clear selected restaurant
  void clearSelectedRestaurant() {
    _selectedRestaurant = null;
    _menuItems = [];
    _categories = [];
    _selectedCategory = null;
    notifyListeners();
  }

  // Clear search results
  void clearSearchResults() {
    _restaurants = [];
    notifyListeners();
  }

  // Generate demo data for testing
  void generateDemoData() {
    _restaurants = [
      Restaurant(
        id: '1',
        name: 'Maa Ki Rasoi Tiffin',
        description: 'Homestyle Indian tiffin with authentic flavors',
        address: '123 MG Road, Bangalore',
        phoneNumber: '+91-9876543210',
        qrCode: 'maa_ki_rasoi_001',
        categories: ['Indian', 'Tiffin', 'Homestyle'],
        rating: 4.5,
        reviewCount: 128,
        imageUrl: '',
        isOpen: true,
      ),
      Restaurant(
        id: '2',
        name: 'Annapurna Tiffin Center',
        description: 'Traditional South Indian tiffin and meals',
        address: '456 Koramangala, Bangalore',
        phoneNumber: '+91-9876543211',
        qrCode: 'annapurna_tiffin_002',
        categories: ['South Indian', 'Tiffin', 'Vegetarian'],
        rating: 4.2,
        reviewCount: 89,
        imageUrl: '',
        isOpen: true,
      ),
      Restaurant(
        id: '3',
        name: 'Dabba Express',
        description: 'Quick and healthy tiffin delivery service',
        address: '789 Indiranagar, Bangalore',
        phoneNumber: '+91-9876543212',
        qrCode: 'dabba_express_003',
        categories: ['Tiffin', 'Healthy', 'Quick Service'],
        rating: 4.7,
        reviewCount: 156,
        imageUrl: '',
        isOpen: true,
      ),
      Restaurant(
        id: '4',
        name: 'Ghar Ka Khana',
        description: 'Home-cooked meals delivered fresh daily',
        address: '321 Jayanagar, Bangalore',
        phoneNumber: '+91-9876543213',
        qrCode: 'ghar_ka_khana_004',
        categories: ['Homestyle', 'Tiffin', 'North Indian'],
        rating: 4.3,
        reviewCount: 67,
        imageUrl: '',
        isOpen: true,
      ),
      Restaurant(
        id: '5',
        name: 'Tiffin Box',
        description: 'Variety of regional Indian cuisines',
        address: '654 Whitefield, Bangalore',
        phoneNumber: '+91-9876543214',
        qrCode: 'tiffin_box_005',
        categories: ['Multi-cuisine', 'Tiffin', 'Regional'],
        rating: 4.1,
        reviewCount: 94,
        imageUrl: '',
        isOpen: true,
      ),
    ];

    _menuItems = [
      MenuItem(
        id: '1',
        name: 'Butter Chicken',
        description: 'Creamy tomato-based curry with tender chicken',
        price: 180.00,
        category: 'Main Course',
        isAvailable: true,
        tags: ['Spicy', 'Popular'],
      ),
      MenuItem(
        id: '2',
        name: 'Butter Naan',
        description: 'Soft and fluffy Indian bread with butter',
        price: 30.00,
        category: 'Bread',
        isAvailable: true,
        tags: ['Vegetarian'],
      ),
      MenuItem(
        id: '3',
        name: 'Chicken Biryani',
        description: 'Aromatic rice dish with spices and chicken',
        price: 250.00,
        category: 'Main Course',
        isAvailable: true,
        tags: ['Spicy', 'Popular'],
      ),
      MenuItem(
        id: '4',
        name: 'Chicken Tikka Masala',
        description: 'Grilled chicken in creamy curry sauce',
        price: 200.00,
        category: 'Main Course',
        isAvailable: true,
        tags: ['Spicy', 'Popular'],
      ),
      MenuItem(
        id: '5',
        name: 'Dal Makhani',
        description: 'Creamy black lentils cooked overnight',
        price: 120.00,
        category: 'Main Course',
        isAvailable: true,
        tags: ['Vegetarian', 'Popular'],
      ),
      MenuItem(
        id: '6',
        name: 'Raita',
        description: 'Cooling yogurt with cucumber and mint',
        price: 40.00,
        category: 'Side Dish',
        isAvailable: true,
        tags: ['Vegetarian'],
      ),
      MenuItem(
        id: '7',
        name: 'Masala Dosa',
        description: 'Crispy dosa with potato filling',
        price: 80.00,
        category: 'Breakfast',
        isAvailable: true,
        tags: ['Vegetarian', 'South Indian'],
      ),
      MenuItem(
        id: '8',
        name: 'Idli Sambar',
        description: 'Soft idlis with hot sambar',
        price: 60.00,
        category: 'Breakfast',
        isAvailable: true,
        tags: ['Vegetarian', 'South Indian'],
      ),
    ];

    _categories = ['Main Course', 'Bread', 'Side Dish', 'Breakfast', 'Appetizers', 'Desserts'];
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 