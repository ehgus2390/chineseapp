import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECF9F1), Color(0xFFF7F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '어서오세요! 새로운 인연을 만나보세요',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '간단히 로그인하고 주변 친구들과 대화를 시작하세요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  auth.isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('로그인하고 시작하기'),
                            onPressed: () async {
                              final success = await auth.signInAnonymously();
                              if (!success) {
                                final message = auth.lastError ?? '로그인에 실패했습니다. Firebase 구성을 확인해주세요.';
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(message)));
                                }
                              }
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
