import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _phoneNumber;
  String? _restaurantName;
  String? _userId;
  Map<String, dynamic>? _userSettings;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get phoneNumber => _phoneNumber;
  String? get restaurantName => _restaurantName;
  String? get userId => _userId;
  Map<String, dynamic>? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // Initialize auth state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _apiService.initialize();
      
      // Check if we have a stored token and validate it
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        // Try to get user profile to validate token
        try {
          final profile = await _apiService.getProfile();
          _setAuthenticated(true);
          _setUserData(profile['user']);
        } catch (e) {
          // Token is invalid, clear it
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
  Future<bool> sendOTP(String phoneNumber, {String? restaurantName}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _apiService.sendOTP(phoneNumber, restaurantName: restaurantName);
      
      if (response['demo'] == true) {
        // In demo mode, show the OTP in console
        print('📱 Demo OTP for $phoneNumber: ${response['otp']}');
      }
      
      _phoneNumber = phoneNumber;
      if (restaurantName != null) {
        _restaurantName = restaurantName;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to send OTP: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login with credentials (phone + password)
  Future<bool> loginWithCredentials(String phoneNumber, String password, {String? restaurantName}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      // For demo mode, accept any credentials
      // In production, this would validate against the backend
      if (phoneNumber.isNotEmpty && password.isNotEmpty) {
        // Create demo user data
        final demoUser = {
          'id': 'restaurant_1',
          'phoneNumber': phoneNumber,
          'restaurantName': restaurantName ?? 'Demo Restaurant',
          'userType': 'restaurant',
          'settings': {
            'notifications': true,
            'autoAccept': false,
          }
        };
        
        _setAuthenticated(true);
        _setUserData(demoUser);
        _phoneNumber = phoneNumber;
        if (restaurantName != null) {
          _restaurantName = restaurantName;
        }
        
        print('🍕 Restaurant logged in: ${demoUser['restaurantName']}');
        return true;
      } else {
        _setError('Please enter valid phone number and password');
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify OTP and login (kept for backward compatibility)
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
        _setUserData(response['user']);
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

  // Register new restaurant
  Future<bool> register(String restaurantName, String phoneNumber, {String? email, String? password}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _apiService.register(restaurantName, phoneNumber, email: email, password: password);
      
      if (response['token'] != null) {
        _setAuthenticated(true);
        _setUserData(response['user']);
        return true;
      } else {
        _setError('Registration failed: No token received');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? restaurantName, String? email, Map<String, dynamic>? settings}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _apiService.updateProfile(
        restaurantName: restaurantName,
        email: email,
        settings: settings,
      );
      
      if (response['user'] != null) {
        _setUserData(response['user']);
        return true;
      } else {
        _setError('Profile update failed');
        return false;
      }
    } catch (e) {
      _setError('Profile update failed: $e');
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
      // Even if logout API fails, clear local data
      print('Logout API error: $e');
    } finally {
      _setAuthenticated(false);
      _clearUserData();
      _setLoading(false);
    }
  }

  // Check if backend is available
  Future<bool> checkBackendHealth() async {
    try {
      await _apiService.healthCheck();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Private helper methods
  void _setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void _setUserData(Map<String, dynamic> userData) {
    _userId = userData['id'];
    _restaurantName = userData['restaurantName'];
    _phoneNumber = userData['phoneNumber'];
    _userSettings = userData['settings'] ?? {};
    notifyListeners();
  }

  void _clearUserData() {
    _userId = null;
    _restaurantName = null;
    _phoneNumber = null;
    _userSettings = null;
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

  // Clear error
  void clearError() {
    _setError(null);
  }
} 