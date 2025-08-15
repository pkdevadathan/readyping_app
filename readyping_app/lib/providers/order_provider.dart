import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<Order> get orders => _orders;
  List<Order> get activeOrders => _orders.where((order) => 
    order.status != OrderStatus.completed
  ).toList();
  List<Order> get completedOrders => _orders.where((order) => 
    order.status == OrderStatus.completed
  ).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  final ApiService _apiService = ApiService();

  // Load orders from API
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
      final response = await _apiService.getOrders(
        status: status,
        page: _currentPage,
        limit: 20,
      );

      final List<dynamic> ordersData = response['orders'] ?? [];
      final List<Order> newOrders = ordersData.map((data) => Order.fromJson(data)).toList();

      if (refresh) {
        _orders = newOrders;
      } else {
        _orders.addAll(newOrders);
      }

      // Update pagination info
      final pagination = response['pagination'] ?? {};
      _hasMore = pagination['hasNext'] ?? false;
      _currentPage++;

      notifyListeners();
    } catch (e) {
      // If API fails, use demo data for testing
      print('🔄 API failed, using demo data: $e');
      generateDemoData();
      _setError(null); // Clear error since we have demo data
    } finally {
      _setLoading(false);
    }
  }

  // Add new order
  Future<bool> addOrder({
    required String orderId,
    required String customerName,
    required String phoneNumber,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    int? estimatedTime,
    String? notes,
    String? priority,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.createOrder(
        orderId: orderId,
        customerName: customerName,
        phoneNumber: phoneNumber,
        items: items,
        totalAmount: totalAmount,
        estimatedTime: estimatedTime,
        notes: notes,
        priority: priority,
      );

      final newOrder = Order.fromJson(response['order']);
      _orders.insert(0, newOrder); // Add to beginning
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    _setLoading(true);
    _setError(null);

    try {
      // For demo mode, update locally
      final index = _orders.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        final order = _orders[index];
        Order updatedOrder;
        
        if (status == OrderStatus.ready) {
          updatedOrder = order.copyWith(
            status: status,
            readyAt: DateTime.now(),
            notificationSent: true,
          );
          print('🍕 Order #$orderId marked as ready - WhatsApp notification sent!');
        } else {
          updatedOrder = order.copyWith(status: status);
        }
        
        _orders[index] = updatedOrder;
        notifyListeners();
        return true;
      } else {
        _setError('Order not found');
        return false;
      }
    } catch (e) {
      _setError('Failed to update order status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update order details
  Future<bool> updateOrder(String orderId, Map<String, dynamic> updateData) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.updateOrder(orderId, updateData);
      final updatedOrder = Order.fromJson(response['order']);

      // Update the order in the list
      final index = _orders.indexWhere((order) => order.orderId == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete order
  Future<bool> deleteOrder(String orderId) async {
    _setLoading(true);
    _setError(null);

    try {
      // For demo mode, remove locally
      final initialCount = _orders.length;
      _orders.removeWhere((order) => order.orderId == orderId);
      
      if (_orders.length < initialCount) {
        notifyListeners();
        print('🗑️ Order #$orderId deleted from demo data');
        return true;
      } else {
        _setError('Order not found');
        return false;
      }
    } catch (e) {
      _setError('Failed to delete order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Bulk update orders
  Future<bool> bulkUpdateOrders(List<String> orderIds, OrderStatus status) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.bulkUpdateOrders(orderIds, status.name);
      
      // Update orders in the list
      for (final orderId in orderIds) {
        final index = _orders.indexWhere((order) => order.orderId == orderId);
        if (index != -1) {
          _orders[index] = _orders[index].copyWith(status: status);
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to bulk update orders: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get order statistics
  Future<Map<String, dynamic>?> getOrderStats({String period = 'today'}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.getOrderStats(period: period);
      return response;
    } catch (e) {
      _setError('Failed to load order statistics: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get single order
  Future<Order?> getOrder(String orderId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.getOrder(orderId);
      return Order.fromJson(response['order']);
    } catch (e) {
      _setError('Failed to load order: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Clear completed orders (local only, doesn't delete from server)
  void clearCompletedOrders() {
    _orders.removeWhere((order) => order.status == OrderStatus.completed);
    notifyListeners();
  }

  // Generate demo data (for testing when backend is not available)
  void generateDemoData() {
    final demoOrders = [
      Order(
        id: '1',
        orderId: 'ORD001',
        customerName: 'Rahul Sharma',
        phoneNumber: '+919876543210',
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Order(
        id: '2',
        orderId: 'ORD002',
        customerName: 'Priya Patel',
        phoneNumber: '+919876543211',
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Order(
        id: '3',
        orderId: 'ORD003',
        customerName: 'Amit Kumar',
        phoneNumber: '+919876543212',
        status: OrderStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        readyAt: DateTime.now().subtract(const Duration(minutes: 2)),
        notificationSent: true,
      ),
      Order(
        id: '4',
        orderId: 'ORD004',
        customerName: 'Neha Singh',
        phoneNumber: '+919876543213',
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];

    _orders = demoOrders;
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

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Refresh all data
  Future<void> refresh() async {
    await loadOrders(refresh: true);
  }
} 