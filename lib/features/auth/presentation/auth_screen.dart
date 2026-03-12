import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _cigsPerDay = TextEditingController();
  final _packPrice = TextEditingController();
  final _yearsSmoking = TextEditingController();
  final _reason = TextEditingController();
  DateTime? _quitDate;
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _cigsPerDay.dispose();
    _packPrice.dispose();
    _yearsSmoking.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isSignUp) {
        await auth.signUp(
          email: _email.text.trim(),
          password: _password.text.trim(),
          name: _name.text.trim(),
          quitDate: _quitDate,
          cigarettesPerDay: _intOrNull(_cigsPerDay.text),
          packPrice: _doubleOrNull(_packPrice.text),
          yearsSmoking: _doubleOrNull(_yearsSmoking.text),
          reasonForQuitting: _reason.text.trim(),
        );
      } else {
        await auth.signIn(email: _email.text.trim(), password: _password.text.trim());
      }
      if (!mounted) return;
      context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Authentication failed.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _loading = true);
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    if (!Platform.isIOS) return;
    try {
      setState(() => _loading = true);
      await ref.read(authRepositoryProvider).signInWithApple();
      if (mounted) context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Apple sign-in failed.');
    } catch (e) {
      setState(() => _error = 'Apple sign-in failed. Make sure Sign in with Apple is enabled in Xcode capabilities.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_email.text.isEmpty) {
      setState(() => _error = 'Enter your email to reset password.');
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Unable to send reset email.');
    }
  }

  int? _intOrNull(String value) => int.tryParse(value.isEmpty ? '0' : value);
  double? _doubleOrNull(String value) => double.tryParse(value.isEmpty ? '0' : value);

  Future<void> _pickQuitDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _quitDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _quitDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Create account' : 'Welcome back')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSignUp ? 'Build your quit plan in minutes.' : 'Sign in to track your streaks.',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            if (_isSignUp) ...[
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickQuitDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Quit date',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _quitDate != null
                        ? '${_quitDate!.year}-${_quitDate!.month.toString().padLeft(2, '0')}-${_quitDate!.day.toString().padLeft(2, '0')}'
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cigsPerDay,
                      decoration: const InputDecoration(labelText: 'Cigarettes/day'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _packPrice,
                      decoration: const InputDecoration(labelText: 'Pack price (local)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yearsSmoking,
                decoration: const InputDecoration(labelText: 'Years smoking'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reason,
                decoration: const InputDecoration(labelText: 'Reason for quitting'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _resetPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_isSignUp ? 'Create account' : 'Sign in'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp ? 'Have an account? Sign in' : 'Need an account? Sign up'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('or continue with'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 22),
                    label: const Text('Google'),
                  ),
                ),
                if (Platform.isIOS) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _signInWithApple,
                      icon: const Icon(Icons.apple, size: 22),
                      label: const Text('Apple'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _BenefitList(),
          ],
        ),
      ),
    );
  }
}

class _BenefitList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      'Micro-actions to beat cravings',
      'Money and time saved visualizers',
      'Push reminders for check-ins',
      'Premium coaching and SOS tools',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: AppColors.primaryDark, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
