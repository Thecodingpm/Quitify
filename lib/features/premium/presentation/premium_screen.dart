import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/premium_service.dart';
import '../../../core/theme/app_theme.dart';
import '../application/premium_controller.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);
    final controller = ref.read(premiumControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Premium'),
        actions: [
          TextButton(
            onPressed: state.isProcessing ? null : controller.restore,
            child: const Text('Restore'),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _GlassBackground(),
          if (state.isActive)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: Text('🎉🎊✨', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppColors.primaryDark,
                    onRefresh: () async => controller.restore(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        const _HeroGlass(),
                        const SizedBox(height: 14),
                        _PlanSelector(
                          plans: state.plans,
                          selectedPlanId: state.selectedPlanId,
                          onSelect: controller.selectPlan,
                        ),
                        const SizedBox(height: 14),
                        _PrimaryCta(
                          isActive: state.isActive,
                          isProcessing: state.isProcessing,
                          priceLabel: state.selectedPlan?.price ?? 'Premium',
                          onPressed: controller.startPurchase,
                          onRedeemCode: () => _showRedeemDialog(context, controller),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 8),
                          _ErrorBanner(message: state.error!),
                        ],
                        const SizedBox(height: 16),
                        _FeatureGlass(
                          title: 'Included in Free',
                          chipsColor: Colors.white,
                          items: const [
                            'Smoke-free timer',
                            'Money saved tracker',
                            'Basic stats',
                            'Craving timer',
                            'Basic achievements',
                          ],
                          accentIcon: Icons.lock_open,
                        ),
                        const SizedBox(height: 14),
                        _FeatureGlass(
                          title: 'Everything in Premium',
                          chipsColor: AppColors.primary.withValues(alpha: 0.12),
                          accentIcon: Icons.workspace_premium,
                          trailing: _AnimatedRail(),
                          items: const [
                            'AI quit coach chatbot',
                            'Advanced analytics',
                            'Craving prediction system',
                            'Deep breathing meditation library',
                            'Personalized quit plans',
                            'Health recovery timeline',
                            'Custom motivation reminders',
                            'Ad-free experience',
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SmokeCard(),
                        const SizedBox(height: 14),
                        _ValueRow(),
                        const SizedBox(height: 12),
                        Text(
                          'Cancel anytime. Subscriptions auto-renew until canceled. Prices shown are placeholders; replace with store pricing.',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, PremiumController controller) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter promo code'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            hintText: 'Promo code',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final success = controller.activateWithCode(codeController.text.trim());
              Navigator.of(ctx).pop();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 Premium activated!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid code. Try again.')),
                );
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}

class _GlassBackground extends StatelessWidget {
  const _GlassBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFeaf8f1), Color(0xFFD7F2E3), Colors.white],
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -40,
          child: _FrostedBlob(color: AppColors.primary.withValues(alpha: 0.25), size: 220),
        ),
        Positioned(
          bottom: -60,
          right: -30,
          child: _FrostedBlob(color: AppColors.primaryDark.withValues(alpha: 0.2), size: 200),
        ),
      ],
    );
  }
}

class _FrostedBlob extends StatelessWidget {
  const _FrostedBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: size,
          width: size,
          color: color,
        ),
      ),
    );
  }
}

class _HeroGlass extends StatelessWidget {
  const _HeroGlass();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unlock the calm, stay smoke-free', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Premium coaching, predictive cravings, and serene breathing rooms to keep you steady.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _TagChip(icon: Icons.auto_awesome, label: 'AI coach'),
                        _TagChip(icon: Icons.bolt, label: 'Streak fire'),
                        _TagChip(icon: Icons.spa, label: 'Guided breath'),
                        _TagChip(icon: Icons.shield, label: 'Ad-free focus'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa, size: 56, color: AppColors.primaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({required this.plans, required this.selectedPlanId, required this.onSelect});

  final List<PricingPlan> plans;
  final String? selectedPlanId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const _GlassCard(child: Center(child: Text('Plans unavailable right now.')));
    }

    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.workspace_premium, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text('Choose your plan', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: plans
                .map(
                  (plan) => _PlanPill(
                    plan: plan,
                    selected: plan.id == selectedPlanId,
                    onTap: () => onSelect(plan.id),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.plan, required this.selected, required this.onTap});

  final PricingPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF5EE4A7), Color(0xFF2ECC71)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(plan.bestValue ? Icons.auto_awesome : Icons.av_timer, color: selected ? Colors.white : AppColors.primaryDark),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(plan.title, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textPrimary)),
                    if (plan.bestValue)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Best value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.primaryDark)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(plan.price, style: TextStyle(color: selected ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.isActive, required this.isProcessing, required this.priceLabel, required this.onPressed, required this.onRedeemCode});

  final bool isActive;
  final bool isProcessing;
  final String priceLabel;
  final VoidCallback onPressed;
  final VoidCallback onRedeemCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isActive || isProcessing ? null : onPressed,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1FAA59), Color(0xFF2ECC71)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: isActive
                    ? const Text('You are Premium ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))
                    : isProcessing
                        ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6))
                        : Text('Continue • $priceLabel', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
        if (!isActive) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: isProcessing ? null : onRedeemCode,
            child: const Text('Have a promo code?', style: TextStyle(color: AppColors.primaryDark)),
          ),
        ],
      ],
    );
  }
}

class _FeatureGlass extends StatelessWidget {
  const _FeatureGlass({required this.title, required this.items, required this.chipsColor, required this.accentIcon, this.trailing});

  final String title;
  final List<String> items;
  final Color chipsColor;
  final IconData accentIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(accentIcon, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: chipsColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, color: AppColors.primaryDark, size: 16),
                        const SizedBox(width: 6),
                        Text(item, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SmokeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.spa, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Expanded(child: Text('Guided calm pack', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _TagChip(icon: Icons.masks, label: 'Smoke dissolving'),
                    SizedBox(height: 8),
                    _TagChip(icon: Icons.local_fire_department, label: 'Fire streak'),
                    SizedBox(height: 8),
                    _TagChip(icon: Icons.savings, label: 'Money tree'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.self_improvement, size: 64, color: AppColors.primaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _MiniIconCard(title: 'Fire streak', icon: Icons.local_fire_department, color: Colors.orange)),
        SizedBox(width: 10),
        Expanded(child: _MiniIconCard(title: 'Money tree', icon: Icons.park, color: Colors.green)),
        SizedBox(width: 10),
        Expanded(child: _MiniIconCard(title: 'Crush cravings', icon: Icons.shield, color: Colors.teal)),
      ],
    );
  }
}

class _MiniIconCard extends StatelessWidget {
  const _MiniIconCard({required this.title, required this.icon, required this.color});

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SizedBox(
            height: 90,
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedRail extends StatefulWidget {
  @override
  State<_AnimatedRail> createState() => _AnimatedRailState();
}

class _AnimatedRailState extends State<_AnimatedRail> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    return SizedBox(
      height: 48,
      width: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final value = _controller.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15 + 0.25 * value),
                  AppColors.primaryDark.withValues(alpha: 0.15 + 0.25 * (1 - value)),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}
