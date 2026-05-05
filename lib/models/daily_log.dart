class DailyLog {
  DailyLog({
    required this.date,
    required this.totalSteps,
    required this.totalCalories,
    required this.totalActiveMinutes,
    required this.totalSessions,
    required this.avgKneeAngle,
    required this.peakKneeAngle,
    required this.avgSpeed,
    required this.goalStepsMet,
    required this.goalExerciseMet,
    required this.goalActiveHoursMet,
  });

  final DateTime date;
  final int totalSteps;
  final double totalCalories;
  final int totalActiveMinutes;
  final int totalSessions;
  final double avgKneeAngle;
  final double peakKneeAngle;
  final double avgSpeed;
  final bool goalStepsMet;
  final bool goalExerciseMet;
  final bool goalActiveHoursMet;

  DailyLog copyWith({
    DateTime? date,
    int? totalSteps,
    double? totalCalories,
    int? totalActiveMinutes,
    int? totalSessions,
    double? avgKneeAngle,
    double? peakKneeAngle,
    double? avgSpeed,
    bool? goalStepsMet,
    bool? goalExerciseMet,
    bool? goalActiveHoursMet,
  }) {
    return DailyLog(
      date: date ?? this.date,
      totalSteps: totalSteps ?? this.totalSteps,
      totalCalories: totalCalories ?? this.totalCalories,
      totalActiveMinutes: totalActiveMinutes ?? this.totalActiveMinutes,
      totalSessions: totalSessions ?? this.totalSessions,
      avgKneeAngle: avgKneeAngle ?? this.avgKneeAngle,
      peakKneeAngle: peakKneeAngle ?? this.peakKneeAngle,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      goalStepsMet: goalStepsMet ?? this.goalStepsMet,
      goalExerciseMet: goalExerciseMet ?? this.goalExerciseMet,
      goalActiveHoursMet: goalActiveHoursMet ?? this.goalActiveHoursMet,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalSteps': totalSteps,
      'totalCalories': totalCalories,
      'totalActiveMinutes': totalActiveMinutes,
      'totalSessions': totalSessions,
      'avgKneeAngle': avgKneeAngle,
      'peakKneeAngle': peakKneeAngle,
      'avgSpeed': avgSpeed,
      'goalStepsMet': goalStepsMet,
      'goalExerciseMet': goalExerciseMet,
      'goalActiveHoursMet': goalActiveHoursMet,
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      totalSteps: _toInt(json['totalSteps']),
      totalCalories: _toDouble(json['totalCalories']),
      totalActiveMinutes: _toInt(json['totalActiveMinutes']),
      totalSessions: _toInt(json['totalSessions']),
      avgKneeAngle: _toDouble(json['avgKneeAngle']),
      peakKneeAngle: _toDouble(json['peakKneeAngle']),
      avgSpeed: _toDouble(json['avgSpeed']),
      goalStepsMet: json['goalStepsMet'] == true,
      goalExerciseMet: json['goalExerciseMet'] == true,
      goalActiveHoursMet: json['goalActiveHoursMet'] == true,
    );
  }

  static DailyLog emptyForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return DailyLog(
      date: day,
      totalSteps: 0,
      totalCalories: 0,
      totalActiveMinutes: 0,
      totalSessions: 0,
      avgKneeAngle: 0,
      peakKneeAngle: 0,
      avgSpeed: 0,
      goalStepsMet: false,
      goalExerciseMet: false,
      goalActiveHoursMet: false,
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

int _toInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
