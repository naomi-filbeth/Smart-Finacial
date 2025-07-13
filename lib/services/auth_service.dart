import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final String _baseUrl = 'http://192.168.1.106:8000/api/auth';
  final RetryClient _client = RetryClient(
    http.Client(),
    retries: 3,
    delay: (retryCount) => Duration(seconds: retryCount * 2),
  );

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception('Login failed: ${data['message']}');
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('username', username);
        final decodedToken = JwtDecoder.decode(data['token']);
        if (kDebugMode) {
          print('Login token: ${data['token']}, user_id: ${decodedToken['user_id']}');
        }
        return {
          'token': data['token'],
          'username': username,
          'user_id': decodedToken['user_id'] ?? 0,
        };
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>?> register(String username, String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception('Registration failed: ${data['message']}');
        }
        return {'success': true};
      } else {
        throw Exception('Registration failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<Map<String, dynamic>?> checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');
    if (token == null || username == null) return null;

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/validate-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception('Token validation failed: ${data['message']}');
        }
        return {
          'token': token,
          'username': username,
          'user_id': JwtDecoder.decode(token)['user_id'] ?? 0,
        };
      } else {
        await prefs.remove('token');
        await prefs.remove('username');
        return null;
      }
    } catch (e) {
      await prefs.remove('token');
      await prefs.remove('username');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
  }

  Future<void> resetPassword(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/forgot-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to request password reset: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Password reset error: $e');
    }
  }
}