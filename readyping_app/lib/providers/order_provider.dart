import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  List<Order> get activeOrders => _orders.where((order) => order.status != OrderStatus.completed).toList();
  List<Order> get completedOrders => _orders.where((order) => order.status == OrderStatus.completed).toList();
  bool get isLoading => _isLoading;

  OrderProvider() {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString('orders');
    if (ordersJson != null) {
      final List<dynamic> ordersList = json.decode(ordersJson);
      _orders = ordersList.map((json) => Order.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = json.encode(_orders.map((order) => order.toJson()).toList());
    await prefs.setString('orders', ordersJson);
  }

  Future<void> addOrder(String orderId, String customerName, String phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: orderId,
      customerName: customerName,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
    );

    _orders.add(order);
    await _saveOrders();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _isLoading = true;
    notifyListeners();

    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      final order = _orders[orderIndex];
      final updatedOrder = order.copyWith(
        status: newStatus,
        readyAt: newStatus == OrderStatus.ready ? DateTime.now() : order.readyAt,
      );

      _orders[orderIndex] = updatedOrder;

      // Send WhatsApp notification if order is ready
      if (newStatus == OrderStatus.ready) {
        await _sendWhatsAppNotification(updatedOrder);
      }

      await _saveOrders();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _sendWhatsAppNotification(Order order) async {
    // Simulate WhatsApp API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Update order with notification sent status
    final orderIndex = _orders.indexWhere((o) => o.id == order.id);
    if (orderIndex != -1) {
      _orders[orderIndex] = order.copyWith(notificationSent: true);
      await _saveOrders();
    }
  }

  Future<void> markOrderAsCompleted(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.completed);
  }

  Future<void> deleteOrder(String orderId) async {
    _orders.removeWhere((order) => order.id == orderId);
    await _saveOrders();
    notifyListeners();
  }

  Future<void> clearCompletedOrders() async {
    _orders.removeWhere((order) => order.status == OrderStatus.completed);
    await _saveOrders();
    notifyListeners();
  }

  // Generate demo data for testing
  Future<void> generateDemoData() async {
    final demoOrders = [
      Order(
        id: '1',
        orderId: 'ORD001',
        customerName: 'John Doe',
        phoneNumber: '+1234567890',
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Order(
        id: '2',
        orderId: 'ORD002',
        customerName: 'Jane Smith',
        phoneNumber: '+1234567891',
        status: OrderStatus.ready,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        readyAt: DateTime.now().subtract(const Duration(minutes: 5)),
        notificationSent: true,
      ),
      Order(
        id: '3',
        orderId: 'ORD003',
        customerName: 'Mike Johnson',
        phoneNumber: '+1234567892',
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        readyAt: DateTime.now().subtract(const Duration(minutes: 45)),
        notificationSent: true,
      ),
    ];

    _orders.addAll(demoOrders);
    await _saveOrders();
    notifyListeners();
  }
} 