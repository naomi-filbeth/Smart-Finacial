import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

class AuthService {
  static const String _baseUrl = 'http://192.168.1.106:8000/api/auth';

  String get baseUrl => _baseUrl;

  final RetryClient _client = RetryClient(
    http.Client(),
    retries: 3,
    delay: (retryCount) => Duration(seconds: retryCount * 2),
  );

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = '$_baseUrl/register/';
    print('Register URL: $url');
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      print('Register Response: ${response.statusCode} ${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        return {'success': true, 'message': 'Registration successful'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('Register Error: $e');
      if (e.toString().contains('XMLHttpRequest')) {
        return {
          'success': false,
          'message': 'CORS error: The server is not configured to allow requests from this origin. Please check the backend CORS settings.'
        };
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = '$_baseUrl/login/';
    print('Login URL: $url');
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      print('Login Response: ${response.statusCode} ${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        final accessToken = data['token']; // Use the token directly as a string
        return {'success': true, 'token': accessToken, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Login Error: $e');
      if (e.toString().contains('XMLHttpRequest')) {
        return {
          'success': false,
          'message': 'CORS error: The server is not configured to allow requests from this origin. Please check the backend CORS settings.'
        };
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    final url = '$_baseUrl/forgot-password';
    print('Reset Password URL: $url');
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      print('Reset Password Response: ${response.statusCode} ${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        return {'success': true, 'message': data['message'] ?? 'Password reset email sent'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to send reset email'};
      }
    } catch (e) {
      print('Reset Password Error: $e');
      if (e.toString().contains('XMLHttpRequest')) {
        return {
          'success': false,
          'message': 'CORS error: The server is not configured to allow requests from this origin. Please check the backend CORS settings.'
        };
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  void dispose() {
    _client.close();
  }
}