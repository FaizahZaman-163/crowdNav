import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'reset_password_page.dart';
import '../pages/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFECF0F1),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            ),
          );
        }

        final event = snapshot.data?.event;
        final session = snapshot.data?.session;

        // User opened the app via the password-reset email link
        if (event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordPage();
        }

        if (session != null) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}