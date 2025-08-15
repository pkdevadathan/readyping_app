import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../models/customer_order.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  // Initialize auth token from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Save auth token to storage
  Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear auth token
  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get auth headers
  Map<String, String> get _authHeaders {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  // Generic HTTP methods
  Future<http.Response> _get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _authHeaders,
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> _patch(String endpoint, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> _put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _authHeaders,
      body: jsonEncode(data),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> _delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _authHeaders,
    );
    _handleResponse(response);
    return response;
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      final errorData = jsonDecode(response.body);
      throw ApiException(
        message: errorData['error']?['message'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
  }

  // Customer Authentication
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    final data = {'phoneNumber': phoneNumber};
    final response = await _post('/auth/send-otp', data);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otp) async {
    final data = {
      'phoneNumber': phoneNumber,
      'otp': otp,
    };
    final response = await _post('/auth/verify-otp', data);
    final responseData = jsonDecode(response.body);
    if (responseData['token'] != null) {
      await _saveToken(responseData['token']);
    }
    return responseData;
  }

  Future<Map<String, dynamic>> register(String phoneNumber, String name, String email) async {
    final data = {
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
    };
    final response = await _post('/auth/register', data);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _get('/auth/profile');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _put('/auth/profile', data);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await _post('/auth/logout', {});
    await clearToken();
    return jsonDecode(response.body);
  }

  // Restaurant Discovery
  Future<List<Restaurant>> searchRestaurants(String query) async {
    final response = await _get('/restaurants/search?q=$query');
    final data = jsonDecode(response.body);
    final restaurants = (data['restaurants'] as List<dynamic>?)
        ?.map((json) => Restaurant.fromJson(json))
        .toList() ?? [];
    return restaurants;
  }

  Future<Restaurant> getRestaurantByQR(String qrCode) async {
    final response = await _get('/restaurants/qr/$qrCode');
    final data = jsonDecode(response.body);
    return Restaurant.fromJson(data['restaurant']);
  }

  Future<Restaurant> getRestaurant(String restaurantId) async {
    final response = await _get('/restaurants/$restaurantId');
    final data = jsonDecode(response.body);
    return Restaurant.fromJson(data['restaurant']);
  }

  // Menu Management
  Future<List<MenuItem>> getRestaurantMenu(String restaurantId) async {
    final response = await _get('/restaurants/$restaurantId/menu');
    final data = jsonDecode(response.body);
    final menuItems = (data['menu'] as List<dynamic>?)
        ?.map((json) => MenuItem.fromJson(json))
        .toList() ?? [];
    return menuItems;
  }

  Future<List<String>> getMenuCategories(String restaurantId) async {
    final response = await _get('/restaurants/$restaurantId/menu/categories');
    final data = jsonDecode(response.body);
    return List<String>.from(data['categories'] ?? []);
  }

  // Order Management
  Future<CustomerOrder> createOrder(Map<String, dynamic> orderData) async {
    final response = await _post('/orders', orderData);
    final data = jsonDecode(response.body);
    return CustomerOrder.fromJson(data['order']);
  }

  Future<List<CustomerOrder>> getCustomerOrders({String? status, int page = 1, int limit = 20}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;
    
    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _get('/orders?$queryString');
    final data = jsonDecode(response.body);
    final orders = (data['orders'] as List<dynamic>?)
        ?.map((json) => CustomerOrder.fromJson(json))
        .toList() ?? [];
    return orders;
  }

  Future<CustomerOrder> getOrder(String orderId) async {
    final response = await _get('/orders/$orderId');
    final data = jsonDecode(response.body);
    return CustomerOrder.fromJson(data['order']);
  }

  Future<CustomerOrder> cancelOrder(String orderId) async {
    final response = await _patch('/orders/$orderId/cancel', {});
    final data = jsonDecode(response.body);
    return CustomerOrder.fromJson(data['order']);
  }

  // Payment
  Future<Map<String, dynamic>> initiatePayment(String orderId, String paymentMethod) async {
    final data = {
      'orderId': orderId,
      'paymentMethod': paymentMethod,
    };
    final response = await _post('/payments/initiate', data);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> confirmPayment(String orderId, String transactionId) async {
    final data = {
      'orderId': orderId,
      'transactionId': transactionId,
    };
    final response = await _post('/payments/confirm', data);
    return jsonDecode(response.body);
  }

  // Health Check
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    return jsonDecode(response.body);
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
} 