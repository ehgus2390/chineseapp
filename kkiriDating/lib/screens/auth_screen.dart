import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'package:kkiri/l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final verifyEmailCtrl = TextEditingController();
  final verifyPasswordCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final smsCtrl = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;
  String? _error;
  String? _verificationMethod; // 'phone' | 'email'
  bool _verificationComplete = false;
  bool _verificationBusy = false;
  bool _verificationEmailSent = false;
  String? _verificationId;
  bool _verificationMetadataSaved = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    verifyEmailCtrl.dispose();
    verifyPasswordCtrl.dispose();
    phoneCtrl.dispose();
    smsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = emailCtrl.text.trim();
      final password = passwordCtrl.text;
      if (email.isEmpty || password.isEmpty) {
        throw StateError('empty');
      }
      final state = context.read<AppState>();
      if (_isLogin) {
        await state.signInWithEmail(email, password);
      } else {
        if (!_verificationComplete) {
          throw StateError('verification_required');
        }
        // After verification, complete sign-up using the selected method.
        if (_verificationMethod == 'email') {
          await state.signInWithEmail(email, password);
        } else {
          await state.registerWithEmail(email, password);
        }
        await _persistVerificationMetadata(_verificationMethod ?? 'email');
        state.setAuthFlowInProgress(false);
      }
    } catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _persistVerificationMetadata(String method) async {
    if (_verificationMetadataSaved) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'authMethod': method,
      'verifiedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _verificationMetadataSaved = true;
  }

  String _friendlyAuthError(Object error) {
    final l = AppLocalizations.of(context)!;
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return l.authErrorInvalidEmail;
        case 'email-already-in-use':
          return l.authErrorEmailInUse;
        case 'wrong-password':
          return l.authErrorWrongPassword;
        case 'user-not-found':
          return l.authErrorUserNotFound;
        case 'too-many-requests':
          return l.authErrorTooManyRequests;
        case 'invalid-verification-code':
          return l.authErrorInvalidVerificationCode;
        case 'invalid-verification-id':
          return l.authErrorInvalidVerificationId;
        default:
          return l.authErrorVerificationFailed;
      }
    }
    if (error is StateError && error.message == 'verification_required') {
      return l.authErrorVerificationRequired;
    }
    if (error is StateError && error.message == 'empty') {
      return l.authErrorEmptyEmailPassword;
    }
    if (error is StateError && error.message == 'phone_empty') {
      return l.authErrorPhoneEmpty;
    }
    if (error is StateError && error.message == 'code_empty') {
      return l.authErrorCodeEmpty;
    }
    return l.authErrorGeneric;
  }

  void _resetVerificationState() {
    _verificationMethod = null;
    _verificationComplete = false;
    _verificationBusy = false;
    _verificationEmailSent = false;
    _verificationId = null;
    _verificationMetadataSaved = false;
    verifyEmailCtrl.clear();
    verifyPasswordCtrl.clear();
    phoneCtrl.clear();
    smsCtrl.clear();
  }

  Future<void> _startPhoneVerification() async {
    final phone = phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = _friendlyAuthError(StateError('phone_empty')));
      return;
    }
    setState(() {
      _verificationBusy = true;
      _error = null;
    });
    context.read<AppState>().setAuthFlowInProgress(true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() {
            _verificationComplete = true;
            _verificationMethod = 'phone';
          });
        } finally {
          if (mounted) setState(() => _verificationBusy = false);
        }
      },
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() {
          _error = _friendlyAuthError(e);
          _verificationBusy = false;
        });
      },
      codeSent: (verificationId, _) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _verificationBusy = false;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _confirmPhoneCode() async {
    final code = smsCtrl.text.trim();
    if (_verificationId == null || code.isEmpty) {
      setState(() => _error = _friendlyAuthError(StateError('code_empty')));
      return;
    }
    setState(() {
      _verificationBusy = true;
      _error = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _verificationComplete = true;
        _verificationMethod = 'phone';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _verificationBusy = false);
    }
  }

  Future<void> _sendEmailVerification() async {
    final email = verifyEmailCtrl.text.trim();
    final password = verifyPasswordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = _friendlyAuthError(StateError('empty')));
      return;
    }
    setState(() {
      _verificationBusy = true;
      _error = null;
    });
    context.read<AppState>().setAuthFlowInProgress(true);
    try {
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCred.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _verificationEmailSent = true;
        _verificationMethod = 'email';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _verificationBusy = false);
    }
  }

  Future<void> _checkEmailVerified() async {
    final email = verifyEmailCtrl.text.trim();
    final password = verifyPasswordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = _friendlyAuthError(StateError('empty')));
      return;
    }
    setState(() {
      _verificationBusy = true;
      _error = null;
    });
    context.read<AppState>().setAuthFlowInProgress(true);
    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCred.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        if (!mounted) return;
        setState(() {
          _verificationComplete = true;
          _verificationMethod = 'email';
          emailCtrl.text = email;
          passwordCtrl.text = password;
        });
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _verificationBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.loginTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.loginSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (!_isLogin) ...[
                Text(
                  l.authVerifyIntro,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _verificationBusy
                            ? null
                            : () => setState(() {
                                _verificationMethod = 'phone';
                              }),
                        child: Text(
                          l.authVerifyPhoneButton,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _verificationBusy
                            ? null
                            : () => setState(() {
                                _verificationMethod = 'email';
                              }),
                        child: Text(
                          l.authVerifyEmailButton,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_verificationMethod == 'phone') ...[
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l.authPhoneLabel),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _verificationBusy
                          ? null
                          : _startPhoneVerification,
                      child: _verificationBusy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.authSendCode),
                    ),
                  ),
                  if (_verificationId != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: smsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l.authCodeLabel),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _verificationBusy ? null : _confirmPhoneCode,
                        child: _verificationBusy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l.authVerifyCompleteButton),
                      ),
                    ),
                  ],
                ],
                if (_verificationMethod == 'email') ...[
                  TextField(
                    controller: verifyEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l.email),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: verifyPasswordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l.password),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _verificationBusy
                          ? null
                          : _sendEmailVerification,
                      child: _verificationBusy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.authSendEmailVerification),
                    ),
                  ),
                  if (_verificationEmailSent) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _verificationBusy
                            ? null
                            : _checkEmailVerified,
                        child: Text(l.authCheckEmailVerified),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
              ],
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l.email),
                enabled: _isLogin || _verificationComplete,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l.password),
                enabled: _isLogin || _verificationComplete,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy || (!_isLogin && !_verificationComplete)
                      ? null
                      : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLogin ? l.signIn : l.signUp),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _error = null;
                          if (_isLogin) {
                            _resetVerificationState();
                            context.read<AppState>().setAuthFlowInProgress(
                              false,
                            );
                          } else {
                            _resetVerificationState();
                            context.read<AppState>().setAuthFlowInProgress(
                              true,
                            );
                          }
                        });
                      },
                child: Text(_isLogin ? l.needAccount : l.haveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

