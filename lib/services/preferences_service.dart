import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _simModeKey = 'simulationMode';
  static const String _simPatternKey = 'simulationPattern';
  static const String _maxAngleKey = 'maxAngleThreshold';
  static const String _minAngleKey = 'minAngleThreshold';
  static const String _suddenMovementKey = 'suddenMovementThreshold';
  static const String _alertsEnabledKey = 'alertsEnabled';
  static const String _dailyStepGoalKey = 'dailyStepGoal';
  static const String _exerciseMinutesGoalKey = 'exerciseMinutesGoal';
  static const String _activeHoursGoalKey = 'activeHoursGoal';

  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Default to true if not set, as per requirements
    if (!_prefs.containsKey(_simModeKey)) {
      await _prefs.setBool(_simModeKey, true);
    }
    if (!_prefs.containsKey(_simPatternKey)) {
      await _prefs.setString(_simPatternKey, 'random');
    }
    if (!_prefs.containsKey(_dailyStepGoalKey)) {
      await _prefs.setInt(_dailyStepGoalKey, 8000);
    }
    if (!_prefs.containsKey(_exerciseMinutesGoalKey)) {
      await _prefs.setInt(_exerciseMinutesGoalKey, 30);
    }
    if (!_prefs.containsKey(_activeHoursGoalKey)) {
      await _prefs.setDouble(_activeHoursGoalKey, 6.0);
    }
  }

  // ── Simulation Mode ──────────────────────────────────────────────────

  static bool get isSimulationMode => _prefs.getBool(_simModeKey) ?? true;

  static Future<void> setSimulationMode(bool value) async {
    await _prefs.setBool(_simModeKey, value);
  }

  static String get simulationPattern =>
      _prefs.getString(_simPatternKey) ?? 'random';

  static Future<void> setSimulationPattern(String value) async {
    await _prefs.setString(_simPatternKey, value);
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

  // ── Goals ────────────────────────────────────────────────────────────

  static int get dailyStepGoal => _prefs.getInt(_dailyStepGoalKey) ?? 8000;

  static Future<void> setDailyStepGoal(int value) async {
    await _prefs.setInt(_dailyStepGoalKey, value);
  }

  static int get exerciseMinutesGoal =>
      _prefs.getInt(_exerciseMinutesGoalKey) ?? 30;

  static Future<void> setExerciseMinutesGoal(int value) async {
    await _prefs.setInt(_exerciseMinutesGoalKey, value);
  }

  static double get activeHoursGoal =>
      _prefs.getDouble(_activeHoursGoalKey) ?? 6.0;

  static Future<void> setActiveHoursGoal(double value) async {
    await _prefs.setDouble(_activeHoursGoalKey, value);
  }
}
