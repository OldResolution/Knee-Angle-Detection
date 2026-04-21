class UserGoals {
  const UserGoals({
    required this.dailyStepGoal,
    required this.exerciseMinutesGoal,
    required this.activeHoursGoal,
  });

  static const UserGoals defaults = UserGoals(
    dailyStepGoal: 8000,
    exerciseMinutesGoal: 30,
    activeHoursGoal: 6.0,
  );

  final int dailyStepGoal;
  final int exerciseMinutesGoal;
  final double activeHoursGoal;

  UserGoals copyWith({
    int? dailyStepGoal,
    int? exerciseMinutesGoal,
    double? activeHoursGoal,
  }) {
    return UserGoals(
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      exerciseMinutesGoal: exerciseMinutesGoal ?? this.exerciseMinutesGoal,
      activeHoursGoal: activeHoursGoal ?? this.activeHoursGoal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyStepGoal': dailyStepGoal,
      'exerciseMinutesGoal': exerciseMinutesGoal,
      'activeHoursGoal': activeHoursGoal,
    };
  }

  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      dailyStepGoal: _toInt(json['dailyStepGoal'], fallback: defaults.dailyStepGoal),
      exerciseMinutesGoal: _toInt(json['exerciseMinutesGoal'], fallback: defaults.exerciseMinutesGoal),
      activeHoursGoal: _toDouble(json['activeHoursGoal'], fallback: defaults.activeHoursGoal),
    );
  }
}

int _toInt(Object? value, {required int fallback}) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _toDouble(Object? value, {required double fallback}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}
