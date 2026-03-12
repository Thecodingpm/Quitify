import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  void _maybeNavigate(AsyncValue<bool> onboardingState, AsyncValue<User?> authState) {
    if (_navigated) return;
    if (onboardingState.isLoading || authState.isLoading) return;

    final onboardingDone = onboardingState.value ?? false;
    final user = authState.value;

    final target = onboardingDone
        ? (user != null ? '/dashboard' : '/auth')
        : '/onboarding';

    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.watch() so the widget rebuilds when the async providers complete.
    final onboardingState = ref.watch(onboardingControllerProvider);
    final authState = ref.watch(authStateChangesProvider);

    _maybeNavigate(onboardingState, authState);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Preparing your quit plan...'),
          ],
        ),
      ),
    );
  }
}
