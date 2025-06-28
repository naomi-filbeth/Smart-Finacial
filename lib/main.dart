import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_financial/providers/debtors_provider.dart';
import 'package:smart_financial/providers/sales_provider.dart';
// import 'package:device_preview/device_preview.dart';
import 'package:smart_financial/screens/login_screen.dart';
import 'package:smart_financial/screens/register_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/main_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  // runApp(DevicePreview(builder: (context) => SmartFinanceApp()));
  runApp(SmartFinanceApp());
}

class SmartFinanceApp extends StatelessWidget {
  const SmartFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
            create: (context) => SalesProvider(
                Provider.of<AuthProvider>(context, listen: false))),
        ChangeNotifierProvider(
            create: (context) => DebtorsProvider(
                Provider.of<AuthProvider>(context, listen: false)))
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'smart finance',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/check-auth': (context) => const AuthCheckScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);

    return FutureBuilder<bool>(
      future: authProvider.checkAuthentication(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Waiting for authentication at ${DateTime.now()}');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data == true) {
          print(
              'Authentication successful, loading user data at ${DateTime.now()}');
          salesProvider.loadUserData();
          return const MainScreen();
        }
        print(
            'Authentication failed or no data, showing login at ${DateTime.now()}');
        return const LoginScreen();
      },
    );
  }
}