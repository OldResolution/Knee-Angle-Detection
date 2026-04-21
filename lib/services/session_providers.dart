import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log.dart';
import '../models/knee_data_point.dart';
import '../models/session_record.dart';
import 'ble_providers.dart';
import 'ble_service.dart';
import 'ml_providers.dart';
import 'storage_service.dart';

final _sessionRefreshProvider = StateProvider<int>((ref) => 0);

final activeSessionProvider =
    StateNotifierProvider<SessionLifecycleNotifier, ActiveSessionState?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final stream = ref.watch(bleControllerProvider.notifier).dataStream;
  final notifier = SessionLifecycleNotifier(ref: ref, storage: storage, stream: stream);

  ref.listen<BleConnectionStateData>(bleConnectionStateProvider, (previous, next) {
    final wasActive = previous != null &&
        (previous.phase == BleConnectionPhase.connected ||
            previous.phase == BleConnectionPhase.reconnecting ||
            previous.isSimulationMode);
    final nowInactive = next.phase == BleConnectionPhase.disconnected ||
        next.phase == BleConnectionPhase.error;

    if (wasActive && nowInactive) {
      unawaited(notifier.endSession());
    }
  });

  ref.onDispose(notifier.dispose);
  return notifier;
});

final sessionHistoryProvider = FutureProvider<List<SessionRecord>>((ref) async {
  ref.watch(_sessionRefreshProvider);
  final storage = ref.watch(storageServiceProvider);
  return storage.getAllSessions();
});

final dailyLogProvider = FutureProvider.family<DailyLog, DateTime>((ref, date) async {
  ref.watch(_sessionRefreshProvider);
  final storage = ref.watch(storageServiceProvider);
  return storage.getDailyLog(date);
});

final trendDataProvider = FutureProvider.family<List<DailyLog>, int>((ref, days) async {
  ref.watch(_sessionRefreshProvider);
  final storage = ref.watch(storageServiceProvider);
  if (days <= 7) {
    return storage.getLast7DaysLogs();
  }
  return storage.getLast30DaysLogs();
});

class ActiveSessionState {
  const ActiveSessionState({
    required this.startTime,
    required this.lastUpdate,
    required this.pointCount,
    required this.sumAngle,
    required this.peakAngle,
    required this.minAngle,
    required this.sumSpeed,
    required this.peakSpeed,
    required this.totalSteps,
    required this.caloriesBurned,
    required this.activityDurations,
  });

  final DateTime startTime;
  final DateTime lastUpdate;
  final int pointCount;
  final double sumAngle;
  final double peakAngle;
  final double minAngle;
  final double sumSpeed;
  final double peakSpeed;
  final int totalSteps;
  final double caloriesBurned;
  final Map<ActivityType, Duration> activityDurations;

  double get avgAngle => pointCount == 0 ? 0 : sumAngle / pointCount;
  double get avgSpeed => pointCount == 0 ? 0 : sumSpeed / pointCount;

  ActivityType get dominantActivity {
    if (activityDurations.isEmpty) {
      return ActivityType.unknown;
    }

    var winner = ActivityType.unknown;
    var maxDuration = Duration.zero;

    for (final entry in activityDurations.entries) {
      if (entry.value > maxDuration) {
        winner = entry.key;
        maxDuration = entry.value;
      }
    }

    return winner;
  }

  ActiveSessionState copyWith({
    DateTime? startTime,
    DateTime? lastUpdate,
    int? pointCount,
    double? sumAngle,
    double? peakAngle,
    double? minAngle,
    double? sumSpeed,
    double? peakSpeed,
    int? totalSteps,
    double? caloriesBurned,
    Map<ActivityType, Duration>? activityDurations,
  }) {
    return ActiveSessionState(
      startTime: startTime ?? this.startTime,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      pointCount: pointCount ?? this.pointCount,
      sumAngle: sumAngle ?? this.sumAngle,
      peakAngle: peakAngle ?? this.peakAngle,
      minAngle: minAngle ?? this.minAngle,
      sumSpeed: sumSpeed ?? this.sumSpeed,
      peakSpeed: peakSpeed ?? this.peakSpeed,
      totalSteps: totalSteps ?? this.totalSteps,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      activityDurations: activityDurations ?? this.activityDurations,
    );
  }

  Duration get elapsed => lastUpdate.difference(startTime);
}

class SessionLifecycleNotifier extends StateNotifier<ActiveSessionState?> {
  SessionLifecycleNotifier({
    required Ref ref,
    required StorageService storage,
    required Stream<KneeDataPoint> stream,
  })  : _ref = ref,
        _storage = storage,
        super(null) {
    _streamSubscription = stream.listen(_onPoint);
  }

  final Ref _ref;
  final StorageService _storage;

  StreamSubscription<KneeDataPoint>? _streamSubscription;

  double? _prevPrevAngle;
  double? _prevAngle;
  DateTime? _prevTime;
  DateTime? _lastStepTime;

  static const Duration _maxGap = Duration(seconds: 8);

  void _onPoint(KneeDataPoint point) {
    final current = state;

    if (current == null) {
      state = _newState(point.timestamp);
    } else if (point.timestamp.difference(current.lastUpdate) > _maxGap) {
      unawaited(endSession(endTime: current.lastUpdate));
      state = _newState(point.timestamp);
    }

    final active = state;
    if (active == null) {
      return;
    }

    final stepIncrement = _detectStep(point.angle, point.timestamp);
    final delta = _prevTime == null
        ? Duration.zero
        : point.timestamp.difference(_prevTime!).abs();

    final activityDurations = Map<ActivityType, Duration>.from(active.activityDurations);
    activityDurations[point.activityType] =
        (activityDurations[point.activityType] ?? Duration.zero) + delta;

    state = active.copyWith(
      lastUpdate: point.timestamp,
      pointCount: active.pointCount + 1,
      sumAngle: active.sumAngle + point.angle,
      peakAngle: max(active.peakAngle, point.angle),
      minAngle: min(active.minAngle, point.angle),
      sumSpeed: active.sumSpeed + point.speed,
      peakSpeed: max(active.peakSpeed, point.speed),
      totalSteps: active.totalSteps + stepIncrement,
      caloriesBurned: (active.totalSteps + stepIncrement) * 0.04,
      activityDurations: activityDurations,
    );

    _prevTime = point.timestamp;
  }

  ActiveSessionState _newState(DateTime start) {
    return ActiveSessionState(
      startTime: start,
      lastUpdate: start,
      pointCount: 0,
      sumAngle: 0,
      peakAngle: 0,
      minAngle: 180,
      sumSpeed: 0,
      peakSpeed: 0,
      totalSteps: 0,
      caloriesBurned: 0,
      activityDurations: const {},
    );
  }

  int _detectStep(double currentAngle, DateTime timestamp) {
    var stepDetected = 0;

    final previous = _prevAngle;
    final beforePrevious = _prevPrevAngle;

    if (beforePrevious != null && previous != null) {
      final isPeak = previous > beforePrevious && previous >= currentAngle;
      final hasAmplitude = (previous - beforePrevious) >= 6 && (previous - currentAngle) >= 6;
      final aboveThreshold = previous >= 45;
      final coolDownPassed =
          _lastStepTime == null || timestamp.difference(_lastStepTime!) >= const Duration(milliseconds: 320);

      if (isPeak && hasAmplitude && aboveThreshold && coolDownPassed) {
        _lastStepTime = timestamp;
        stepDetected = 1;
      }
    }

    _prevPrevAngle = previous;
    _prevAngle = currentAngle;

    return stepDetected;
  }

  Future<void> endSession({DateTime? endTime}) async {
    final active = state;
    if (active == null || active.pointCount < 2) {
      _resetTracking();
      state = null;
      return;
    }

    final prediction = _ref.read(latestGaitPredictionProvider);
    final session = SessionRecord(
      id: _generateId(),
      startTime: active.startTime,
      endTime: endTime ?? active.lastUpdate,
      avgAngle: active.avgAngle,
      peakAngle: active.peakAngle,
      minAngle: active.minAngle == 180 ? 0 : active.minAngle,
      avgSpeed: active.avgSpeed,
      peakSpeed: active.peakSpeed,
      totalSteps: active.totalSteps,
      caloriesBurned: active.caloriesBurned,
      dominantActivity: active.dominantActivity,
      gaitLabel: prediction?.label,
    );

    await _storage.saveSession(session);
    _ref.read(_sessionRefreshProvider.notifier).state++;

    _resetTracking();
    state = null;
  }

  void _resetTracking() {
    _prevPrevAngle = null;
    _prevAngle = null;
    _prevTime = null;
    _lastStepTime = null;
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final random = Random().nextInt(0x7fffffff).toRadixString(16);
    final merged = (now + random).padRight(32, '0').substring(0, 32);
    return '${merged.substring(0, 8)}-${merged.substring(8, 12)}-${merged.substring(12, 16)}-${merged.substring(16, 20)}-${merged.substring(20, 32)}';
  }
}
