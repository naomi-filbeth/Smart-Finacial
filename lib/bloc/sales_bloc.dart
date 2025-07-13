import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'sales_event.dart';
import 'sales_state.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final AuthBloc authBloc;
  final RetryClient _client = RetryClient(
    http.Client(),
    retries: 3,
    delay: (retryCount) => Duration(seconds: retryCount * 2),
  );
  final String _baseUrl = 'http://192.168.1.106:8000/api/auth/financial';

  SalesBloc(this.authBloc) : super(const SalesState()) {
    on<LoadSales>(_onLoadSales);
    on<AddSale>(_onAddSale);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<ClearSales>(_onClearSales);

    authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        add(LoadSales());
      } else if (authState is AuthUnauthenticated) {
        add(ClearSales());
      }
    });

    if (authBloc.state is AuthAuthenticated) {
      add(LoadSales());
    }
  }

  Future<void> _onLoadSales(LoadSales event, Emitter<SalesState> emit) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    if (authBloc.state is! AuthAuthenticated) {
      emit(state.copyWith(isLoading: false, sales: [], products: [], topSellingProducts: []));
      return;
    }

    try {
      final token = (authBloc.state as AuthAuthenticated).token;
      final salesResponse = await _client.get(
        Uri.parse('$_baseUrl/sales/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final productsResponse = await _client.get(
        Uri.parse('$_baseUrl/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final topSellingResponse = await _client.get(
        Uri.parse('$_baseUrl/top-selling-products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (salesResponse.statusCode == 200 && productsResponse.statusCode == 200 && topSellingResponse.statusCode == 200) {
        final salesData = jsonDecode(salesResponse.body) as List;
        final productsData = jsonDecode(productsResponse.body) as List;
        final topSellingData = jsonDecode(topSellingResponse.body) as List;

        final products = productsData.map((item) {
          final mappedItem = Map<String, dynamic>.from(item);
          if (kDebugMode) {
            print('Processing product: $mappedItem');
          }
          mappedItem['price'] = (mappedItem['price'] is String
              ? double.tryParse(mappedItem['price'])
              : mappedItem['price'] as num?)?.toDouble() ?? 0.0;
          mappedItem['cost'] = (mappedItem['cost'] is String
              ? double.tryParse(mappedItem['cost'])
              : mappedItem['cost'] as num?)?.toDouble() ?? 0.0;
          mappedItem['stock'] = (mappedItem['stock'] is String
              ? int.tryParse(mappedItem['stock'])
              : mappedItem['stock'] as num?)?.toInt() ?? 0;
          mappedItem['id'] = (mappedItem['id'] is String
              ? int.tryParse(mappedItem['id'])
              : mappedItem['id'] as num?)?.toInt() ?? 0;
          return mappedItem;
        }).toList();

        final sales = salesData.map((item) {
          final mappedItem = Map<String, dynamic>.from(item);
          if (kDebugMode) {
            print('Processing sale: $mappedItem');
          }
          mappedItem['price'] = (mappedItem['price'] is String
              ? double.tryParse(mappedItem['price'])
              : mappedItem['price'] as num?)?.toDouble() ?? 0.0;
          mappedItem['cost'] = (mappedItem['cost'] is String
              ? double.tryParse(mappedItem['cost'])
              : mappedItem['cost'] as num?)?.toDouble() ?? 0.0;
          mappedItem['quantity'] = (mappedItem['quantity'] is String
              ? int.tryParse(mappedItem['quantity'])
              : mappedItem['quantity'] as num?)?.toInt() ?? 0;
          mappedItem['product_id'] = (mappedItem['product'] is String
              ? int.tryParse(mappedItem['product'])
              : mappedItem['product'] as num?)?.toInt() ?? 0;
          mappedItem['date'] = DateTime.tryParse(mappedItem['date'] as String? ?? '') ?? DateTime.now();
          // Map product name
          final product = products.firstWhere(
                (p) => p['id'] == mappedItem['product_id'],
            orElse: () => {'name': 'Unknown Product'},
          );
          mappedItem['product_name'] = product['name'];
          return mappedItem;
        }).toList();

        final topSellingProducts = topSellingData.map((item) {
          final mappedItem = Map<String, dynamic>.from(item);
          if (kDebugMode) {
            print('Processing top selling product: $mappedItem');
          }
          mappedItem['quantity'] = (mappedItem['quantity'] is String
              ? int.tryParse(mappedItem['quantity'])
              : mappedItem['quantity'] as num?)?.toInt() ?? 0;
          mappedItem['name'] = mappedItem['name']?.toString() ?? 'Unknown';
          return mappedItem;
        }).toList();

        final totalSales = sales.fold<double>(
            0.0, (sum, sale) => sum + (sale['quantity'] * sale['price']));
        final totalCost = sales.fold<double>(
            0.0, (sum, sale) => sum + (sale['quantity'] * sale['cost']));
        final totalProfit = totalSales - totalCost;

        emit(state.copyWith(
          isLoading: false,
          sales: sales,
          products: products,
          topSellingProducts: topSellingProducts,
          totalSales: totalSales,
          totalCost: totalCost,
          totalProfit: totalProfit,
        ));
      } else if (salesResponse.statusCode == 401 || productsResponse.statusCode == 401 || topSellingResponse.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to load data: Sales(${salesResponse.statusCode}), Products(${productsResponse.statusCode}), TopSelling(${topSellingResponse.statusCode})');
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      if (e.toString().contains('Session expired')) {
        authBloc.add(Logout());
      }
    }
  }

  Future<void> _onAddSale(AddSale event, Emitter<SalesState> emit) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final token = (authBloc.state as AuthAuthenticated).token;
      final response = await _client.post(
        Uri.parse('$_baseUrl/sales/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product': event.productId,
          'quantity': event.quantity,
          'price': event.price,
          'cost': event.cost,
          'date': event.date.toString().split(' ')[0], // YYYY-MM-DD
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final newSale = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          print('New sale response: $newSale');
        }
        newSale['price'] = (newSale['price'] is String
            ? double.tryParse(newSale['price'])
            : newSale['price'] as num?)?.toDouble() ?? event.price;
        newSale['cost'] = (newSale['cost'] is String
            ? double.tryParse(newSale['cost'])
            : newSale['cost'] as num?)?.toDouble() ?? event.cost;
        newSale['quantity'] = (newSale['quantity'] is String
            ? int.tryParse(newSale['quantity'])
            : newSale['quantity'] as num?)?.toInt() ?? event.quantity;
        newSale['product_id'] = (newSale['product'] is String
            ? int.tryParse(newSale['product'])
            : newSale['product'] as num?)?.toInt() ?? event.productId;
        newSale['date'] = DateTime.tryParse(newSale['date'] as String? ?? '') ?? event.date;
        // Map product name
        final product = state.products.firstWhere(
              (p) => p['id'] == newSale['product_id'],
          orElse: () => {'name': 'Unknown Product'},
        );
        newSale['product_name'] = product['name'];

        final updatedSales = [...state.sales, newSale];
        final totalSales = updatedSales.fold<double>(
            0.0, (sum, sale) => sum + (sale['quantity'] * sale['price']));
        final totalCost = updatedSales.fold<double>(
            0.0, (sum, sale) => sum + (sale['quantity'] * sale['cost']));
        final totalProfit = totalSales - totalCost;

        final updatedProducts = state.products.map((product) {
          if (product['id'] == event.productId) {
            final updatedProduct = Map<String, dynamic>.from(product);
            updatedProduct['stock'] = (product['stock'] as int) - event.quantity;
            return updatedProduct;
          }
          return product;
        }).toList();

        final topSellingProducts = state.topSellingProducts.map((item) {
          final mappedItem = Map<String, dynamic>.from(item);
          if (mappedItem['name'] == product['name']) {
            mappedItem['quantity'] = (mappedItem['quantity'] as int) + event.quantity;
          }
          return mappedItem;
        }).toList();

        emit(state.copyWith(
          isLoading: false,
          sales: updatedSales,
          products: updatedProducts,
          topSellingProducts: topSellingProducts,
          totalSales: totalSales,
          totalCost: totalCost,
          totalProfit: totalProfit,
        ));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to add sale: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      if (e.toString().contains('Session expired')) {
        authBloc.add(Logout());
      }
    }
  }

  Future<void> _onAddProduct(AddProduct event, Emitter<SalesState> emit) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final token = (authBloc.state as AuthAuthenticated).token;
      final response = await _client.post(
        Uri.parse('$_baseUrl/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': event.name,
          'price': event.price,
          'cost': event.cost,
          'stock': event.stock,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final newProduct = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          print('New product response: $newProduct');
        }
        newProduct['price'] = (newProduct['price'] is String
            ? double.tryParse(newProduct['price'])
            : newProduct['price'] as num?)?.toDouble() ?? event.price;
        newProduct['cost'] = (newProduct['cost'] is String
            ? double.tryParse(newProduct['cost'])
            : newProduct['cost'] as num?)?.toDouble() ?? event.cost;
        newProduct['stock'] = (newProduct['stock'] is String
            ? int.tryParse(newProduct['stock'])
            : newProduct['stock'] as num?)?.toInt() ?? event.stock;
        newProduct['id'] = (newProduct['id'] is String
            ? int.tryParse(newProduct['id'])
            : newProduct['id'] as num?)?.toInt() ?? 0;

        emit(state.copyWith(
          isLoading: false,
          products: [...state.products, newProduct],
        ));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to add product: ${response.statusCode}');
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      if (e.toString().contains('Session expired')) {
        authBloc.add(Logout());
      }
    }
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<SalesState> emit) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final token = (authBloc.state as AuthAuthenticated).token;
      final response = await _client.put(
        Uri.parse('$_baseUrl/products/${event.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': event.name,
          'price': event.price,
          'cost': event.cost,
          'stock': event.stock,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final updatedProduct = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          print('Updated product response: $updatedProduct');
        }
        updatedProduct['price'] = (updatedProduct['price'] is String
            ? double.tryParse(updatedProduct['price'])
            : updatedProduct['price'] as num?)?.toDouble() ?? event.price;
        updatedProduct['cost'] = (updatedProduct['cost'] is String
            ? double.tryParse(updatedProduct['cost'])
            : updatedProduct['cost'] as num?)?.toDouble() ?? event.cost;
        updatedProduct['stock'] = (updatedProduct['stock'] is String
            ? int.tryParse(updatedProduct['stock'])
            : updatedProduct['stock'] as num?)?.toInt() ?? event.stock;
        updatedProduct['id'] = (updatedProduct['id'] is String
            ? int.tryParse(updatedProduct['id'])
            : updatedProduct['id'] as num?)?.toInt() ?? event.id;

        final updatedProducts = state.products.map((product) {
          if (product['id'] == event.id) return updatedProduct;
          return product;
        }).toList();

        emit(state.copyWith(
          isLoading: false,
          products: updatedProducts,
        ));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      if (e.toString().contains('Session expired')) {
        authBloc.add(Logout());
      }
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<SalesState> emit) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final token = (authBloc.state as AuthAuthenticated).token;
      final response = await _client.delete(
        Uri.parse('$_baseUrl/products/${event.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 204) {
        final updatedProducts = state.products.where((product) => product['id'] != event.id).toList();
        emit(state.copyWith(isLoading: false, products: updatedProducts));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else if (response.statusCode == 404) {
        throw Exception('Product not found or does not belong to this user.');
      } else if (response.statusCode == 403) {
        throw Exception('Cannot delete product with associated sales.');
      } else {
        throw Exception('Failed to delete product: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      if (e.toString().contains('Session expired')) {
        authBloc.add(Logout());
      }
    }
  }

  Future<void> _onClearSales(ClearSales event, Emitter<SalesState> emit) async {
    emit(const SalesState());
  }

  @override
  Future<void> close() {
    _client.close();
    return super.close();
  }
}