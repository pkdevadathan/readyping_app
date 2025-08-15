import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  // Handle response and throw exceptions for errors
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      final errorData = jsonDecode(response.body);
      throw ApiException(
        message: errorData['error']?['message'] ?? 'Unknown error',
        statusCode: response.statusCode,
      );
    }
  }

  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    return jsonDecode(response.body);
  }

  // Authentication methods
  Future<Map<String, dynamic>> sendOTP(String phoneNumber, {String? restaurantName}) async {
    final data = {
      'phoneNumber': phoneNumber,
      if (restaurantName != null) 'restaurantName': restaurantName,
    };
    
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
    
    // Save token if login successful
    if (responseData['token'] != null) {
      await _saveToken(responseData['token']);
    }
    
    return responseData;
  }

  Future<Map<String, dynamic>> register(String restaurantName, String phoneNumber, {String? email, String? password}) async {
    final data = {
      'restaurantName': restaurantName,
      'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
    };
    
    final response = await _post('/auth/register', data);
    final responseData = jsonDecode(response.body);
    
    // Save token if registration successful
    if (responseData['token'] != null) {
      await _saveToken(responseData['token']);
    }
    
    return responseData;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _get('/auth/profile');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateProfile({String? restaurantName, String? email, Map<String, dynamic>? settings}) async {
    final data = <String, dynamic>{};
    if (restaurantName != null) data['restaurantName'] = restaurantName;
    if (email != null) data['email'] = email;
    if (settings != null) data['settings'] = settings;
    
    final response = await _put('/auth/profile', data);
    return jsonDecode(response.body);
  }

  Future<void> logout() async {
    await _post('/auth/logout', {});
    await clearToken();
  }

  // Order methods
  Future<Map<String, dynamic>> getOrders({String? status, int page = 1, int limit = 20}) async {
    final queryParams = <String, String>{};
    if (status != null && status != 'all') queryParams['status'] = status;
    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();
    
    final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _authHeaders);
    _handleResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final response = await _get('/orders/$orderId');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createOrder({
    required String orderId,
    required String customerName,
    required String phoneNumber,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    int? estimatedTime,
    String? notes,
    String? priority,
  }) async {
    final data = {
      'orderId': orderId,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      if (items != null) 'items': items,
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (estimatedTime != null) 'estimatedTime': estimatedTime,
      if (notes != null) 'notes': notes,
      if (priority != null) 'priority': priority,
    };
    
    final response = await _post('/orders', data);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final response = await _patch('/orders/$orderId/status', {'status': status});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateOrder(String orderId, Map<String, dynamic> updateData) async {
    final response = await _put('/orders/$orderId', updateData);
    return jsonDecode(response.body);
  }

  Future<void> deleteOrder(String orderId) async {
    await _delete('/orders/$orderId');
  }

  Future<Map<String, dynamic>> bulkUpdateOrders(List<String> orderIds, String status) async {
    final response = await _post('/orders/bulk/status', {
      'orderIds': orderIds,
      'status': status,
    });
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getOrderStats({String period = 'today'}) async {
    final response = await _get('/orders/stats/overview?period=$period');
    return jsonDecode(response.body);
  }

  // QR Code methods
  Future<Map<String, dynamic>> getQRCodes() async {
    final response = await _get('/qr');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createQRCode({
    required String name,
    String? description,
    Map<String, dynamic>? settings,
  }) async {
    final data = {
      'name': name,
      if (description != null) 'description': description,
      if (settings != null) 'settings': settings,
    };
    
    final response = await _post('/qr', data);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getQRCode(String code) async {
    final response = await http.get(
      Uri.parse('$baseUrl/qr/$code'),
      headers: {'Content-Type': 'application/json'},
    );
    _handleResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getQRCodeImage(String code, {int size = 200}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/qr/$code/image?size=$size'),
      headers: {'Content-Type': 'application/json'},
    );
    _handleResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateQRCode(String id, Map<String, dynamic> updateData) async {
    final response = await _put('/qr/$id', updateData);
    return jsonDecode(response.body);
  }

  Future<void> deleteQRCode(String id) async {
    await _delete('/qr/$id');
  }

  Future<Map<String, dynamic>> getQRStats() async {
    final response = await _get('/qr/stats/overview');
    return jsonDecode(response.body);
  }

  // Analytics methods
  Future<Map<String, dynamic>> getDashboardAnalytics({String period = 'today'}) async {
    final response = await _get('/analytics/dashboard?period=$period');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getOrderTrends({int days = 7}) async {
    final response = await _get('/analytics/orders/trends?days=$days');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getPerformanceMetrics({String period = 'month'}) async {
    final response = await _get('/analytics/performance?period=$period');
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