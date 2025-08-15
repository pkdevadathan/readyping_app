import 'package:flutter/foundation.dart';
import '../models/customer_order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<CustomerOrder> _orders = [];
  CustomerOrder? _currentOrder;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<CustomerOrder> get orders => _orders;
  CustomerOrder? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  final ApiService _apiService = ApiService();

  // Load customer orders
  Future<void> loadOrders({String? status, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _orders.clear();
    }
    if (!_hasMore || _isLoading) return;
    
    _setLoading(true);
    _setError(null);
    try {
      // For demo purposes, start with empty orders
      // Orders will be added when customers place orders
      if (_orders.isEmpty) {
        // Don't generate demo data - start fresh
        _orders = [];
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new order
  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    _setLoading(true);
    _setError(null);
    try {
      // For demo purposes, create order locally
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      final order = CustomerOrder(
        id: orderId,
        orderId: orderId,
        restaurantId: orderData['restaurantId'],
        restaurantName: orderData['restaurantName'],
        customerId: 'customer_1',
        customerName: 'Rahul Sharma',
        customerPhone: '+919876543210',
        items: (orderData['items'] as List).map((item) => OrderItem(
          menuItemId: item['menuItemId'],
          name: item['name'],
          quantity: item['quantity'],
          price: item['price'].toDouble(),
        )).toList(),
        totalAmount: orderData['totalAmount'].toDouble(),
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        isPaid: true,
        paymentMethod: 'UPI',
        upiTransactionId: 'UPI${DateTime.now().millisecondsSinceEpoch}',
      );
      
      _currentOrder = order;
      _orders.insert(0, order);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get single order
  Future<CustomerOrder?> getOrder(String orderId) async {
    _setLoading(true);
    _setError(null);
    try {
      final order = await _apiService.getOrder(orderId);
      return order;
    } catch (e) {
      _setError('Failed to get order: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    _setLoading(true);
    _setError(null);
    try {
      final updatedOrder = await _apiService.cancelOrder(orderId);
      
      // Update order in list
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }
      
      // Update current order if it's the same
      if (_currentOrder?.id == orderId) {
        _currentOrder = updatedOrder;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to cancel order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set current order
  void setCurrentOrder(CustomerOrder order) {
    _currentOrder = order;
    notifyListeners();
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  // Get orders by status
  List<CustomerOrder> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Get active orders (not completed or cancelled)
  List<CustomerOrder> get activeOrders {
    return _orders.where((order) => 
      order.status != OrderStatus.completed && 
      order.status != OrderStatus.cancelled
    ).toList();
  }

  // Get completed orders
  List<CustomerOrder> get completedOrders {
    return _orders.where((order) => order.status == OrderStatus.completed).toList();
  }

  // Refresh orders
  Future<void> refresh() async {
    await loadOrders(refresh: true);
  }

  // Generate demo data for testing
  void generateDemoData() {
    _orders = [
      CustomerOrder(
        id: '1',
        orderId: 'ORD001',
        restaurantId: '1',
        restaurantName: 'Maa Ki Rasoi Tiffin',
        customerId: 'customer_1',
        customerName: 'Rahul Sharma',
        customerPhone: '+919876543210',
        items: [
          OrderItem(
            menuItemId: '1',
            name: 'Butter Chicken',
            quantity: 1,
            price: 180.00,
          ),
          OrderItem(
            menuItemId: '4',
            name: 'Chicken Tikka Masala',
            quantity: 1,
            price: 200.00,
          ),
        ],
        totalAmount: 380.00,
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isPaid: true,
        paymentMethod: 'UPI',
        upiTransactionId: 'UPI123456789',
      ),
      CustomerOrder(
        id: '2',
        orderId: 'ORD002',
        restaurantId: '1',
        restaurantName: 'Maa Ki Rasoi Tiffin',
        customerId: 'customer_1',
        customerName: 'Rahul Sharma',
        customerPhone: '+919876543210',
        items: [
          OrderItem(
            menuItemId: '2',
            name: 'Butter Naan',
            quantity: 2,
            price: 30.00,
          ),
          OrderItem(
            menuItemId: '5',
            name: 'Dal Makhani',
            quantity: 1,
            price: 120.00,
          ),
        ],
        totalAmount: 180.00,
        status: OrderStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        readyAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isPaid: true,
        paymentMethod: 'UPI',
        upiTransactionId: 'UPI987654321',
      ),
      CustomerOrder(
        id: '3',
        orderId: 'ORD003',
        restaurantId: '1',
        restaurantName: 'Maa Ki Rasoi Tiffin',
        customerId: 'customer_1',
        customerName: 'Rahul Sharma',
        customerPhone: '+919876543210',
        items: [
          OrderItem(
            menuItemId: '3',
            name: 'Chicken Biryani',
            quantity: 1,
            price: 250.00,
          ),
          OrderItem(
            menuItemId: '6',
            name: 'Raita',
            quantity: 1,
            price: 40.00,
          ),
        ],
        totalAmount: 290.00,
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        isPaid: true,
        paymentMethod: 'UPI',
        upiTransactionId: 'UPI456789123',
      ),
    ];
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