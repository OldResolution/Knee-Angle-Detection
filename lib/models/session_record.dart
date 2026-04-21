import 'package:hive/hive.dart';

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

class SessionRecordAdapter extends TypeAdapter<SessionRecord> {
  @override
  final int typeId = 1;

  @override
  SessionRecord read(BinaryReader reader) {
    final count = reader.readByte();
    final values = <int, dynamic>{};
    for (var i = 0; i < count; i++) {
      values[reader.readByte()] = reader.read();
    }

    return SessionRecord(
      id: (values[0] ?? '').toString(),
      startTime: values[1] is DateTime ? values[1] as DateTime : DateTime.now(),
      endTime: values[2] is DateTime ? values[2] as DateTime : DateTime.now(),
      avgAngle: (values[3] as num?)?.toDouble() ?? 0,
      peakAngle: (values[4] as num?)?.toDouble() ?? 0,
      minAngle: (values[5] as num?)?.toDouble() ?? 0,
      avgSpeed: (values[6] as num?)?.toDouble() ?? 0,
      peakSpeed: (values[7] as num?)?.toDouble() ?? 0,
      totalSteps: (values[8] as num?)?.toInt() ?? 0,
      caloriesBurned: (values[9] as num?)?.toDouble() ?? 0,
      dominantActivity: parseActivityType(values[10]?.toString()),
      gaitLabel: values[11]?.toString(),
    );
  }

  @override
  void write(BinaryWriter writer, SessionRecord obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.avgAngle)
      ..writeByte(4)
      ..write(obj.peakAngle)
      ..writeByte(5)
      ..write(obj.minAngle)
      ..writeByte(6)
      ..write(obj.avgSpeed)
      ..writeByte(7)
      ..write(obj.peakSpeed)
      ..writeByte(8)
      ..write(obj.totalSteps)
      ..writeByte(9)
      ..write(obj.caloriesBurned)
      ..writeByte(10)
      ..write(obj.dominantActivity.label)
      ..writeByte(11)
      ..write(obj.gaitLabel);
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
