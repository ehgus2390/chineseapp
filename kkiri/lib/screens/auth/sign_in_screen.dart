import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.person),
          label: const Text('익명 로그인'),
          onPressed: auth.isLoading ? null : () async {
            await auth.signInAnonymously();
          },
        ),
      ),
    );
  }
}
