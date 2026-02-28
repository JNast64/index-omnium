// lib/features/auth/sign_up_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  /// When true → "Sign in" screen.
  /// When false → "Sign up" screen.
  final bool showLogin;

  const SignUpPage({super.key, this.showLogin = false});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = AuthService.instance;
    final email = _email.text.trim();
    final password = _password.text;

    String? err;

    if (widget.showLogin) {
      // LOGIN
      err = await auth.signIn(email: email, password: password);
    } else {
      // SIGN UP
      if (password != _confirm.text) {
        err = 'Passwords do not match';
      } else {
        err = await auth.signUp(email: email, password: password);
      }
    }

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _error = err;
        _loading = false;
      });
    } else {
      // Success → go to home
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.showLogin;
    final title =
        isLogin ? 'Sign in to Index Omnium' : 'Sign up for Index Omnium';
    final primaryLabel = isLogin ? 'Sign in' : 'Create account';

    final toggleText = isLogin
        ? 'Need an account? Sign up'
        : 'Already have an account? Sign in';

    final toggleRoute = isLogin ? '/signup' : '/login';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    isLogin ? 'Welcome back' : 'Create account',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),

                  // Email
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (min 6 chars)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm password only on sign-up
                  if (!isLogin) ...[
                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(primaryLabel),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () => context.go(toggleRoute),
                      child: Text(toggleText),
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
