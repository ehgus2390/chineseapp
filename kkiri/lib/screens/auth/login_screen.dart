// lib/screens/auth/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔴 핵심: alias 사용
import '../../providers/auth_provider.dart' as app_auth;
import '../../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final appState = context.read<AppState>();
      if (_isLoginMode) {
        await appState.signInWithEmail(email, password);
      } else {
        await appState.registerWithEmail(email, password);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kkiri에 오신 것을 환영합니다',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              /// ✅ 익명 로그인 (충돌 해결된 부분)
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                  setState(() => _isSubmitting = true);
                  try {
                    await context
                        .read<app_auth.AuthProvider>()
                        .signInAnonymously();
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('익명으로 시작하기'),
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                '나중에 프로필에서 이메일 인증을 완료하면 1:1 채팅을 이용할 수 있습니다.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade400),
              const SizedBox(height: 16),

              Text(
                _isLoginMode ? '이메일로 로그인' : '이메일로 계정 만들기',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(_isLoginMode ? 'Login' : 'Sign up'),
                ),
              ),

              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(
                  _isLoginMode
                      ? 'New here? Create an account'
                      : 'Already have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
