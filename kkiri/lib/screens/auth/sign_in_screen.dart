import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _isLoginMode = true;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kkiri 로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _pwCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: appState.isLoading
                  ? null
                  : () async {
                final email = _emailCtrl.text.trim();
                final pw = _pwCtrl.text.trim();
                if (email.isEmpty || pw.isEmpty) return;

                try {
                  if (_isLoginMode) {
                    await appState.signInWithEmail(email, pw);
                  } else {
                    await appState.registerWithEmail(email, pw);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류: $e')),
                  );
                }
              },
              child: Text(_isLoginMode ? '로그인' : '회원가입'),
            ),
            TextButton(
              onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
              child: Text(_isLoginMode ? '회원가입하기' : '이미 계정이 있어요'),
            ),
          ],
        ),
      ),
    );
  }
}
