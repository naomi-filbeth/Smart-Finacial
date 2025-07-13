import 'package:equatable/equatable.dart';

class DebtorsState extends Equatable {
  final List<Map<String, dynamic>> debtors;
  final bool isLoading;
  final String errorMessage;

  const DebtorsState({
    this.debtors = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  DebtorsState copyWith({
    List<Map<String, dynamic>>? debtors,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DebtorsState(
      debtors: debtors ?? this.debtors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [debtors, isLoading, errorMessage];
}