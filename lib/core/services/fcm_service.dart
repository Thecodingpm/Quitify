import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(FirebaseMessaging.instance);
});

class FcmService {
  FcmService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission();
    log('FCM permission: ${settings.authorizationStatus}');
    await _messaging.setAutoInitEnabled(true);

    // Token retrieval may fail on iOS if APNS token isn't ready yet.
    // We catch the error and retry after a delay.
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        log('FCM token: $token');
      }
    } catch (e) {
      log('FCM token not available yet, will retry: $e');
      // Retry after a delay to allow iOS to deliver the APNS token.
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          final token = await _messaging.getToken();
          if (token != null) {
            log('FCM token (retry): $token');
          }
        } catch (e) {
          log('FCM token retry failed: $e');
        }
      });
    }

    FirebaseMessaging.onMessage.listen((message) {
      log('Foreground message: ${message.messageId}');
    });
  }
}
