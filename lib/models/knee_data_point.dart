enum ActivityType {
  walking,
  sitting,
  standing,
  exercising,
  unknown,
}

extension ActivityTypeX on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.walking:
        return 'walking';
      case ActivityType.sitting:
        return 'sitting';
      case ActivityType.standing:
        return 'standing';
      case ActivityType.exercising:
        return 'exercising';
      case ActivityType.unknown:
        return 'unknown';
    }
  }

  String get displayName {
    final value = label;
    return value[0].toUpperCase() + value.substring(1);
  }
}

ActivityType parseActivityType(String? raw) {
  final normalized = (raw ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'walking':
      return ActivityType.walking;
    case 'sitting':
      return ActivityType.sitting;
    case 'standing':
      return ActivityType.standing;
    case 'exercising':
      return ActivityType.exercising;
    default:
      return ActivityType.unknown;
  }
}

class KneeDataPoint {
  const KneeDataPoint({
    required this.angle,
    required this.speed,
    required this.activityType,
    required this.timestamp,
  });

  final double angle;
  final double speed;
  final ActivityType activityType;
  final DateTime timestamp;

  factory KneeDataPoint.fromJson(Map<String, dynamic> json, {DateTime? timestamp}) {
    final parsedAngle = _toDouble(json['angle']);
    if (parsedAngle == null) {
      throw const FormatException('Missing or invalid angle value.');
    }

    final parsedSpeed = _toDouble(json['speed']) ?? 0;
    final parsedActivity = parseActivityType(json['activity']?.toString());

    return KneeDataPoint(
      angle: parsedAngle,
      speed: parsedSpeed,
      activityType: parsedActivity,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}

double? _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.trim());
  }

  return null;
}