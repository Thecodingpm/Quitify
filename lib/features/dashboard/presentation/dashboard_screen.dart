import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../data/progress_repository.dart';
import '../domain/quit_stats.dart';

final quitStatsProvider = StreamProvider<QuitStats>((ref) {
  final auth = ref.watch(authStateChangesProvider);
  return auth.maybeWhen(
    data: (user) {
      if (user == null) return Stream.value(QuitStats.placeholder());
      return ref.watch(progressRepositoryProvider).watchStats(user.uid);
    },
    orElse: () => const Stream.empty(),
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(quitStatsProvider);
    final user = ref.watch(authStateChangesProvider).maybeWhen(data: (u) => u, orElse: () => null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quitify'),
        actions: [
          IconButton(
            onPressed: () => context.push('/premium'),
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
          IconButton(
            onPressed: () => context.push('/analytics'),
            icon: const Icon(Icons.auto_graph_outlined),
          ),
          if (user != null)
            IconButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  context.go('/auth');
                }
              },
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Sign out',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: stats.when(
          data: (value) => _DashboardBody(stats: value),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Unable to load stats: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (user == null) {
            context.go('/auth');
            return;
          }
          await ref.read(progressRepositoryProvider).recordCheckIn(uid: user.uid);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Daily check-in logged. Keep going!')),
            );
          }
        },
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Daily check-in'),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.stats});

  final QuitStats stats;

  String _lifeRegained() {
    final minutes = stats.cigarettesAvoided * 11; // rough average minutes regained per cigarette not smoked
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours hr';
    final days = hours ~/ 24;
    return '$days d';
  }

  double _streakScale() {
    final streak = stats.streakDays;
    if (streak <= 1) return 1.0;
    if (streak <= 7) return 1.1;
    if (streak <= 30) return 1.2;
    if (streak <= 90) return 1.3;
    return 1.4;
  }

  List<_Achievement> _achievements() {
    final days = stats.daysSmokeFree;
    return const [
      _Achievement(label: '1 day', target: 1),
      _Achievement(label: '7 days', target: 7),
      _Achievement(label: '30 days', target: 30),
      _Achievement(label: '90 days', target: 90),
      _Achievement(label: '1 year', target: 365),
    ].map((a) => a.copyWith(unlocked: days >= a.target)).toList();
  }

  double _jarFill() {
    return (stats.cigarettesAvoided / 120).clamp(0, 1); // assume 120 as visual capacity
  }

  int _treeStage() {
    final saved = stats.moneySaved;
    if (saved < 50) return 1;
    if (saved < 200) return 2;
    return 3;
  }

  String _timerLabel() {
    final days = stats.daysSmokeFree;
    final hours = (stats.daysSmokeFree * 24) % 24; // placeholder until precise quit timestamp is added
    return '${days}d ${hours}h';
  }

  int _lungStage() {
    if (stats.daysSmokeFree < 3) return 1;
    if (stats.daysSmokeFree < 14) return 2;
    return 3;
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateChangesProvider).maybeWhen(data: (u) => u, orElse: () => null);

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Smoke-free timer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _HeroStat(label: 'Elapsed', value: _timerLabel()),
                  const SizedBox(width: 12),
                  _HeroStat(label: 'Streak', value: '${stats.streakDays} days'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Your recovery', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _LungRecoveryWidget(key: ValueKey(_lungStage()), stage: _lungStage()),
              ),
              const SizedBox(height: 10),
              Text(
                _lungStage() == 1
                    ? 'Lungs are stabilizing—keep hydration high.'
                    : _lungStage() == 2
                        ? 'Healing underway—oxygen levels rising.'
                        : 'Healthy path—circulation and breath improving.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Craving SOS', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Ride out cravings with a 5-min plan, breathing guide, and a quick distraction game.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: user == null
                      ? () => context.go('/auth')
                      : () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) => CravingSupportSheet(userId: user.uid),
                          ),
                  icon: const Icon(Icons.self_improvement),
                  label: const Text('Start 5-min support'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Streak fire', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: _streakScale(),
                child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 48),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Streak heat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('${stats.streakDays} days in a row', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Achievements', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _achievements()
              .map(
                (a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: a.unlocked ? AppColors.primary.withValues(alpha: 0.14) : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: a.unlocked ? AppColors.primary : Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.unlocked ? Icons.verified : Icons.lock_outline, size: 18, color: a.unlocked ? AppColors.primaryDark : Colors.grey),
                      const SizedBox(width: 6),
                      Text(a.label, style: theme.textTheme.bodyMedium?.copyWith(color: a.unlocked ? AppColors.primaryDark : Colors.grey)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text('Impact today', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(label: 'Cigs avoided', value: stats.cigarettesAvoided.toString(), icon: Icons.block),
            _StatCard(label: 'Money saved', value: '\$${stats.moneySaved.toStringAsFixed(0)}', icon: Icons.savings_outlined),
            _StatCard(label: 'Life regained', value: _lifeRegained(), icon: Icons.favorite),
            _StatCard(label: 'Cravings beaten', value: stats.cravingsResisted.toString(), icon: Icons.shield_moon_outlined),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next best action', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Log a craving, start a 5-min breathwork, or schedule a reminder to refill nicotine replacement.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/premium'),
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('Unlock premium coaching'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Cigarette jar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _CigaretteJarWidget(fill: _jarFill(), avoided: stats.cigarettesAvoided),
        const SizedBox(height: 16),
        Text('Money tree', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _MoneyTreeWidget(saved: stats.moneySaved, stage: _treeStage()),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  const _Achievement({required this.label, required this.target, this.unlocked = false});

  final String label;
  final int target;
  final bool unlocked;

  _Achievement copyWith({bool? unlocked}) => _Achievement(label: label, target: target, unlocked: unlocked ?? this.unlocked);
}

class CravingSupportSheet extends ConsumerStatefulWidget {
  const CravingSupportSheet({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<CravingSupportSheet> createState() => _CravingSupportSheetState();
}

class _CravingSupportSheetState extends ConsumerState<CravingSupportSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  Timer? _countdownTimer;
  int _remainingSeconds = 300;
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _startCountdown();
    _logCraving();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  Future<void> _logCraving() async {
    if (_logged) return;
    _logged = true;
    await ref.read(progressRepositoryProvider).recordCraving(uid: widget.userId);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  double get _countdownProgress => _remainingSeconds / 300;

  String get _timeLabel {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _breathLabel(double value) {
    final seconds = value * 14;
    if (seconds < 4) return 'Inhale 4s';
    if (seconds < 8) return 'Hold 4s';
    return 'Exhale 6s';
  }

  double _breathScale(double value) {
    final seconds = value * 14;
    if (seconds < 4) {
      return 0.75 + (seconds / 4) * 0.35; // grow
    }
    if (seconds < 8) {
      return 1.1; // hold
    }
    final t = (seconds - 8) / 6;
    return 1.1 - t * 0.4; // shrink
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Craving support', style: theme.textTheme.titleLarge),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 6),
            Text('5-minute plan to ride it out. Stay with your breath and tap the game to break the urge.', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Countdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(_timeLabel, style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: _countdownProgress,
                      minHeight: 10,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Breathing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Center(
                    child: AnimatedBuilder(
                      animation: _breathController,
                      builder: (_, __) {
                        final scale = _breathScale(_breathController.value);
                        final label = _breathLabel(_breathController.value);
                        return Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    height: 90,
                                    width: 90,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(label, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            const Text('Inhale 4s · Hold 4s · Exhale 6s'),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coping tips', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const _TipRow(text: 'Drink cold water slowly'),
                  const _TipRow(text: 'Box breathing 4-4-6'),
                  const _TipRow(text: '2-minute brisk walk'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mini game: tap to break cigarettes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const CravingGame(),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
            child: const Icon(Icons.check, size: 14, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class CravingGame extends StatefulWidget {
  const CravingGame({super.key});

  @override
  State<CravingGame> createState() => _CravingGameState();
}

class _CravingGameState extends State<CravingGame> {
  late List<bool> _destroyed;

  @override
  void initState() {
    super.initState();
    _destroyed = List<bool>.filled(6, false);
  }

  int get _remaining => _destroyed.where((d) => !d).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tap to smash cravings ($_remaining left)', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_destroyed.length, (index) {
            final gone = _destroyed[index];
            return GestureDetector(
              onTap: gone
                  ? null
                  : () => setState(() {
                        _destroyed[index] = true;
                      }),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: gone ? 0.35 : 1,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: gone ? 0.85 : 1,
                  child: Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: gone ? AppColors.surface : AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(
                      gone ? Icons.check_circle_outline : Icons.smoking_rooms,
                      color: gone ? AppColors.primaryDark : AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// --- Custom visual widgets replacing broken Lottie animations ---

class _LungRecoveryWidget extends StatefulWidget {
  const _LungRecoveryWidget({super.key, required this.stage});
  final int stage;

  @override
  State<_LungRecoveryWidget> createState() => _LungRecoveryWidgetState();
}

class _LungRecoveryWidgetState extends State<_LungRecoveryWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.stage == 1
        ? Colors.grey.shade400
        : widget.stage == 2
            ? Colors.teal.shade300
            : AppColors.primary;

    final bgColor = widget.stage == 1
        ? Colors.grey.shade100
        : widget.stage == 2
            ? Colors.teal.shade50
            : AppColors.primary.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.9 + (_controller.value * 0.15);
        return SizedBox(
          height: 200,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.air, size: 72, color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CigaretteJarWidget extends StatelessWidget {
  const _CigaretteJarWidget({required this.fill, required this.avoided});
  final double fill;
  final int avoided;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Jar outline
                Container(
                  width: 120,
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.grey.shade400, width: 2.5),
                  ),
                ),
                // Jar lid
                Positioned(
                  top: 0,
                  child: Container(
                    width: 130,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                // Fill level
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  width: 115,
                  height: 165 * fill,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // Cigarette icons inside the jar
                if (avoided > 0)
                  Positioned(
                    bottom: 10,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        avoided.clamp(0, 12),
                        (i) => Icon(Icons.smoke_free, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                  ),
                // Count label
                Positioned(
                  bottom: avoided > 3 ? 40 : 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$avoided avoided',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(fill * 100).round()}% full · Goal: 120 cigarettes avoided',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _MoneyTreeWidget extends StatelessWidget {
  const _MoneyTreeWidget({required this.saved, required this.stage});
  final double saved;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final treeSize = 60.0 + (stage * 25.0);
    final leafCount = stage * 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text('Money saved: \$${saved.toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Ground
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 160,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Trunk
                Positioned(
                  bottom: 12,
                  child: Container(
                    width: 12,
                    height: treeSize * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Tree canopy
                Positioned(
                  bottom: 12 + treeSize * 0.35,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    width: treeSize,
                    height: treeSize,
                    decoration: BoxDecoration(
                      color: stage >= 3 ? Colors.green.shade600 : stage >= 2 ? Colors.green.shade400 : Colors.green.shade200,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.park, size: treeSize * 0.5, color: Colors.white),
                    ),
                  ),
                ),
                // Dollar leaves
                ...List.generate(leafCount, (i) {
                  final radius = treeSize * 0.45;
                  return Positioned(
                    bottom: 12 + treeSize * 0.35 + treeSize * 0.5 + (radius * 0.7 * (i.isEven ? 1 : -0.5)),
                    left: MediaQuery.of(context).size.width * 0.5 - 40 + (radius * 0.8 * (i % 3 == 0 ? -1 : 1)),
                    child: Text('💵', style: TextStyle(fontSize: 14 + (stage * 2).toDouble())),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stage < 3 ? 'Tree grows as savings grow. Next bloom at \$${stage == 1 ? 50 : 200}.' : '🌳 Fully bloomed! You\'re saving big!',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
