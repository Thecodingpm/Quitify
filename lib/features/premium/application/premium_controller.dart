import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/premium_service.dart';

class PremiumState {
  const PremiumState({
    required this.isLoading,
    required this.isActive,
    required this.isProcessing,
    required this.plans,
    required this.selectedPlanId,
    this.error,
  });

  final bool isLoading;
  final bool isActive;
  final bool isProcessing;
  final List<PricingPlan> plans;
  final String? selectedPlanId;
  final String? error;

  PricingPlan? get selectedPlan {
    if (plans.isEmpty) return null;
    return plans.firstWhere(
      (p) => p.id == selectedPlanId,
      orElse: () => plans.first,
    );
  }

  PremiumState copyWith({
    bool? isLoading,
    bool? isActive,
    bool? isProcessing,
    List<PricingPlan>? plans,
    String? selectedPlanId,
    String? error,
  }) {
    return PremiumState(
      isLoading: isLoading ?? this.isLoading,
      isActive: isActive ?? this.isActive,
      isProcessing: isProcessing ?? this.isProcessing,
      plans: plans ?? this.plans,
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
      error: error,
    );
  }

  static const initial = PremiumState(
    isLoading: true,
    isActive: false,
    isProcessing: false,
    plans: <PricingPlan>[],
    selectedPlanId: null,
  );
}

class PremiumController extends Notifier<PremiumState> {
  PremiumService get _service => ref.read(premiumServiceProvider);

  @override
  PremiumState build() {
    _init();
    return PremiumState.initial;
  }

  static const _productIds = {'quitify_monthly', 'quitify_yearly'};
  static const _prefsActiveKey = 'premium_active';
  static const _prefsPlanKey = 'premium_plan';

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  SharedPreferences? _prefs;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final cachedActive = prefs.getBool(_prefsActiveKey) ?? false;
    final cachedPlan = prefs.getString(_prefsPlanKey);

    final plans = await _service.loadPlans(_productIds);
    final selectedPlanId = cachedPlan ?? (plans.isNotEmpty ? plans.first.id : null);

    state = state.copyWith(
      isLoading: false,
      isActive: cachedActive,
      selectedPlanId: selectedPlanId,
      plans: plans,
    );

    _purchaseSub = _service.purchaseUpdates.listen(_handlePurchaseUpdates);
    ref.onDispose(() => _purchaseSub?.cancel());
  }

  void selectPlan(String planId) {
    state = state.copyWith(selectedPlanId: planId);
  }

  Future<void> startPurchase() async {
    final plan = state.selectedPlan;
    if (plan == null) return;
    state = state.copyWith(isProcessing: true, error: null);
    try {
      await _service.startPurchase(plan.id);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  Future<void> restore() async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      await _service.restorePurchases();
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> detailsList) async {
    for (final purchase in detailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(isProcessing: true);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _service.completePurchase(purchase);
          await _persistActive(purchase.productID);
          state = state.copyWith(
            isActive: true,
            isProcessing: false,
            error: null,
            selectedPlanId: purchase.productID,
          );
          break;
        case PurchaseStatus.error:
          state = state.copyWith(isProcessing: false, error: purchase.error?.message ?? 'Purchase failed');
          break;
        case PurchaseStatus.canceled:
          state = state.copyWith(isProcessing: false, error: 'Purchase canceled');
          break;
      }
    }
  }

  Future<void> _persistActive(String planId) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_prefsActiveKey, true);
    await prefs.setString(_prefsPlanKey, planId);
  }

  /// Test promo code to activate premium without a real purchase.
  /// Code: QUITIFY2026
  bool activateWithCode(String code) {
    if (code.toUpperCase() == 'QUITIFY2026') {
      _persistActive('promo_code');
      state = state.copyWith(
        isActive: true,
        isProcessing: false,
        error: null,
        selectedPlanId: 'promo_code',
      );
      return true;
    }
    return false;
  }

}

final premiumControllerProvider = NotifierProvider<PremiumController, PremiumState>(PremiumController.new);