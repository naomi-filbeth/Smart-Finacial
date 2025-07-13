import 'package:equatable/equatable.dart';

abstract class DebtorsEvent extends Equatable {
  const DebtorsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDebtors extends DebtorsEvent {}

class AddDebtor extends DebtorsEvent {
  final String name;
  final double balance;
  final String? email;
  final String? phone;
  final String? product;

  const AddDebtor({
    required this.name,
    required this.balance,
    this.email,
    this.phone,
    this.product,
  });

  @override
  List<Object?> get props => [name, balance, email, phone, product];
}

class UpdateDebtor extends DebtorsEvent {
  final int id;
  final double balance;
  final String? email;
  final String? phone;
  final String? product;

  const UpdateDebtor({
    required this.id,
    required this.balance,
    this.email,
    this.phone,
    this.product,
  });

  @override
  List<Object?> get props => [id, balance, email, phone, product];
}

class DeleteDebtor extends DebtorsEvent {
  final int id;

  const DeleteDebtor({required this.id});

  @override
  List<Object?> get props => [id];
}

class ClearDebtors extends DebtorsEvent {}