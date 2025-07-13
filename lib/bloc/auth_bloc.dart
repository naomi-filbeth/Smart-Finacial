import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:flutter/foundation.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<CheckAuthentication>(_onCheckAuthentication);
    on<Login>(_onLogin);
    on<Register>(_onRegister);
    on<Logout>(_onLogout);
    on<ResetPassword>(_onResetPassword);

    add(CheckAuthentication());
  }

  Future<void> _onCheckAuthentication(CheckAuthentication event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (!rememberMe) {
      emit(AuthUnauthenticated());
      return;
    }

    try {
      final data = await _authService.checkAuthentication();
      if (data != null) {
        if (kDebugMode) {
          print('Authenticated user: ${data['username']}, user_id: ${data['user_id']}');
        }
        emit(AuthAuthenticated(
          token: data['token'],
          username: data['username'],
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLogin(Login event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final data = await _authService.login(event.username, event.password);
      if (data != null) {
        final prefs = await SharedPreferences.getInstance();
        if (event.rememberMe) {
          await prefs.setBool('remember_me', true);
        }
        if (kDebugMode) {
          print('Login successful: ${data['username']}, user_id: ${data['user_id']}');
        }
        emit(AuthAuthenticated(
          token: data['token'],
          username: event.username,
        ));
      } else {
        emit(AuthError(message: 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRegister(Register event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _authService.register(event.username, event.email, event.password);
      if (result?['success']) {
        emit(AuthInitial());
      } else {
        emit(AuthError(message: result?['message'] ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLogout(Logout event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onResetPassword(ResetPassword event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(event.email);
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }
}