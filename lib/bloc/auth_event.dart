import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthentication extends AuthEvent {}

class Login extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;

  const Login({
    required this.username,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [username, password, rememberMe];
}

class Register extends AuthEvent {
  final String username;
  final String email;
  final String password;

  const Register({
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [username, email, password];
}

class Logout extends AuthEvent {}

class ResetPassword extends AuthEvent {
  final String email;

  const ResetPassword({required this.email});

  @override
  List<Object?> get props => [email];
}