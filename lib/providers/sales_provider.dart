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
  bool _isMounted = true;
  bool _isAddingProduct = false; // Flag to control notifications

  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _topSellingProducts = [];

  double get totalSales => _totalSales;
  double get totalCost => _totalCost;
  double get totalProfit => _totalProfit;
  List<Map<String, dynamic>> get sales => _sales;
  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get topSellingProducts => _topSellingProducts;

  final String _baseUrl = 'http://192.168.1.106:8000/api/auth/financial';
  final RetryClient _client = RetryClient(
    http.Client(),
    retries: 3,
    delay: (retryCount) => Duration(seconds: retryCount * 2),
  );
  final AuthProvider _authProvider;

  SalesProvider(this._authProvider) {
    print('SalesProvider initialized with authProvider: $_authProvider at ${DateTime.now()}');
    if (_authProvider.isAuthenticated) {
      loadUserData();
    }
  }

  Future<String> _validateToken(BuildContext context) async {
    final token = _authProvider.token;
    if (token == null || token.isEmpty) {
      print('No valid token, logging out at ${DateTime.now()}');
      await _authProvider.logout(context);
      throw Exception('No valid authentication token available. Please log in again.');
    }
    return token;
  }

  void clear() {
    _sales.clear();
    _products.clear();
    _topSellingProducts.clear();
    _totalSales = 0.0;
    _totalCost = 0.0;
    _totalProfit = 0.0;
    if (_isMounted) {
      print('Clearing SalesProvider state and notifying listeners at ${DateTime.now()}');
      notifyListeners();
    }
  }

  Future<void> loadUserData() async {
    print('Loading user data at ${DateTime.now()}');
    if (!_authProvider.isAuthenticated) {
      print('Authentication not available, skipping data load at ${DateTime.now()}');
      clear();
      return;
    }

    try {
      final token = _authProvider.token;
      if (token == null || token.isEmpty) {
        throw Exception('No valid authentication token available.');
      }

      print('Fetching products from $_baseUrl/products/ at ${DateTime.now()}');
      final productsResponse = await _client.get(
        Uri.parse('$_baseUrl/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      print('Products Response: ${productsResponse.statusCode} ${productsResponse.body} at ${DateTime.now()}');
      if (productsResponse.statusCode == 200) {
        final data = jsonDecode(productsResponse.body);
        if (data['products'] is! List) {
          print('Unexpected products format: ${data['products']} at ${DateTime.now()}');
          throw Exception('Invalid products data format: ${data['products']}');
        }
        final productList = List<Map<String, dynamic>>.from(data['products'] ?? []);
        final List<Map<String, dynamic>> parsedProducts = productList.map((p) {
          return {
            'name': p['name'] as String,
            'stock': int.tryParse(p['stock'].toString()) ?? 0,
            'price': double.tryParse(p['price'].toString()) ?? 0.0,
            'cost': double.tryParse(p['cost'].toString()) ?? 0.0,
            'id': int.tryParse(p['id'].toString()) ?? 0,
          };
        }).toList();
        _products.clear();
        _products.addAll(parsedProducts);
        print('Parsed Products: $_products at ${DateTime.now()}');
      } else if (productsResponse.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception('Failed to load products: ${productsResponse.statusCode} ${productsResponse.body}');
      }

      print('Fetching sales from $_baseUrl/sales/ at ${DateTime.now()}');
      final salesResponse = await _client.get(
        Uri.parse('$_baseUrl/sales/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      print('Sales Response: ${salesResponse.statusCode} ${salesResponse.body} at ${DateTime.now()}');
      if (salesResponse.statusCode == 200) {
        final data = jsonDecode(salesResponse.body);
        if (data['sales'] is! List) {
          print('Unexpected sales format: ${data['sales']} at ${DateTime.now()}');
          throw Exception('Invalid sales data format: ${data['sales']}');
        }
        final salesList = List<Map<String, dynamic>>.from(data['sales'] ?? []);
        final List<Map<String, dynamic>> parsedSales = salesList.map((s) {
          return {
            'id': int.tryParse(s['id'].toString()) ?? 0,
            'product': s['product_name'] as String? ?? _products.firstWhere(
                  (p) => p['id'] == int.tryParse(s['product'].toString()),
              orElse: () => {'name': 'Unknown'},
            )['name'],
            'quantity': int.tryParse(s['quantity'].toString()) ?? 0,
            'price': double.tryParse(s['price'].toString()) ?? 0.0,
            'cost': double.tryParse(s['cost'].toString()) ?? 0.0,
            'date': s['date'] as String,
          };
        }).toList();
        _sales.clear();
        _sales.addAll(parsedSales);
        print('Parsed Sales: $_sales at ${DateTime.now()}');
      } else if (salesResponse.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception('Failed to load sales: ${salesResponse.statusCode} ${salesResponse.body}');
      }

      _topSellingProducts.clear();
      for (var sale in _sales) {
        final productName = sale['product'] as String;
        final quantity = sale['quantity'] as int;
        final topProductIndex = _topSellingProducts.indexWhere((p) => p['name'] == productName);
        if (topProductIndex != -1) {
          _topSellingProducts[topProductIndex]['quantity'] = (_topSellingProducts[topProductIndex]['quantity'] as int) + quantity;
        } else {
          _topSellingProducts.add({'name': productName, 'quantity': quantity});
        }
      }
      _topSellingProducts.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      _calculateTotals();
      if (_isMounted) {
        print('Notifying listeners after loadUserData at ${DateTime.now()}');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      print('Error loading user data: $e\n$stackTrace at ${DateTime.now()}');
      if (_isMounted) {
        print('Notifying listeners on error at ${DateTime.now()}');
        notifyListeners();
      }
      throw Exception('Failed to load user data: $e');
    }
  }

  void _calculateTotals() {
    _totalSales = _sales.fold(0.0, (sum, sale) {
      final quantity = (sale['quantity'] as num).toDouble();
      final price = (sale['price'] as num).toDouble();
      return sum + (quantity * price);
    });
    _totalCost = _sales.fold(0.0, (sum, sale) {
      final quantity = (sale['quantity'] as num).toDouble();
      final cost = (sale['cost'] as num).toDouble();
      return sum + (quantity * cost);
    });
    _totalProfit = _totalSales - _totalCost;
  }

  Future<void> addSale(BuildContext context, Map<String, dynamic> sale) async {
    try {
      final productName = sale['product'] as String?;
      final quantity = sale['quantity'] as int?;
      final price = sale['price'] as double?;
      final date = sale['date'] as String?;

      if (productName == null || quantity == null || price == null || date == null) {
        throw Exception('Invalid sale data provided.');
      }

      final product = _products.firstWhere(
            (p) => p['name'] == productName,
        orElse: () => throw Exception('Product $productName not found in inventory.'),
      );

      if (product['stock'] < quantity) {
        throw Exception('Insufficient stock for $productName. Available: ${product['stock']}');
      }

      final token = await _validateToken(context);

      print('Adding sale: Product: $productName (ID: ${product['id']}), Quantity: $quantity, Price: $price, Date: $date at ${DateTime.now()}');
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

      print('Add Sale Response: ${response.statusCode} ${response.body} at ${DateTime.now()}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final newSale = {
          'id': int.tryParse(responseData['id'].toString()) ?? (_sales.isNotEmpty ? (_sales.last['id'] as int) + 1 : 1),
          'product': productName,
          'quantity': quantity,
          'price': price,
          'cost': product['cost'] as double,
          'date': date,
        };
        _sales.insert(0, newSale);
        product['stock'] = (product['stock'] as int) - quantity;

        final topProductIndex = _topSellingProducts.indexWhere((p) => p['name'] == productName);
        if (topProductIndex != -1) {
          _topSellingProducts[topProductIndex]['quantity'] = (_topSellingProducts[topProductIndex]['quantity'] as int) + quantity;
        } else {
          _topSellingProducts.add({'name': productName, 'quantity': quantity});
        }
        _topSellingProducts.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

        _calculateTotals();
        if (_isMounted && !_isAddingProduct) {
          print('Notifying listeners after addSale at ${DateTime.now()}');
          notifyListeners();
        }
      } else if (response.statusCode == 401) {
        await _authProvider.logout(context);
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception('Failed to add sale: ${response.statusCode} ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error adding sale: $e\n$stackTrace at ${DateTime.now()}');
      throw Exception('Failed to add sale: $e');
    }
  }

  Future<void> addProduct(BuildContext context, String name, double price, double cost, int stock) async {
    try {
      _isAddingProduct = true; // Suppress notifications during addProduct
      if (_products.any((p) => p['name'].toLowerCase() == name.toLowerCase())) {
        throw Exception('Product "$name" already exists');
      }

      final token = await _validateToken(context);

      print('Adding product: $name, Price: $price, Cost: $cost, Stock: $stock at ${DateTime.now()}');
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

      print('Add Product Response: ${response.statusCode} ${response.body} at ${DateTime.now()}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final newProduct = {
          'name': name,
          'stock': stock,
          'price': price,
          'cost': cost,
          'id': int.tryParse(jsonDecode(response.body)['id'].toString()) ?? 0,
        };
        _products.add(newProduct);
        print('Products after adding: $_products at ${DateTime.now()}');
      } else if (response.statusCode == 401) {
        await _authProvider.logout(context);
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to add product: ${response.statusCode} ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error adding product: $e\n$stackTrace at ${DateTime.now()}');
      throw Exception('Failed to add product: $e');
    } finally {
      _isAddingProduct = false;
      if (_isMounted) {
        print('Notifying listeners after addProduct at ${DateTime.now()}');
        notifyListeners();
      }
    }
  }

  Future<void> deleteProduct(BuildContext context, String name) async {
    try {
      final token = await _validateToken(context);

      print('Deleting product: $name at ${DateTime.now()}');
      final response = await _client.delete(
        Uri.parse('$_baseUrl/products/$name/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Delete Product Response: ${response.statusCode} ${response.body} at ${DateTime.now()}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _products.removeWhere((p) => p['name'] == name);
        _sales.removeWhere((s) => s['product'] == name);
        _topSellingProducts.removeWhere((t) => t['name'] == name);
        _calculateTotals();
        if (_isMounted && !_isAddingProduct) {
          print('Notifying listeners after deleteProduct at ${DateTime.now()}');
          notifyListeners();
        }
        await loadUserData();
      } else if (response.statusCode == 401) {
        await _authProvider.logout(context);
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception('Failed to delete product: ${response.statusCode} ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error deleting product: $e\n$stackTrace at ${DateTime.now()}');
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  void dispose() {
    print('Disposing SalesProvider at ${DateTime.now()}');
    _isMounted = false;
    _client.close();
    super.dispose();
  }
}