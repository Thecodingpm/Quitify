class QuitStats {
  const QuitStats({
    required this.daysSmokeFree,
    required this.cigarettesAvoided,
    required this.moneySaved,
    required this.healthScore,
    required this.streakDays,
    required this.cravingsResisted,
  });

  final int daysSmokeFree;
  final int cigarettesAvoided;
  final double moneySaved;
  final int healthScore;
  final int streakDays;
  final int cravingsResisted;

  factory QuitStats.fromMap(Map<String, dynamic> map) {
    return QuitStats(
      daysSmokeFree: (map['daysSmokeFree'] ?? 0) as int,
      cigarettesAvoided: (map['cigarettesAvoided'] ?? 0) as int,
      moneySaved: (map['moneySaved'] ?? 0).toDouble(),
      healthScore: (map['healthScore'] ?? 0) as int,
      streakDays: (map['streakDays'] ?? 0) as int,
      cravingsResisted: (map['cravingsResisted'] ?? 0) as int,
    );
  }

  static QuitStats placeholder() {
    return const QuitStats(
      daysSmokeFree: 3,
      cigarettesAvoided: 12,
      moneySaved: 18.5,
      healthScore: 62,
      streakDays: 3,
      cravingsResisted: 5,
    );
  }
}
