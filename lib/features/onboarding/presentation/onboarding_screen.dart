import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../data/onboarding_repository.dart';

final onboardingControllerProvider = AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends AsyncNotifier<bool> {
  static const _prefKey = 'onboarding_completed';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    state = const AsyncData(true);
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  final _cigsPerDay = TextEditingController();
  final _packPrice = TextEditingController();
  final _yearsSmoking = TextEditingController();
  final _reason = TextEditingController();
  DateTime? _quitDate;

  int _index = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pageController.dispose();
    _cigsPerDay.dispose();
    _packPrice.dispose();
    _yearsSmoking.dispose();
    _reason.dispose();
    super.dispose();
  }

  double get _progress => (_index + 1) / 4;

  Future<void> _next() async {
    if (_index < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final info = OnboardingInfo(
        cigarettesPerDay: int.parse(_cigsPerDay.text),
        packPrice: double.parse(_packPrice.text),
        yearsSmoking: double.parse(_yearsSmoking.text),
        quitDate: _quitDate,
        reason: _reason.text.trim(),
      );

      await ref.read(onboardingRepositoryProvider).saveInfo(info);
      await ref.read(onboardingControllerProvider.notifier).markCompleted();

      final user = ref.read(authStateChangesProvider).maybeWhen(data: (u) => u, orElse: () => null);
      if (!mounted) return;
      context.go(user != null ? '/dashboard' : '/auth');
    } catch (e) {
      setState(() => _error = 'Could not save your plan. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _progress),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(_progress * 100).round()}%', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _WelcomeSlide(),
                  const _BenefitSlide(),
                  const _LungRecoverySlide(),
                  _FormSlide(
                    formKey: _formKey,
                    cigsPerDay: _cigsPerDay,
                    packPrice: _packPrice,
                    yearsSmoking: _yearsSmoking,
                    reason: _reason,
                    quitDate: _quitDate,
                    onPickDate: _pickQuitDate,
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_index > 0)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                              ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _saving ? null : _next,
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_index == 3 ? 'Save and continue' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network('https://assets1.lottiefiles.com/packages/lf20_J1Zla1wQ7a.json', height: 240),
          const SizedBox(height: 22),
          Text('Welcome to Quitify', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Your calm, science-backed companion to stay smoke-free with coaching, reminders, and visualization.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BenefitSlide extends StatelessWidget {
  const _BenefitSlide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final benefits = [
      'Track streaks, money saved, and cravings beaten',
      'Gentle reminders to stay accountable',
      'SOS toolkit when cravings hit',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network('https://assets5.lottiefiles.com/packages/lf20_xlkxtmul.json', height: 230),
          const SizedBox(height: 18),
          Text('Why you will love this', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: AppColors.primaryDark, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LungRecoverySlide extends StatelessWidget {
  const _LungRecoverySlide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network('https://assets1.lottiefiles.com/packages/lf20_lxqtk0kz.json', height: 260),
          const SizedBox(height: 18),
          Text('Watch your lungs recover', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Every smoke-free day boosts circulation, improves breath, and rewires cravings. We will visualize it for you.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FormSlide extends StatelessWidget {
  const _FormSlide({
    required this.formKey,
    required this.cigsPerDay,
    required this.packPrice,
    required this.yearsSmoking,
    required this.reason,
    required this.quitDate,
    required this.onPickDate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController cigsPerDay;
  final TextEditingController packPrice;
  final TextEditingController yearsSmoking;
  final TextEditingController reason;
  final DateTime? quitDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your quit profile', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('We use this to personalize your streaks and savings. You can change it later.', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: cigsPerDay,
                    decoration: const InputDecoration(labelText: 'Cigarettes per day'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: packPrice,
                    decoration: const InputDecoration(labelText: 'Pack price'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: yearsSmoking,
              decoration: const InputDecoration(labelText: 'Years smoking'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onPickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Quit date',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  quitDate != null
                      ? '${quitDate!.year}-${quitDate!.month.toString().padLeft(2, '0')}-${quitDate!.day.toString().padLeft(2, '0')}'
                      : 'Select date',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Reason for quitting'),
              maxLines: 3,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
