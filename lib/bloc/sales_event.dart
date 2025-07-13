import 'package:equatable/equatable.dart';

abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object?> get props => [];
}

class LoadSales extends SalesEvent {}

class AddSale extends SalesEvent {
  final int productId;
  final int quantity;
  final double price;
  final double cost;
  final DateTime date;

  const AddSale({
    required this.productId,
    required this.quantity,
    required this.price,
    required this.cost,
    required this.date,
  });

  @override
  List<Object?> get props => [productId, quantity, price, cost, date];
}

class AddProduct extends SalesEvent {
  final String name;
  final double price;
  final double cost;
  final int stock;

  const AddProduct({
    required this.name,
    required this.price,
    required this.cost,
    required this.stock,
  });

  @override
  List<Object?> get props => [name, price, cost, stock];
}

class UpdateProduct extends SalesEvent {
  final int id;
  final String name;
  final double price;
  final double cost;
  final int stock;

  const UpdateProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.cost,
    required this.stock,
  });

  @override
  List<Object?> get props => [id, name, price, cost, stock];
}

class DeleteProduct extends SalesEvent {
  final int id;

  const DeleteProduct({required this.id});

  @override
  List<Object?> get props => [id];
}

class ClearSales extends SalesEvent {}