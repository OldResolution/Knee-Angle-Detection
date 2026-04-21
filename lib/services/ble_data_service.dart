import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/knee_data_point.dart';

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
  String _decodeBuffer = '';
  KneeDataPoint? _lastPoint;

  Future<void> setSimulationMode(bool enabled) async {
    _simulationMode = enabled;
    if (enabled) {
      await stopStreaming();
      _startSimulationStream();
    } else {
      _stopSimulationStream();
    }
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
      final elapsed = now.difference(sessionStart).inMilliseconds / 1000.0;
      final base = 65 + 38 * sin(2 * pi * 0.45 * elapsed);
      final harmonics = 6 * sin(2 * pi * 1.05 * elapsed);
      final jitter = (random.nextDouble() - 0.5) * 3;
      final angle = (base + harmonics + jitter).clamp(0, 140).toDouble();
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