import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PricingPlan {
  const PricingPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    this.bestValue = false,
  });

  final String id;
  final String title;
  final String price;
  final String description;
  final bool bestValue;

  static const fallbackPlans = <PricingPlan>[
    PricingPlan(
      id: 'quitify_monthly',
      title: 'Monthly',
      price: '\$5.99',
      description: 'Build momentum with reminders, streak boosts, and craving SOS.',
    ),
    PricingPlan(
      id: 'quitify_yearly',
      title: 'Yearly',
      price: '\$39.99',
      description: 'Unlock full support all year with 7-day free trial.',
      bestValue: true,
    ),
  ];
}

class PremiumService {
  PremiumService(this._iap);

  final InAppPurchase _iap;

  Stream<List<PurchaseDetails>> get purchaseUpdates => _iap.purchaseStream;

  Future<void> startPurchase(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      throw Exception('Product not found. Try again in a moment.');
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> completePurchase(PurchaseDetails details) async {
    if (details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
    }
  }

  Future<List<PricingPlan>> loadPlans(Set<String> productIds) async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      return PricingPlan.fallbackPlans;
    }

    final response = await _iap.queryProductDetails(productIds);
    if (response.notFoundIDs.isNotEmpty && response.productDetails.isEmpty) {
      return PricingPlan.fallbackPlans;
    }

    return response.productDetails
        .map(
          (product) => PricingPlan(
            id: product.id,
            title: product.title,
            price: product.price,
            description: product.description,
            bestValue: product.id.toLowerCase().contains('year'),
          ),
        )
        .toList();
  }
}

final premiumServiceProvider = Provider<PremiumService>((ref) {
  return PremiumService(InAppPurchase.instance);
});
