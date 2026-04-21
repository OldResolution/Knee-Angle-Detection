import 'dart:async';

import '../models/knee_alert.dart';
import '../models/knee_data_point.dart';

/// Configuration for the knee analysis engine.
class AnalysisConfig {
  const AnalysisConfig({
    this.maxAngleThreshold = 140.0,
    this.minAngleThreshold = 5.0,
    this.suddenMovementThreshold = 200.0,
    this.alertsEnabled = true,
    this.cooldownDuration = const Duration(seconds: 5),
    this.maxHistorySize = 50,
  });

  final double maxAngleThreshold;
  final double minAngleThreshold;

  /// Angular velocity spike threshold (°/s).
  final double suddenMovementThreshold;

  final bool alertsEnabled;

  /// Cooldown per alert type to avoid spam.
  final Duration cooldownDuration;

  /// Maximum number of alerts retained in history.
  final int maxHistorySize;

  AnalysisConfig copyWith({
    double? maxAngleThreshold,
    double? minAngleThreshold,
    double? suddenMovementThreshold,
    bool? alertsEnabled,
  }) {
    return AnalysisConfig(
      maxAngleThreshold: maxAngleThreshold ?? this.maxAngleThreshold,
      minAngleThreshold: minAngleThreshold ?? this.minAngleThreshold,
      suddenMovementThreshold:
          suddenMovementThreshold ?? this.suddenMovementThreshold,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      cooldownDuration: cooldownDuration,
      maxHistorySize: maxHistorySize,
    );
  }
}

/// Real-time analysis engine that subscribes to [KneeDataPoint] streams and
/// emits [KneeAlert]s for threshold breaches and sudden movements.
class KneeAnalysisService {
  KneeAnalysisService({
    required Stream<KneeDataPoint> dataStream,
    AnalysisConfig config = const AnalysisConfig(),
  })  : _config = config {
    _subscription = dataStream.listen(_onDataPoint);
  }

  AnalysisConfig _config;
  StreamSubscription<KneeDataPoint>? _subscription;

  final StreamController<KneeAlert> _alertController =
      StreamController<KneeAlert>.broadcast();

  /// Live stream of alerts as they are generated.
  Stream<KneeAlert> get alertStream => _alertController.stream;

  /// Tracks last emit time per [AlertType] for cooldown logic.
  final Map<AlertType, DateTime> _lastAlertTime = {};

  /// Update configuration at runtime (e.g. when user changes slider).
  void updateConfig(AnalysisConfig config) {
    _config = config;
  }

  void _onDataPoint(KneeDataPoint point) {
    if (!_config.alertsEnabled) return;

    _checkAngleThresholds(point);
    _checkSuddenMovement(point);
  }

  // ── Threshold Detection ──────────────────────────────────────────────

  void _checkAngleThresholds(KneeDataPoint point) {
    final now = point.timestamp;

    // Upper limit breach
    if (point.angle > _config.maxAngleThreshold) {
      _emitIfCooldownExpired(
        alertType: AlertType.angleThreshold,
        now: now,
        builder: () => KneeAlert(
          type: AlertType.angleThreshold,
          severity: AlertSeverity.warning,
          title: 'Max Angle Exceeded',
          message:
              'Knee angle reached ${point.angle.toStringAsFixed(1)}° — above the ${_config.maxAngleThreshold.toStringAsFixed(0)}° limit.',
          triggerValue: point.angle,
          thresholdValue: _config.maxAngleThreshold,
          timestamp: now,
        ),
      );
    }

    // Lower limit breach
    if (point.angle < _config.minAngleThreshold) {
      _emitIfCooldownExpired(
        alertType: AlertType.angleThreshold,
        now: now,
        builder: () => KneeAlert(
          type: AlertType.angleThreshold,
          severity: AlertSeverity.info,
          title: 'Min Angle Breach',
          message:
              'Knee angle dropped to ${point.angle.toStringAsFixed(1)}° — below the ${_config.minAngleThreshold.toStringAsFixed(0)}° floor.',
          triggerValue: point.angle,
          thresholdValue: _config.minAngleThreshold,
          timestamp: now,
        ),
      );
    }
  }

  // ── Sudden Movement Detection ────────────────────────────────────────

  void _checkSuddenMovement(KneeDataPoint point) {
    if (point.speed > _config.suddenMovementThreshold) {
      _emitIfCooldownExpired(
        alertType: AlertType.suddenMovement,
        now: point.timestamp,
        builder: () => KneeAlert(
          type: AlertType.suddenMovement,
          severity: AlertSeverity.critical,
          title: 'Sudden Movement Detected',
          message:
              'Angular velocity spiked to ${point.speed.toStringAsFixed(1)}°/s — exceeds the ${_config.suddenMovementThreshold.toStringAsFixed(0)}°/s safety limit.',
          triggerValue: point.speed,
          thresholdValue: _config.suddenMovementThreshold,
          timestamp: point.timestamp,
        ),
      );
    }
  }

  // ── Cooldown Gate ────────────────────────────────────────────────────

  void _emitIfCooldownExpired({
    required AlertType alertType,
    required DateTime now,
    required KneeAlert Function() builder,
  }) {
    final lastTime = _lastAlertTime[alertType];
    if (lastTime != null &&
        now.difference(lastTime) < _config.cooldownDuration) {
      return; // still in cooldown
    }

    _lastAlertTime[alertType] = now;
    final alert = builder();
    if (!_alertController.isClosed) {
      _alertController.add(alert);
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _alertController.close();
  }
}
