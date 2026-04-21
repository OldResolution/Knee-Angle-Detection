import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const Object _unsetBleField = Object();

enum BleConnectionPhase {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class BleScanState {
  const BleScanState({
    required this.results,
    required this.isScanning,
    required this.isSimulationMode,
    required this.adapterState,
    required this.canRequestEnable,
    this.errorMessage,
    this.infoMessage,
  });

  factory BleScanState.initial({required bool isSimulationMode}) {
    return BleScanState(
      results: const [],
      isScanning: false,
      isSimulationMode: isSimulationMode,
      adapterState: BluetoothAdapterState.unknown,
      canRequestEnable:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    );
  }

  final List<ScanResult> results;
  final bool isScanning;
  final bool isSimulationMode;
  final BluetoothAdapterState adapterState;
  final bool canRequestEnable;
  final String? errorMessage;
  final String? infoMessage;

  BleScanState copyWith({
    List<ScanResult>? results,
    bool? isScanning,
    bool? isSimulationMode,
    BluetoothAdapterState? adapterState,
    bool? canRequestEnable,
    Object? errorMessage = _unsetBleField,
    Object? infoMessage = _unsetBleField,
  }) {
    return BleScanState(
      results: results ?? this.results,
      isScanning: isScanning ?? this.isScanning,
      isSimulationMode: isSimulationMode ?? this.isSimulationMode,
      adapterState: adapterState ?? this.adapterState,
      canRequestEnable: canRequestEnable ?? this.canRequestEnable,
      errorMessage: identical(errorMessage, _unsetBleField)
          ? this.errorMessage
          : errorMessage as String?,
      infoMessage: identical(infoMessage, _unsetBleField)
          ? this.infoMessage
          : infoMessage as String?,
    );
  }

  bool get isBluetoothOff => adapterState == BluetoothAdapterState.off;

  String get summary {
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }

    if (isSimulationMode) {
      return infoMessage ?? 'Simulation mode active';
    }

    if (isScanning) {
      return 'Scanning for nearby devices';
    }

    if (results.isEmpty) {
      return infoMessage ?? 'No BLE devices discovered yet';
    }

    return '${results.length} device${results.length == 1 ? '' : 's'} discovered';
  }
}

class BleConnectionStateData {
  const BleConnectionStateData({
    required this.phase,
    required this.isSimulationMode,
    required this.reconnectAttempts,
    this.device,
    this.errorMessage,
    this.mtu,
    this.infoMessage,
  });

  factory BleConnectionStateData.initial({required bool isSimulationMode}) {
    return BleConnectionStateData(
      phase: BleConnectionPhase.disconnected,
      isSimulationMode: isSimulationMode,
      reconnectAttempts: 0,
    );
  }

  final BluetoothDevice? device;
  final BleConnectionPhase phase;
  final bool isSimulationMode;
  final int reconnectAttempts;
  final String? errorMessage;
  final int? mtu;
  final String? infoMessage;

  BleConnectionStateData copyWith({
    Object? device = _unsetBleField,
    BleConnectionPhase? phase,
    bool? isSimulationMode,
    int? reconnectAttempts,
    Object? errorMessage = _unsetBleField,
    Object? mtu = _unsetBleField,
    Object? infoMessage = _unsetBleField,
  }) {
    return BleConnectionStateData(
      device: identical(device, _unsetBleField)
          ? this.device
          : device as BluetoothDevice?,
      phase: phase ?? this.phase,
      isSimulationMode: isSimulationMode ?? this.isSimulationMode,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      errorMessage: identical(errorMessage, _unsetBleField)
          ? this.errorMessage
          : errorMessage as String?,
      mtu: identical(mtu, _unsetBleField) ? this.mtu : mtu as int?,
      infoMessage: identical(infoMessage, _unsetBleField)
          ? this.infoMessage
          : infoMessage as String?,
    );
  }

  String get deviceLabel => device == null ? 'No device' : _deviceName(device!);

  String get summary {
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }

    if (isSimulationMode && device == null) {
      return infoMessage ?? 'Simulation mode active';
    }

    switch (phase) {
      case BleConnectionPhase.connected:
        return mtu == null
            ? 'Connected to $deviceLabel'
            : 'Connected to $deviceLabel | MTU $mtu';
      case BleConnectionPhase.connecting:
        return 'Connecting to $deviceLabel';
      case BleConnectionPhase.reconnecting:
        return 'Reconnecting to $deviceLabel (attempt $reconnectAttempts)';
      case BleConnectionPhase.error:
        return errorMessage ?? 'Connection error';
      case BleConnectionPhase.disconnected:
        return infoMessage ??
            (device == null
                ? 'No device connected'
                : '$deviceLabel disconnected');
    }
  }

  String get phaseLabel {
    if (isSimulationMode && device == null) {
      return 'simulation';
    }

    switch (phase) {
      case BleConnectionPhase.disconnected:
        return 'disconnected';
      case BleConnectionPhase.connecting:
        return 'connecting';
      case BleConnectionPhase.connected:
        return 'connected';
      case BleConnectionPhase.reconnecting:
        return 'reconnecting';
      case BleConnectionPhase.error:
        return 'error';
    }
  }
}

class BleState {
  const BleState({
    required this.scanState,
    required this.connectionState,
  });

  factory BleState.initial({required bool isSimulationMode}) {
    return BleState(
      scanState: BleScanState.initial(isSimulationMode: isSimulationMode),
      connectionState:
          BleConnectionStateData.initial(isSimulationMode: isSimulationMode),
    );
  }

  final BleScanState scanState;
  final BleConnectionStateData connectionState;

  BleState copyWith({
    BleScanState? scanState,
    BleConnectionStateData? connectionState,
  }) {
    return BleState(
      scanState: scanState ?? this.scanState,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

typedef BleScanStateUpdater = void Function(BleScanState state);
typedef BleConnectionStateUpdater = void Function(BleConnectionStateData state);
typedef BleDeviceCallback = Future<void> Function(BluetoothDevice device);
typedef BleSimulationModeCallback = Future<void> Function(
    bool isSimulationMode);

class BleService {
  BleService({
    required bool initialSimulationMode,
    required BleScanStateUpdater onScanStateChanged,
    required BleConnectionStateUpdater onConnectionStateChanged,
    this.onDeviceConnected,
    this.onDeviceDisconnected,
    this.onSimulationModeChanged,
  })  : _simulationMode = initialSimulationMode,
        _onScanStateChanged = onScanStateChanged,
        _onConnectionStateChanged = onConnectionStateChanged {
    _scanState = BleScanState.initial(isSimulationMode: initialSimulationMode);
    _connectionState =
        BleConnectionStateData.initial(isSimulationMode: initialSimulationMode);
    _attachGlobalListeners();
  }

  static const int _maxReconnectAttempts = 3;
  static const Duration _reconnectBaseDelay = Duration(seconds: 2);

  final BleScanStateUpdater _onScanStateChanged;
  final BleConnectionStateUpdater _onConnectionStateChanged;
  final BleDeviceCallback? onDeviceConnected;
  final BleDeviceCallback? onDeviceDisconnected;
  final BleSimulationModeCallback? onSimulationModeChanged;

  late BleScanState _scanState;
  late BleConnectionStateData _connectionState;

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSubscription;
  StreamSubscription<int>? _deviceMtuSubscription;

  BluetoothDevice? _activeDevice;
  bool _simulationMode;
  bool _manualDisconnectRequested = false;
  bool _reconnectInProgress = false;
  int _reconnectAttempts = 0;
  bool _streamingStartedForActiveDevice = false;

  BluetoothDevice? get activeDevice => _activeDevice;

  void _attachGlobalListeners() {
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (_simulationMode) {
        return;
      }

      _scanState = _scanState.copyWith(
        results: List<ScanResult>.unmodifiable(results),
        errorMessage: null,
      );
      _onScanStateChanged(_scanState);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (_simulationMode) {
        return;
      }

      _scanState = _scanState.copyWith(
        isScanning: isScanning,
        errorMessage: null,
      );
      _onScanStateChanged(_scanState);
    });

    _adapterStateSubscription =
        FlutterBluePlus.adapterState.listen((adapterState) {
      if (_simulationMode) {
        return;
      }

      _scanState = _scanState.copyWith(
        adapterState: adapterState,
        errorMessage: adapterState == BluetoothAdapterState.on
            ? null
            : _scanState.errorMessage,
      );
      _onScanStateChanged(_scanState);

      if (adapterState != BluetoothAdapterState.on) {
        _scanState = _scanState.copyWith(
          isScanning: false,
          errorMessage:
              'Bluetooth adapter is $adapterState. Turn on Bluetooth to scan.',
        );
        _onScanStateChanged(_scanState);

        if (_connectionState.phase == BleConnectionPhase.connected ||
            _connectionState.phase == BleConnectionPhase.connecting) {
          _connectionState = _connectionState.copyWith(
            phase: BleConnectionPhase.error,
            errorMessage: 'Bluetooth adapter is $adapterState.',
          );
          _onConnectionStateChanged(_connectionState);
        }
      }
    });
  }

  void _emitScanState(BleScanState state) {
    _scanState = state;
    _onScanStateChanged(_scanState);
  }

  void _emitConnectionState(BleConnectionStateData state) {
    _connectionState = state;
    _onConnectionStateChanged(_connectionState);
  }

  Future<void> setSimulationMode(bool enabled) async {
    if (_simulationMode == enabled) {
      return;
    }

    if (enabled) {
      await disconnect();
      await stopScan();
    }

    _simulationMode = enabled;
    _streamingStartedForActiveDevice = false;

    _scanState = BleScanState.initial(isSimulationMode: enabled).copyWith(
      infoMessage: enabled
          ? 'Simulation mode enabled. BLE scanning is paused.'
          : 'Simulation mode disabled. Start a scan to find devices.',
    );
    _connectionState =
        BleConnectionStateData.initial(isSimulationMode: enabled).copyWith(
      infoMessage: enabled
          ? 'Simulation mode enabled. Real BLE connections are paused.'
          : 'Ready for BLE connection.',
    );

    _emitScanState(_scanState);
    _emitConnectionState(_connectionState);
    if (onSimulationModeChanged != null) {
      await onSimulationModeChanged!(enabled);
    }
  }

  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 12)}) async {
    if (_simulationMode) {
      _emitScanState(
        _scanState.copyWith(
          isScanning: false,
          errorMessage: null,
          infoMessage: 'Simulation mode enabled. Real BLE scanning is skipped.',
        ),
      );
      return;
    }

    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        final enabled = await _ensureBluetoothReady(adapterState);
        if (!enabled) {
          return;
        }
      }

      _emitScanState(
        _scanState.copyWith(
          isScanning: true,
          errorMessage: null,
          infoMessage: 'Scanning for nearby BLE devices...',
        ),
      );

      await FlutterBluePlus.startScan(timeout: timeout);
    } on TimeoutException catch (_) {
      _emitScanState(
        _scanState.copyWith(
          isScanning: false,
          errorMessage: 'Scan timed out before any results were returned.',
        ),
      );
    } catch (error) {
      _emitScanState(
        _scanState.copyWith(
          isScanning: false,
          errorMessage: 'Unable to start BLE scan: $error',
        ),
      );
    }
  }

  Future<void> stopScan() async {
    if (_simulationMode) {
      _emitScanState(
        _scanState.copyWith(
          isScanning: false,
          infoMessage: 'Simulation mode active.',
        ),
      );
      return;
    }

    try {
      await FlutterBluePlus.stopScan();
    } catch (error) {
      _emitScanState(
        _scanState.copyWith(
          isScanning: false,
          errorMessage: 'Unable to stop BLE scan: $error',
        ),
      );
    }
  }

  Future<void> requestBluetoothEnable() async {
    if (_simulationMode) {
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    await _ensureBluetoothReady(adapterState, triggeredFromStartScan: false);
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_simulationMode) {
      _emitConnectionState(
        _connectionState.copyWith(
          phase: BleConnectionPhase.disconnected,
          errorMessage:
              'Simulation mode is enabled. Real BLE connections are skipped.',
          infoMessage: 'Switch off simulation mode to connect to hardware.',
          device: null,
        ),
      );
      return;
    }

    _manualDisconnectRequested = false;
    _activeDevice = device;
    _reconnectAttempts = 0;
    _streamingStartedForActiveDevice = false;
    _attachDeviceListeners(device);

    _emitConnectionState(
      _connectionState.copyWith(
        device: device,
        phase: BleConnectionPhase.connecting,
        errorMessage: null,
        infoMessage: 'Connecting to ${_deviceName(device)}...',
      ),
    );

    try {
      await device.connect(
          timeout: const Duration(seconds: 15), autoConnect: false);
      await _requestMtu(device);
    } catch (error) {
      _emitConnectionState(
        _connectionState.copyWith(
          device: device,
          phase: BleConnectionPhase.error,
          errorMessage: 'Unable to connect to ${_deviceName(device)}: $error',
        ),
      );
      await _attemptReconnect(device, reason: 'initial connect failure');
    }
  }

  Future<void> disconnect() async {
    _manualDisconnectRequested = true;
    _reconnectInProgress = false;

    final device = _activeDevice;
    _activeDevice = null;
    _streamingStartedForActiveDevice = false;

    try {
      await device?.disconnect();
    } catch (error) {
      _emitConnectionState(
        _connectionState.copyWith(
          phase: BleConnectionPhase.disconnected,
          errorMessage: 'Disconnect failed: $error',
        ),
      );
      return;
    }

    _reconnectAttempts = 0;
    _cancelDeviceSubscriptions();
    if (device != null && onDeviceDisconnected != null) {
      await onDeviceDisconnected!(device);
    }
    _emitConnectionState(
      BleConnectionStateData.initial(isSimulationMode: _simulationMode)
          .copyWith(
        infoMessage: 'Disconnected.',
      ),
    );
  }

  Future<void> _attemptReconnect(BluetoothDevice device,
      {required String reason}) async {
    if (_manualDisconnectRequested || _simulationMode || _reconnectInProgress) {
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _emitConnectionState(
        _connectionState.copyWith(
          phase: BleConnectionPhase.error,
          errorMessage:
              'Reconnect failed after $_maxReconnectAttempts attempts.',
          infoMessage: reason,
        ),
      );
      return;
    }

    _reconnectInProgress = true;
    _reconnectAttempts += 1;

    _emitConnectionState(
      _connectionState.copyWith(
        device: device,
        phase: BleConnectionPhase.reconnecting,
        reconnectAttempts: _reconnectAttempts,
        errorMessage: null,
        infoMessage: 'Retrying $reason...',
      ),
    );

    final delay =
        Duration(seconds: _reconnectBaseDelay.inSeconds * _reconnectAttempts);
    await Future<void>.delayed(delay);

    if (_manualDisconnectRequested || _simulationMode) {
      _reconnectInProgress = false;
      return;
    }

    try {
      _attachDeviceListeners(device);
      await device.connect(
          timeout: const Duration(seconds: 15), autoConnect: false);
      await _requestMtu(device);
      _reconnectAttempts = 0;
    } catch (error) {
      _reconnectInProgress = false;
      _emitConnectionState(
        _connectionState.copyWith(
          device: device,
          phase: BleConnectionPhase.error,
          reconnectAttempts: _reconnectAttempts,
          errorMessage: 'Reconnect attempt $_reconnectAttempts failed: $error',
        ),
      );
      await _attemptReconnect(device, reason: 'reconnect failure');
      return;
    }

    _reconnectInProgress = false;
  }

  void _attachDeviceListeners(BluetoothDevice device) {
    _cancelDeviceSubscriptions();

    _deviceConnectionSubscription =
        device.connectionState.listen((connectionState) {
      if (_simulationMode) {
        return;
      }

      if (connectionState == BluetoothConnectionState.connected) {
        _reconnectInProgress = false;
        _reconnectAttempts = 0;
        _manualDisconnectRequested = false;
        _emitConnectionState(
          _connectionState.copyWith(
            device: device,
            phase: BleConnectionPhase.connected,
            errorMessage: null,
            infoMessage: 'Connected to ${_deviceName(device)}',
          ),
        );
        unawaited(_ensureStreamingStarted(device));
      } else if (connectionState == BluetoothConnectionState.disconnected) {
        _emitConnectionState(
          _connectionState.copyWith(
            device: device,
            phase: BleConnectionPhase.disconnected,
            infoMessage: 'Disconnected from ${_deviceName(device)}',
          ),
        );
        _streamingStartedForActiveDevice = false;
        if (onDeviceDisconnected != null) {
          unawaited(onDeviceDisconnected!(device));
        }
        if (!_manualDisconnectRequested) {
          unawaited(_attemptReconnect(device, reason: 'unexpected disconnect'));
        }
      } else {
        _emitConnectionState(
          _connectionState.copyWith(
            device: device,
            phase: BleConnectionPhase.connecting,
            errorMessage: null,
          ),
        );
      }
    });

    _deviceMtuSubscription = device.mtu.listen((mtu) {
      if (_simulationMode) {
        return;
      }

      _emitConnectionState(
        _connectionState.copyWith(
          device: device,
          mtu: mtu,
          errorMessage: null,
        ),
      );
      if (mtu > 0) {
        unawaited(_ensureStreamingStarted(device));
      }
    });
  }

  Future<void> _requestMtu(BluetoothDevice device) async {
    try {
      await device.requestMtu(185);
    } catch (_) {
      // Requesting MTU can fail on some platforms; connection can still proceed.
    }
  }

  Future<bool> _ensureBluetoothReady(
    BluetoothAdapterState adapterState, {
    bool triggeredFromStartScan = true,
  }) async {
    if (adapterState == BluetoothAdapterState.on) {
      return true;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _emitScanState(
        _scanState.copyWith(
          errorMessage: null,
          infoMessage: triggeredFromStartScan
              ? 'Bluetooth is off. Asking Android to turn it on...'
              : 'Requesting Bluetooth to turn on...',
        ),
      );
      try {
        await FlutterBluePlus.turnOn();
        final readyState = await FlutterBluePlus.adapterState
            .firstWhere(
          (state) => state == BluetoothAdapterState.on,
          orElse: () => adapterState,
        )
            .timeout(const Duration(seconds: 20), onTimeout: () {
          return adapterState;
        });

        if (readyState == BluetoothAdapterState.on) {
          _emitScanState(
            _scanState.copyWith(
              adapterState: readyState,
              errorMessage: null,
              infoMessage: 'Bluetooth enabled. Ready to scan.',
            ),
          );
          return true;
        }
      } catch (error) {
        _emitScanState(
          _scanState.copyWith(
            isScanning: false,
            errorMessage:
                'Bluetooth needs to be turned on before scanning: $error',
          ),
        );
        return false;
      }
    }

    _emitScanState(
      _scanState.copyWith(
        isScanning: false,
        errorMessage:
            'Bluetooth adapter is $adapterState. Please enable Bluetooth and try again.',
      ),
    );
    return false;
  }

  Future<void> _ensureStreamingStarted(BluetoothDevice device) async {
    if (_streamingStartedForActiveDevice || _simulationMode) {
      return;
    }

    if (_connectionState.phase != BleConnectionPhase.connected) {
      return;
    }

    _streamingStartedForActiveDevice = true;
    if (onDeviceConnected != null) {
      try {
        await onDeviceConnected!(device);
      } catch (_) {
        _streamingStartedForActiveDevice = false;
      }
    }
  }

  void _cancelDeviceSubscriptions() {
    unawaited(_deviceConnectionSubscription?.cancel());
    unawaited(_deviceMtuSubscription?.cancel());
    _deviceConnectionSubscription = null;
    _deviceMtuSubscription = null;
  }

  void dispose() {
    _manualDisconnectRequested = true;
    _reconnectInProgress = false;
    _cancelDeviceSubscriptions();
    unawaited(_scanResultsSubscription?.cancel());
    unawaited(_isScanningSubscription?.cancel());
    unawaited(_adapterStateSubscription?.cancel());
  }
}

String _deviceName(BluetoothDevice device) {
  final platformName = device.platformName;
  if (platformName.isNotEmpty) {
    return platformName;
  }

  return device.remoteId.str;
}
