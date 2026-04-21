import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/knee_data_point.dart';

enum SimulationPattern {
  normalWalking,
  limp,
  shuffling,
  stiffKnee,
  exercise,
  random,
}

extension SimulationPatternX on SimulationPattern {
  String get key {
    switch (this) {
      case SimulationPattern.normalWalking:
        return 'normalWalking';
      case SimulationPattern.limp:
        return 'limp';
      case SimulationPattern.shuffling:
        return 'shuffling';
      case SimulationPattern.stiffKnee:
        return 'stiffKnee';
      case SimulationPattern.exercise:
        return 'exercise';
      case SimulationPattern.random:
        return 'random';
    }
  }

  String get displayName {
    switch (this) {
      case SimulationPattern.normalWalking:
        return 'Normal Walking';
      case SimulationPattern.limp:
        return 'Limp';
      case SimulationPattern.shuffling:
        return 'Shuffling';
      case SimulationPattern.stiffKnee:
        return 'Stiff Knee';
      case SimulationPattern.exercise:
        return 'Exercise';
      case SimulationPattern.random:
        return 'Random';
    }
  }
}

SimulationPattern parseSimulationPattern(String? raw) {
  switch ((raw ?? '').trim()) {
    case 'normalWalking':
      return SimulationPattern.normalWalking;
    case 'limp':
      return SimulationPattern.limp;
    case 'shuffling':
      return SimulationPattern.shuffling;
    case 'stiffKnee':
      return SimulationPattern.stiffKnee;
    case 'exercise':
      return SimulationPattern.exercise;
    case 'random':
    default:
      return SimulationPattern.random;
  }
}

class BleDataService {
  BleDataService({
    String serviceUuid = '0000FFE0-0000-1000-8000-00805F9B34FB',
    String characteristicUuid = '0000FFE1-0000-1000-8000-00805F9B34FB',
  })  : _serviceUuid = Guid(serviceUuid),
        _characteristicUuid = Guid(characteristicUuid);

  final Guid _serviceUuid;
  final Guid _characteristicUuid;

  final StreamController<KneeDataPoint> _controller = StreamController<KneeDataPoint>.broadcast();

  Stream<KneeDataPoint> get stream => _controller.stream;

  StreamSubscription<List<int>>? _characteristicSubscription;
  BluetoothCharacteristic? _activeCharacteristic;
  Timer? _simulationTimer;

  bool _simulationMode = false;
  SimulationPattern _simulationPattern = SimulationPattern.random;
  double _simulationSpeedMultiplier = 1.0;
  String _decodeBuffer = '';
  KneeDataPoint? _lastPoint;

  SimulationPattern get simulationPattern => _simulationPattern;
  double get simulationSpeedMultiplier => _simulationSpeedMultiplier;
  double get simulationDataRateHz => 20.0 * _simulationSpeedMultiplier;

  Future<void> setSimulationMode(bool enabled) async {
    _simulationMode = enabled;
    if (enabled) {
      await stopStreaming();
      _startSimulationStream();
    } else {
      _stopSimulationStream();
    }
  }

  void setSimulationPattern(SimulationPattern pattern) {
    _simulationPattern = pattern;
  }

  void setSimulationSpeedMultiplier(double multiplier) {
    _simulationSpeedMultiplier = multiplier.clamp(0.5, 3.0).toDouble();
  }

  Future<void> startStreaming(BluetoothDevice device) async {
    if (_simulationMode) {
      _startSimulationStream();
      return;
    }

    _stopSimulationStream();
    await stopStreaming();

    final services = await device.discoverServices();

    BluetoothCharacteristic? characteristic;
    for (final service in services) {
      final serviceMatches = service.uuid == _serviceUuid;
      for (final candidate in service.characteristics) {
        final isTarget = candidate.uuid == _characteristicUuid;
        if (serviceMatches && isTarget) {
          characteristic = candidate;
          break;
        }
      }
      if (characteristic != null) {
        break;
      }
    }

    if (characteristic == null) {
      throw StateError(
        'Target characteristic not found. Expected service $_serviceUuid and characteristic $_characteristicUuid.',
      );
    }

    _activeCharacteristic = characteristic;
    await characteristic.setNotifyValue(true);
    _characteristicSubscription = characteristic.lastValueStream.listen(_onPacketBytes);
  }

  Future<void> stopStreaming() async {
    await _characteristicSubscription?.cancel();
    _characteristicSubscription = null;

    try {
      await _activeCharacteristic?.setNotifyValue(false);
    } catch (_) {
      // Ignore errors while tearing down notifications.
    }

    _activeCharacteristic = null;
    _decodeBuffer = '';
  }

  void _onPacketBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      return;
    }

    _decodeBuffer += utf8.decode(bytes, allowMalformed: true);
    final extracted = _extractJsonObjects();
    for (final raw in extracted) {
      _emitFromRawJson(raw);
    }
  }

  List<String> _extractJsonObjects() {
    final packets = <String>[];
    var depth = 0;
    var start = -1;

    for (var i = 0; i < _decodeBuffer.length; i++) {
      final char = _decodeBuffer[i];
      if (char == '{') {
        if (depth == 0) {
          start = i;
        }
        depth += 1;
      } else if (char == '}') {
        if (depth > 0) {
          depth -= 1;
        }

        if (depth == 0 && start >= 0) {
          packets.add(_decodeBuffer.substring(start, i + 1));
          _decodeBuffer = _decodeBuffer.substring(i + 1);
          i = -1;
          start = -1;
        }
      }
    }

    if (_decodeBuffer.length > 4096) {
      _decodeBuffer = _decodeBuffer.substring(_decodeBuffer.length - 1024);
    }

    return packets;
  }

  void _emitFromRawJson(String rawPacket) {
    try {
      final decoded = jsonDecode(rawPacket);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final parsed = KneeDataPoint.fromJson(decoded, timestamp: DateTime.now());
      final resolvedSpeed = parsed.speed == 0 ? _computeSpeed(parsed.angle, parsed.timestamp) : parsed.speed;
      final resolvedActivity = parsed.activityType == ActivityType.unknown
          ? _inferActivity(angle: parsed.angle, speed: resolvedSpeed)
          : parsed.activityType;

      final point = KneeDataPoint(
        angle: parsed.angle.clamp(0, 180).toDouble(),
        speed: resolvedSpeed,
        activityType: resolvedActivity,
        timestamp: parsed.timestamp,
      );

      _lastPoint = point;
      if (!_controller.isClosed) {
        _controller.add(point);
      }
    } catch (_) {
      // Ignore malformed packets.
    }
  }

  double _computeSpeed(double angle, DateTime timestamp) {
    final previous = _lastPoint;
    if (previous == null) {
      return 0;
    }

    final deltaMillis = timestamp.difference(previous.timestamp).inMilliseconds;
    if (deltaMillis <= 0) {
      return previous.speed;
    }

    final deltaSeconds = deltaMillis / 1000.0;
    return ((angle - previous.angle).abs() / deltaSeconds).clamp(0, 720).toDouble();
  }

  ActivityType _inferActivity({required double angle, required double speed}) {
    if (speed > 70 && angle > 20 && angle < 140) {
      return ActivityType.walking;
    }

    if (speed > 110) {
      return ActivityType.exercising;
    }

    if (speed < 5 && angle >= 75 && angle <= 110) {
      return ActivityType.sitting;
    }

    if (speed < 5 && angle < 30) {
      return ActivityType.standing;
    }

    return ActivityType.unknown;
  }

  void _startSimulationStream() {
    if (_simulationTimer != null) {
      return;
    }

    final sessionStart = DateTime.now();
    final random = Random();

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final now = DateTime.now();
      final elapsed = (now.difference(sessionStart).inMilliseconds / 1000.0) * _simulationSpeedMultiplier;
      final angle = _nextSimulatedAngle(
        elapsed: elapsed,
        random: random,
      );
      final speed = _computeSpeed(angle, now);
      final activity = _inferActivity(angle: angle, speed: speed);

      final point = KneeDataPoint(
        angle: angle,
        speed: speed,
        activityType: activity,
        timestamp: now,
      );

      _lastPoint = point;
      if (!_controller.isClosed) {
        _controller.add(point);
      }
    });
  }

  double _nextSimulatedAngle({
    required double elapsed,
    required Random random,
  }) {
    switch (_simulationPattern) {
      case SimulationPattern.normalWalking:
        return (65 + 30 * sin(2 * pi * 0.55 * elapsed) + 5 * sin(2 * pi * 1.1 * elapsed))
            .clamp(30, 100)
            .toDouble();
      case SimulationPattern.limp:
        final primary = 58 + 32 * sin(2 * pi * 0.42 * elapsed);
        final asym = 16 * sin(2 * pi * 0.21 * elapsed + pi / 5);
        final jitter = (random.nextDouble() - 0.5) * 8;
        return (primary + asym + jitter).clamp(15, 120).toDouble();
      case SimulationPattern.shuffling:
        return (24 + 10 * sin(2 * pi * 1.3 * elapsed) + (random.nextDouble() - 0.5) * 3)
            .clamp(10, 40)
            .toDouble();
      case SimulationPattern.stiffKnee:
        return (40 + 16 * sin(2 * pi * 0.38 * elapsed) + (random.nextDouble() - 0.5) * 2)
            .clamp(20, 60)
            .toDouble();
      case SimulationPattern.exercise:
        final burst = (sin(2 * pi * 0.16 * elapsed) > 0.72) ? 22 : 0;
        return (72 + 58 * sin(2 * pi * 0.75 * elapsed) + burst + (random.nextDouble() - 0.5) * 5)
            .clamp(10, 140)
            .toDouble();
      case SimulationPattern.random:
        final base = 65 + 38 * sin(2 * pi * 0.45 * elapsed);
        final harmonics = 6 * sin(2 * pi * 1.05 * elapsed);
        final jitter = (random.nextDouble() - 0.5) * 6;
        return (base + harmonics + jitter).clamp(0, 140).toDouble();
    }
  }

  void _stopSimulationStream() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  Future<void> dispose() async {
    _stopSimulationStream();
    await stopStreaming();
    await _controller.close();
  }
}