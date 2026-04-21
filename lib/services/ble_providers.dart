import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/knee_alert.dart';
import '../models/knee_data_point.dart';
import '../services/preferences_service.dart';
import 'ble_data_service.dart';
import 'ble_service.dart';
import 'knee_analysis_service.dart';

final bleControllerProvider = StateNotifierProvider<BleController, BleState>((ref) {
  return BleController(initialSimulationMode: PreferencesService.isSimulationMode);
});

final bleScanStateProvider = Provider<BleScanState>((ref) {
  return ref.watch(bleControllerProvider.select((state) => state.scanState));
});

final bleConnectionStateProvider = Provider<BleConnectionStateData>((ref) {
  return ref.watch(bleControllerProvider.select((state) => state.connectionState));
});

final bleDataStreamProvider = StreamProvider<KneeDataPoint>((ref) {
  return ref.watch(bleControllerProvider.notifier).dataStream;
});

final currentKneeDataProvider = Provider<KneeDataPoint?>((ref) {
  return ref.watch(bleDataStreamProvider).valueOrNull;
});

final kneeDataHistoryProvider = StateNotifierProvider<KneeDataHistoryNotifier, List<KneeDataPoint>>((ref) {
  final notifier = KneeDataHistoryNotifier();
  final subscription = ref.watch(bleControllerProvider.notifier).dataStream.listen(notifier.addPoint);
  ref.onDispose(subscription.cancel);
  return notifier;
});

final isLiveDataActiveProvider = Provider<bool>((ref) {
  final current = ref.watch(currentKneeDataProvider);
  final connection = ref.watch(bleConnectionStateProvider);
  if (current == null) {
    return false;
  }

  if (connection.isSimulationMode) {
    return true;
  }

  return connection.phase == BleConnectionPhase.connected || connection.phase == BleConnectionPhase.reconnecting;
});

// ── Analysis Engine Providers ──────────────────────────────────────────

/// Current analysis configuration, rebuilds when changed via settings.
final analysisConfigProvider = StateProvider<AnalysisConfig>((ref) {
  return AnalysisConfig(
    maxAngleThreshold: PreferencesService.maxAngleThreshold,
    minAngleThreshold: PreferencesService.minAngleThreshold,
    suddenMovementThreshold: PreferencesService.suddenMovementThreshold,
    alertsEnabled: PreferencesService.alertsEnabled,
  );
});

/// Singleton analysis engine tied to the BLE controller lifecycle.
final kneeAnalysisProvider = Provider<KneeAnalysisService>((ref) {
  final dataStream = ref.watch(bleControllerProvider.notifier).dataStream;
  final config = ref.watch(analysisConfigProvider);

  final service = KneeAnalysisService(
    dataStream: dataStream,
    config: config,
  );

  ref.onDispose(() => service.dispose());
  return service;
});

/// Live stream of [KneeAlert]s emitted by the analysis engine.
final alertStreamProvider = StreamProvider<KneeAlert>((ref) {
  final analysis = ref.watch(kneeAnalysisProvider);
  return analysis.alertStream;
});

/// Rolling history of the most recent alerts.
final alertHistoryProvider =
    StateNotifierProvider<AlertHistoryNotifier, List<KneeAlert>>((ref) {
  final notifier = AlertHistoryNotifier();
  final subscription =
      ref.watch(kneeAnalysisProvider).alertStream.listen(notifier.addAlert);
  ref.onDispose(subscription.cancel);
  return notifier;
});

/// Number of undismissed alerts (for badge display).
final activeAlertCountProvider = Provider<int>((ref) {
  final history = ref.watch(alertHistoryProvider);
  return history.where((alert) => !alert.dismissed).length;
});

class KneeDataHistoryNotifier extends StateNotifier<List<KneeDataPoint>> {
  KneeDataHistoryNotifier({this.maxPoints = 200}) : super(const []);

  final int maxPoints;

  void addPoint(KneeDataPoint point) {
    final next = [...state, point];
    if (next.length > maxPoints) {
      next.removeRange(0, next.length - maxPoints);
    }
    state = next;
  }

  void clear() {
    state = const [];
  }
}

class AlertHistoryNotifier extends StateNotifier<List<KneeAlert>> {
  AlertHistoryNotifier({this.maxAlerts = 50}) : super(const []);

  final int maxAlerts;

  void addAlert(KneeAlert alert) {
    final next = [alert, ...state];
    if (next.length > maxAlerts) {
      next.removeRange(maxAlerts, next.length);
    }
    state = next;
  }

  void dismiss(int index) {
    if (index < 0 || index >= state.length) return;
    final next = [...state];
    next[index] = next[index].copyWith(dismissed: true);
    state = next;
  }

  void dismissAll() {
    state = state.map((a) => a.copyWith(dismissed: true)).toList();
  }

  void clear() {
    state = const [];
  }
}


class BleController extends StateNotifier<BleState> {
  BleController({required bool initialSimulationMode})
      : super(BleState.initial(isSimulationMode: initialSimulationMode)) {
    _dataService = BleDataService();
    _service = BleService(
      initialSimulationMode: initialSimulationMode,
      onScanStateChanged: (scanState) {
        state = state.copyWith(scanState: scanState);
      },
      onConnectionStateChanged: (connectionState) {
        state = state.copyWith(connectionState: connectionState);
      },
      onDeviceConnected: (device) => _dataService.startStreaming(device),
      onDeviceDisconnected: (_) => _dataService.stopStreaming(),
      onSimulationModeChanged: (isSimulationMode) => _dataService.setSimulationMode(isSimulationMode),
    );

    if (initialSimulationMode) {
      unawaited(_dataService.setSimulationMode(true));
    }
  }

  late final BleService _service;
  late final BleDataService _dataService;

  Stream<KneeDataPoint> get dataStream => _dataService.stream;

  Future<void> startScan() => _service.startScan();

  Future<void> stopScan() => _service.stopScan();

  Future<void> connectToDevice(BluetoothDevice device) => _service.connectToDevice(device);

  Future<void> disconnect() => _service.disconnect();

  Future<void> setSimulationMode(bool enabled) => _service.setSimulationMode(enabled);

  @override
  void dispose() {
    unawaited(_dataService.dispose());
    _service.dispose();
    super.dispose();
  }
}