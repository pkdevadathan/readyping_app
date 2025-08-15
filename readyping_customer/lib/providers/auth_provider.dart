import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _phoneNumber;
  String? _customerName;
  String? _customerEmail;
  String? _customerId;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get phoneNumber => _phoneNumber;
  String? get customerName => _customerName;
  String? get customerEmail => _customerEmail;
  String? get customerId => _customerId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // Initialize auth state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _apiService.initialize();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        try {
          final profile = await _apiService.getProfile();
          _setAuthenticated(true);
          _setCustomerData(profile['user']);
        } catch (e) {
          await _apiService.clearToken();
          _setAuthenticated(false);
        }
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Send OTP
  Future<bool> sendOTP(String phoneNumber) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.sendOTP(phoneNumber);
      if (response['demo'] == true) {
        print('📱 Demo OTP for $phoneNumber: ${response['otp']}');
      }
      _phoneNumber = phoneNumber;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to send OTP: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login with phone number (no OTP)
  Future<bool> loginWithPhone(String phoneNumber) async {
    _setLoading(true);
    _setError(null);
    try {
      // Create demo user data for direct login
      final user = {
        'id': 'customer_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Customer ${phoneNumber.substring(phoneNumber.length - 4)}',
        'phoneNumber': phoneNumber,
        'email': null,
        'role': 'customer',
        'settings': <String, dynamic>{},
      };

      // Generate demo token
      final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      
      // Save token and user data
      await _apiService.clearToken(); // Clear any existing token
      _setAuthenticated(true);
      _setCustomerData(user);
      return true;
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify OTP and login (kept for compatibility)
  Future<bool> loginWithOTP(String otp) async {
    if (_phoneNumber == null) {
      _setError('Phone number not found. Please send OTP first.');
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.verifyOTP(_phoneNumber!, otp);
      if (response['token'] != null) {
        _setAuthenticated(true);
        _setCustomerData(response['user']);
        return true;
      } else {
        _setError('Login failed: No token received');
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register new customer
  Future<bool> register(String name, String email) async {
    if (_phoneNumber == null) {
      _setError('Phone number not found. Please send OTP first.');
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.register(_phoneNumber!, name, email);
      if (response['success'] == true) {
        _customerName = name;
        _customerEmail = email;
        notifyListeners();
        return true;
      } else {
        _setError('Registration failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.updateProfile(data);
      _setCustomerData(response['user']);
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _apiService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _setAuthenticated(false);
      _clearCustomerData();
      _setLoading(false);
    }
  }

  // Check backend health
  Future<bool> checkBackendHealth() async {
    try {
      final response = await _apiService.healthCheck();
      return response['status'] == 'OK';
    } catch (e) {
      return false;
    }
  }

  // Private helper methods
  void _setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void _setCustomerData(Map<String, dynamic> userData) {
    _customerId = userData['id'];
    _customerName = userData['name'];
    _customerEmail = userData['email'];
    _phoneNumber = userData['phoneNumber'];
    notifyListeners();
  }

  void _clearCustomerData() {
    _customerId = null;
    _customerName = null;
    _customerEmail = null;
    _phoneNumber = null;
    notifyListeners();
  }

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