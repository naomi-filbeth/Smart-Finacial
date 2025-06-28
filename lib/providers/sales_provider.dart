import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_provider.dart';

class SalesProvider with ChangeNotifier {
  double _totalSales = 0.0;
  double _totalCost = 0.0;
  double _totalProfit = 0.0;
  bool _isLoading = false;
  String _errorMessage = '';
  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _topSellingProducts = [];

  double get totalSales => _totalSales;
  double get totalCost => _totalCost;
  double get totalProfit => _totalProfit;
  List<Map<String, dynamic>> get sales => List.unmodifiable(_sales);
  List<Map<String, dynamic>> get products => List.unmodifiable(_products);
  List<Map<String, dynamic>> get topSellingProducts => List.unmodifiable(_topSellingProducts);
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  final String _baseUrl = 'http://192.168.1.106:8000/api/auth/financial';
  final RetryClient _client = RetryClient(
    http.Client(),
    retries: 3,
    delay: (retryCount) => Duration(seconds: retryCount * 2),
  );
  final AuthProvider _authProvider;

  SalesProvider(this._authProvider) {
    if (_authProvider.isAuthenticated) {
      loadUserData();
    }
  }

  Future<void> _validateToken() async {
    if (!_authProvider.isAuthenticated) {
      throw Exception('No valid authentication token. Please log in again.');
    }
  }

  void clear() {
    _sales.clear();
    _products.clear();
    _topSellingProducts.clear();
    _totalSales = 0.0;
    _totalCost = 0.0;
    _totalProfit = 0.0;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> loadUserData() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    if (!_authProvider.isAuthenticated) {
      clear();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await _validateToken();
      final token = _authProvider.token;
      final productsResponse = await _client.get(
        Uri.parse('$_baseUrl/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (productsResponse.statusCode == 200) {
        final data = jsonDecode(productsResponse.body);
        if (data['products'] is! List) {
          throw Exception('Invalid products data format.');
        }
        final productList = List<Map<String, dynamic>>.from(data['products']);
        _products.clear();
        _products.addAll(productList.map((p) => {
          'name': p['name'] as String,
          'stock': int.parse(p['stock'].toString()),
          'price': double.parse(p['price'].toString()),
          'cost': double.parse(p['cost'].toString()),
          'id': int.parse(p['id'].toString()),
        }));
      } else if (productsResponse.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to load products: ${productsResponse.statusCode}');
      }

      final salesResponse = await _client.get(
        Uri.parse('$_baseUrl/sales/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (salesResponse.statusCode == 200) {
        final data = jsonDecode(salesResponse.body);
        if (data['sales'] is! List) {
          throw Exception('Invalid sales data format.');
        }
        final salesList = List<Map<String, dynamic>>.from(data['sales']);
        _sales.clear();
        _sales.addAll(salesList.map((s) => {
          'id': int.parse(s['id'].toString()),
          'product': s['product_name'] as String? ??
              _products.firstWhere(
                    (p) => p['id'] == int.parse(s['product'].toString()),
                orElse: () => {'name': 'Unknown'},
              )['name'] as String,
          'quantity': int.parse(s['quantity'].toString()),
          'price': double.parse(s['price'].toString()),
          'cost': double.parse(s['cost'].toString()),
          'date': s['date'] as String,
        }));
      } else if (salesResponse.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to load sales: ${salesResponse.statusCode}');
      }

      _topSellingProducts.clear();
      for (var sale in _sales) {
        final productName = sale['product'] as String;
        final quantity = sale['quantity'] as int;
        final existing = _topSellingProducts.firstWhere(
              (p) => p['name'] == productName,
          orElse: () => {'name': productName, 'quantity': 0},
        );
        existing['quantity'] = (existing['quantity'] as int) + quantity;
        if (!_topSellingProducts.contains(existing)) {
          _topSellingProducts.add(existing);
        }
      }
      _topSellingProducts.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      _calculateTotals();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      if (e.toString().contains('Session expired')) {
        await _authProvider.logout(BuildContext as BuildContext);
      }
    }
  }

  void _calculateTotals() {
    _totalSales = _sales.fold(0.0, (sum, sale) => sum + (sale['quantity'] as int) * (sale['price'] as double));
    _totalCost = _sales.fold(0.0, (sum, sale) => sum + (sale['quantity'] as int) * (sale['cost'] as double));
    _totalProfit = _totalSales - _totalCost;
  }

  Future<void> addSale(BuildContext context, Map<String, dynamic> sale) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final productName = sale['product'] as String;
      final quantity = sale['quantity'] as int;
      final price = sale['price'] as double;
      final date = sale['date'] as String;

      final product = _products.firstWhere(
            (p) => p['name'] == productName,
        orElse: () => throw Exception('Product $productName not found.'),
      );

      if (product['stock'] < quantity) {
        throw Exception('Insufficient stock for $productName. Available: ${product['stock']}');
      }

      await _validateToken();
      final token = _authProvider.token;
      final response = await _client.post(
        Uri.parse('$_baseUrl/sales/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product': product['id'],
          'quantity': quantity,
          'price': price,
          'cost': product['cost'] as double,
          'date': date,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _sales.insert(0, {
          'id': int.parse(responseData['id'].toString()),
          'product': productName,
          'quantity': quantity,
          'price': price,
          'cost': product['cost'] as double,
          'date': date,
        });
        product['stock'] = (product['stock'] as int) - quantity;

        final existing = _topSellingProducts.firstWhere(
              (p) => p['name'] == productName,
          orElse: () => {'name': productName, 'quantity': 0},
        );
        existing['quantity'] = (existing['quantity'] as int) + quantity;
        if (!_topSellingProducts.contains(existing)) {
          _topSellingProducts.add(existing);
        }
        _topSellingProducts.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

        _calculateTotals();
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to add sale: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (e.toString().contains('Session expired')) {
        await _authProvider.logout(context);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(BuildContext context, String name, double price, double cost, int stock) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (_products.any((p) => p['name'].toLowerCase() == name.toLowerCase())) {
        throw Exception('Product "$name" already exists.');
      }

      await _validateToken();
      final token = _authProvider.token;
      final response = await _client.post(
        Uri.parse('$_baseUrl/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'price': price,
          'cost': cost,
          'stock': stock,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _products.add({
          'name': name,
          'stock': stock,
          'price': price,
          'cost': cost,
          'id': int.parse(jsonDecode(response.body)['id'].toString()),
        });
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to add product: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (e.toString().contains('Session expired')) {
        await _authProvider.logout(context);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(BuildContext context, String name) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _validateToken();
      final token = _authProvider.token;
      final response = await _client.delete(
        Uri.parse('$_baseUrl/products/$name/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        _products.removeWhere((p) => p['name'] == name);
        _sales.removeWhere((s) => s['product'] == name);
        _topSellingProducts.removeWhere((t) => t['name'] == name);
        _calculateTotals();
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (e.toString().contains('Session expired')) {
        await _authProvider.logout(context);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}