import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((_) {
  return FirebaseAnalytics.instance;
});

final analyticsObserverProvider = Provider<NavigatorObserver>((ref) {
  return FirebaseAnalyticsObserver(analytics: ref.watch(firebaseAnalyticsProvider));
});

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logAppOpen() => _analytics.logAppOpen();

  Future<void> logOnboardingCompleted() => _analytics.logEvent(name: 'onboarding_completed');

  Future<void> logCheckIn({required int day}) => _analytics.logEvent(
        name: 'daily_check_in',
        parameters: {'day': day},
      );

  Future<void> logSubscriptionView(String planId) => _analytics.logViewItem(items: [AnalyticsEventItem(itemId: planId, itemName: 'premium_plan')]);
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(firebaseAnalyticsProvider));
});
