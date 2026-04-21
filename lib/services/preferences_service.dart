import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _simModeKey = 'simulationMode';
  static const String _maxAngleKey = 'maxAngleThreshold';
  static const String _minAngleKey = 'minAngleThreshold';
  static const String _suddenMovementKey = 'suddenMovementThreshold';
  static const String _alertsEnabledKey = 'alertsEnabled';

  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Default to true if not set, as per requirements
    if (!_prefs.containsKey(_simModeKey)) {
      await _prefs.setBool(_simModeKey, true);
    }
  }

  // ── Simulation Mode ──────────────────────────────────────────────────

  static bool get isSimulationMode => _prefs.getBool(_simModeKey) ?? true;

  static Future<void> setSimulationMode(bool value) async {
    await _prefs.setBool(_simModeKey, value);
  }

  // ── Alert Thresholds ─────────────────────────────────────────────────

  static double get maxAngleThreshold =>
      _prefs.getDouble(_maxAngleKey) ?? 140.0;

  static Future<void> setMaxAngleThreshold(double value) async {
    await _prefs.setDouble(_maxAngleKey, value);
  }

  static double get minAngleThreshold =>
      _prefs.getDouble(_minAngleKey) ?? 5.0;

  static Future<void> setMinAngleThreshold(double value) async {
    await _prefs.setDouble(_minAngleKey, value);
  }

  static double get suddenMovementThreshold =>
      _prefs.getDouble(_suddenMovementKey) ?? 200.0;

  static Future<void> setSuddenMovementThreshold(double value) async {
    await _prefs.setDouble(_suddenMovementKey, value);
  }

  // ── Alert Master Toggle ──────────────────────────────────────────────

  static bool get alertsEnabled =>
      _prefs.getBool(_alertsEnabledKey) ?? true;

  static Future<void> setAlertsEnabled(bool value) async {
    await _prefs.setBool(_alertsEnabledKey, value);
  }
}
