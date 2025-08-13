import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _vendorId;
  String? _vendorName;

  bool get isAuthenticated => _isAuthenticated;
  String? get vendorId => _vendorId;
  String? get vendorName => _vendorName;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _vendorId = prefs.getString('vendorId');
    _vendorName = prefs.getString('vendorName');
    notifyListeners();
  }

  Future<void> _saveAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', _isAuthenticated);
    await prefs.setString('vendorId', _vendorId ?? '');
    await prefs.setString('vendorName', _vendorName ?? '');
  }

  Future<bool> loginWithOTP(String phoneNumber, String otp) async {
    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 2));
    
    // For demo purposes, accept any 6-digit OTP
    if (otp.length == 6) {
      _isAuthenticated = true;
      _vendorId = 'vendor_${DateTime.now().millisecondsSinceEpoch}';
      _vendorName = 'Restaurant ${phoneNumber.substring(phoneNumber.length - 4)}';
      
      await _saveAuthState();
      notifyListeners();
      return true;
    }
    
    return false;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _vendorId = null;
    _vendorName = null;
    
    await _saveAuthState();
    notifyListeners();
  }

  Future<String> sendOTP(String phoneNumber) async {
    // Simulate OTP sending
    await Future.delayed(const Duration(seconds: 1));
    
    // For demo purposes, return a fixed OTP
    return '123456';
  }
} 