import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/quit_stats.dart';

class ProgressRepository {
  ProgressRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<QuitStats> watchStats(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc('current')
        .snapshots()
        .map(
          (snapshot) => snapshot.exists
              ? QuitStats.fromMap(snapshot.data() ?? {})
              : QuitStats.placeholder(),
        )
        .handleError((_) => QuitStats.placeholder());
  }

  Future<void> recordCheckIn({required String uid}) async {
    final doc = _firestore.collection('users').doc(uid).collection('progress').doc('current');
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(doc);
      final current = snapshot.data() ?? {};
      final streakDays = (current['streakDays'] ?? 0) + 1;
      tx.set(doc, {
        'streakDays': streakDays,
        'daysSmokeFree': (current['daysSmokeFree'] ?? 0) + 1,
        'cigarettesAvoided': (current['cigarettesAvoided'] ?? 0) + 4,
        'moneySaved': (current['moneySaved'] ?? 0) + 6.0,
        'healthScore': (current['healthScore'] ?? 0) + 2,
        'cravingsResisted': (current['cravingsResisted'] ?? 0) + 1,
      }, SetOptions(merge: true));
    });
  }

  Future<void> recordCraving({required String uid}) async {
    final userDoc = _firestore.collection('users').doc(uid);
    final progressDoc = userDoc.collection('progress').doc('current');
    final cravingsCol = userDoc.collection('cravings');

    await _firestore.runTransaction((tx) async {
      final progressSnap = await tx.get(progressDoc);
      final current = progressSnap.data() ?? {};
      tx.set(
        progressDoc,
        {
          'cravingsResisted': (current['cravingsResisted'] ?? 0) + 1,
          'total_cravings_logged': (current['total_cravings_logged'] ?? 0) + 1,
        },
        SetOptions(merge: true),
      );
      tx.set(userDoc, {'total_cravings_logged': FieldValue.increment(1)}, SetOptions(merge: true));
    });

    await cravingsCol.add({
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'logged',
    });
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(firestoreProvider));
});
