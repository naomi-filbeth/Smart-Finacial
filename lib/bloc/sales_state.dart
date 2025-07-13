import 'package:equatable/equatable.dart';

class SalesState extends Equatable {
  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> topSellingProducts;
  final bool isLoading;
  final String errorMessage;
  final double totalSales;
  final double totalCost;
  final double totalProfit;

  const SalesState({
    this.sales = const [],
    this.products = const [],
    this.topSellingProducts = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.totalSales = 0.0,
    this.totalCost = 0.0,
    this.totalProfit = 0.0,
  });

  SalesState copyWith({
    List<Map<String, dynamic>>? sales,
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? topSellingProducts,
    bool? isLoading,
    String? errorMessage,
    double? totalSales,
    double? totalCost,
    double? totalProfit,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      products: products ?? this.products,
      topSellingProducts: topSellingProducts ?? this.topSellingProducts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      totalSales: totalSales ?? this.totalSales,
      totalCost: totalCost ?? this.totalCost,
      totalProfit: totalProfit ?? this.totalProfit,
    );
  }

  @override
  List<Object?> get props => [
    sales,
    products,
    topSellingProducts,
    isLoading,
    errorMessage,
    totalSales,
    totalCost,
    totalProfit,
  ];
}