import 'knee_data_point.dart';

class SessionRecord {
  SessionRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.avgAngle,
    required this.peakAngle,
    required this.minAngle,
    required this.avgSpeed,
    required this.peakSpeed,
    required this.totalSteps,
    required this.caloriesBurned,
    required this.dominantActivity,
    this.gaitLabel,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double avgAngle;
  final double peakAngle;
  final double minAngle;
  final double avgSpeed;
  final double peakSpeed;
  final int totalSteps;
  final double caloriesBurned;
  final ActivityType dominantActivity;
  final String? gaitLabel;

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'avgAngle': avgAngle,
      'peakAngle': peakAngle,
      'minAngle': minAngle,
      'avgSpeed': avgSpeed,
      'peakSpeed': peakSpeed,
      'totalSteps': totalSteps,
      'caloriesBurned': caloriesBurned,
      'dominantActivity': dominantActivity.label,
      'gaitLabel': gaitLabel,
    };
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: (json['id'] ?? '').toString(),
      startTime: DateTime.tryParse((json['startTime'] ?? '').toString()) ?? DateTime.now(),
      endTime: DateTime.tryParse((json['endTime'] ?? '').toString()) ?? DateTime.now(),
      avgAngle: _toDouble(json['avgAngle']),
      peakAngle: _toDouble(json['peakAngle']),
      minAngle: _toDouble(json['minAngle']),
      avgSpeed: _toDouble(json['avgSpeed']),
      peakSpeed: _toDouble(json['peakSpeed']),
      totalSteps: _toInt(json['totalSteps']),
      caloriesBurned: _toDouble(json['caloriesBurned']),
      dominantActivity: parseActivityType(json['dominantActivity']?.toString()),
      gaitLabel: json['gaitLabel']?.toString(),
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
