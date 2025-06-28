import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'dart:convert';
import 'auth_provider.dart';

class DebtorsProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _debtors = [];
  final String _baseUrl =
      'http://192.168.1.106:8000/api'; // Update to 'http://10.0.2.2:8000/api' for Android emulator
  final RetryClient _client = RetryClient(
    http.Client(),
    retries: 3,
    delay: (retryCount) => Duration(seconds: retryCount * 2),
  );
  AuthProvider? _authProvider;

  DebtorsProvider([this._authProvider]) {
    if (_authProvider != null) {
      loadDebtors();
    }
  }

  List<Map<String, dynamic>> get debtors => _debtors;

  Future<void> loadDebtors() async {
    print('Loading debtors at ${DateTime.now()}');
    if (_authProvider == null || !_authProvider!.isAuthenticated) {
      print('Authentication not available, skipping debtors load');
      return;
    }

    try {
      final token = _authProvider!.token;
      if (token == null) {
        print('No authentication token available');
        return;
      }

      print('Fetching debtors from $_baseUrl/debtors/');
      final response = await _client.get(
        Uri.parse('$_baseUrl/debtors/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      print('Debtors Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _debtors.clear();
        _debtors.addAll(data.map((item) {
          final mappedItem = Map<String, dynamic>.from(item);
          if (mappedItem['balance'] is String) {
            mappedItem['balance'] =
                double.tryParse(mappedItem['balance'] as String) ?? 0.0;
          }
          return mappedItem;
        }).toList());
        notifyListeners();
      } else {
        throw Exception('Failed to load debtors: ${response.body}');
      }
    } catch (e) {
      print('Error loading debtors: $e');
    }
  }

  Future<void> addDebtor(String name, double balance,
      {String? email, String? phone, String? address}) async {
    try {
      final token = _authProvider!.token;
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/debtors/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'balance': balance,
              if (email != null && email.isNotEmpty) 'email': email,
              if (phone != null && phone.isNotEmpty) 'phone': phone,
              if (address != null && address.isNotEmpty) 'address': address,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Add Debtor Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        final newDebtor = jsonDecode(response.body) as Map<String, dynamic>;
        if (newDebtor['balance'] is String) {
          newDebtor['balance'] =
              double.tryParse(newDebtor['balance'] as String) ?? balance;
        }
        _debtors.add(newDebtor);
        notifyListeners();
      } else {
        throw Exception('Failed to add debtor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add debtor: ${e.toString()}');
    }
  }

  Future<void> updateDebtor(int id, double balance,
      {String? email, String? phone, String? address}) async {
    try {
      final token = _authProvider!.token;
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await _client
          .put(
            Uri.parse('$_baseUrl/debtors/$id/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'balance': balance,
              if (email != null && email.isNotEmpty) 'email': email,
              if (phone != null && phone.isNotEmpty) 'phone': phone,
              if (address != null && address.isNotEmpty) 'address': address,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final index = _debtors.indexWhere((d) => d['id'] == id);
        if (index != -1) {
          final updatedDebtor =
              jsonDecode(response.body) as Map<String, dynamic>;
          if (updatedDebtor['balance'] is String) {
            updatedDebtor['balance'] =
                double.tryParse(updatedDebtor['balance'] as String) ?? balance;
          }
          _debtors[index] = updatedDebtor;
          notifyListeners();
        }
      } else if (response.statusCode == 404) {
        throw Exception('Debtor with ID $id not found.');
      } else {
        throw Exception('Failed to update debtor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update debtor: ${e.toString()}');
    }
  }

  Future<void> deleteDebtor(int id) async {
    try {
      final token = _authProvider!.token;
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await _client.delete(
        Uri.parse('$_baseUrl/debtors/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 204) {
        _debtors.removeWhere((d) => d['id'] == id);
        notifyListeners();
      } else if (response.statusCode == 404) {
        throw Exception('Debtor with ID $id not found.');
      } else {
        throw Exception('Failed to delete debtor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete debtor: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
