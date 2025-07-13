import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'dart:convert';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'debtors_event.dart';
import 'debtors_state.dart';

class DebtorsBloc extends Bloc<DebtorsEvent, DebtorsState> {
  final AuthBloc authBloc;
  final RetryClient _client = RetryClient(
    http.Client(),
    retries: 3,
    delay: (retryCount) => Duration(seconds: retryCount * 2),
  );
  final String _baseUrl = 'http://192.168.1.106:8000/api';

  DebtorsBloc(this.authBloc) : super(const DebtorsState()) {
    on<LoadDebtors>(_onLoadDebtors);
    on<AddDebtor>(_onAddDebtor);
    on<UpdateDebtor>(_onUpdateDebtor);
    on<DeleteDebtor>(_onDeleteDebtor);
    on<ClearDebtors>(_onClearDebtors);

    // Load debtors when authenticated
    authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        add(LoadDebtors());
      } else if (authState is AuthUnauthenticated) {
        add(ClearDebtors());
      }
    });

    // Initial load if already authenticated
    if (authBloc.state is AuthAuthenticated) {
      add(LoadDebtors());
    }
  }

  Future<void> _onLoadDebtors(LoadDebtors event, Emitter<DebtorsState> emit) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    if (authBloc.state is! AuthAuthenticated) {
      emit(state.copyWith(isLoading: false, debtors: []));
      return;
    }

    try {
      final token = (authBloc.state as AuthAuthenticated).token;
      final response = await _client.get(
        Uri.parse('$_baseUrl/debtors/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final debtors = data.map((item) {
          final mappedItem = Map<String, dynamic>.from(item);
          if (mappedItem['balance'] is String) {
            mappedItem['balance'] = double.tryParse(mappedItem['balance'] as String) ?? 0.0;
          }
          return mappedItem;
        }).toList();
        emit(state.copyWith(isLoading: false, debtors: debtors));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to load debtors: ${response.statusCode}');
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

  Future<void> _onAddDebtor(AddDebtor event, Emitter<DebtorsState> emit) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final token = (authBloc.state as AuthAuthenticated).token;
      final response = await _client.post(
        Uri.parse('$_baseUrl/debtors/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': event.name,
          'balance': event.balance,
          'phone' : event.phone,
          'product' : event.product,
          if (event.email != null && event.email!.isNotEmpty) 'email': event.email,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final newDebtor = jsonDecode(response.body) as Map<String, dynamic>;
        if (newDebtor['balance'] is String) {
          newDebtor['balance'] = double.tryParse(newDebtor['balance'] as String) ?? event.balance;
        }
        emit(state.copyWith(
          isLoading: false,
          debtors: [...state.debtors, newDebtor],
        ));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to add debtor: ${response.statusCode}');
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

  Future<void> _onUpdateDebtor(UpdateDebtor event, Emitter<DebtorsState> emit) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final token = (authBloc.state as AuthAuthenticated).token;
      final response = await _client.put(
        Uri.parse('$_baseUrl/debtors/${event.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'balance': event.balance,
          if (event.email != null && event.email!.isNotEmpty) 'email': event.email,
          'phone': event.phone,
          'product': event.product,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final updatedDebtor = jsonDecode(response.body) as Map<String, dynamic>;
        if (updatedDebtor['balance'] is String) {
          updatedDebtor['balance'] = double.tryParse(updatedDebtor['balance'] as String) ?? event.balance;
        }
        final updatedDebtors = state.debtors.map((d) {
          if (d['id'] == event.id) return updatedDebtor;
          return d;
        }).toList();
        emit(state.copyWith(isLoading: false, debtors: updatedDebtors));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to update debtor: ${response.statusCode}');
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

  Future<void> _onDeleteDebtor(DeleteDebtor event, Emitter<DebtorsState> emit) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: ''));

    try {
      final token = (authBloc.state as AuthAuthenticated).token;
      final response = await _client.delete(
        Uri.parse('$_baseUrl/debtors/${event.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 204) {
        final updatedDebtors = state.debtors.where((d) => d['id'] != event.id).toList();
        emit(state.copyWith(isLoading: false, debtors: updatedDebtors));
      } else if (response.statusCode == 401) {
        throw Exception('Session expired.');
      } else {
        throw Exception('Failed to delete debtor: ${response.statusCode}');
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

  Future<void> _onClearDebtors(ClearDebtors event, Emitter<DebtorsState> emit) async {
    emit(const DebtorsState());
  }

  @override
  Future<void> close() {
    _client.close();
    return super.close();
  }
}