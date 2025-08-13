import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readyping_app/providers/auth_provider.dart';
import 'package:readyping_app/providers/order_provider.dart';
import 'package:readyping_app/screens/login_screen.dart';
import 'package:readyping_app/screens/dashboard_screen.dart';
import 'package:readyping_app/theme/app_theme.dart';

void main() {
  runApp(const ReadyPingApp());
}

class ReadyPingApp extends StatelessWidget {
  const ReadyPingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'ReadyPing',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
