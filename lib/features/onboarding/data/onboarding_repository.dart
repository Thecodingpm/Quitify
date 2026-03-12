import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingInfo {
  const OnboardingInfo({
    required this.cigarettesPerDay,
    required this.packPrice,
    required this.yearsSmoking,
    required this.quitDate,
    required this.reason,
  });

  final int cigarettesPerDay;
  final double packPrice;
  final double yearsSmoking;
  final DateTime? quitDate;
  final String reason;

  Map<String, dynamic> toMap() {
    return {
      'cigarettes_per_day': cigarettesPerDay,
      'pack_price': packPrice,
      'years_smoking': yearsSmoking,
      'quit_date': quitDate?.toIso8601String(),
      'reason_for_quitting': reason,
    };
  }

  factory OnboardingInfo.fromMap(Map<String, dynamic> map) {
    return OnboardingInfo(
      cigarettesPerDay: map['cigarettes_per_day'] ?? 0,
      packPrice: (map['pack_price'] ?? 0).toDouble(),
      yearsSmoking: (map['years_smoking'] ?? 0).toDouble(),
      quitDate: map['quit_date'] != null ? DateTime.tryParse(map['quit_date']) : null,
      reason: map['reason_for_quitting'] ?? '',
    );
  }
}

class OnboardingRepository {
  static const _prefKey = 'onboarding_info';

  /// Saves onboarding info locally. Data is synced to Firestore during sign-up.
  Future<void> saveInfo(OnboardingInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(info.toMap()));
  }

  /// Retrieves locally saved onboarding info (used during sign-up to sync to Firestore).
  static Future<OnboardingInfo?> getSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefKey);
    if (json == null) return null;
    return OnboardingInfo.fromMap(jsonDecode(json));
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository();
});
