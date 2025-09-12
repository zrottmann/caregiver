import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleAuthService {
  static const String _userKey = 'current_user';
  
  Future<bool> login(String email, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple mock authentication - accept any email/password combo
    if (email.isNotEmpty && password.isNotEmpty) {
      final userData = {
        'id': '1',
        'email': email,
        'name': email.split('@')[0],
        'userType': 'patient', // or 'caregiver'
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(userData));
      return true;
    }
    return false;
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }
  
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}