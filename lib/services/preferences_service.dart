import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _simModeKey = 'simulationMode';

  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Default to true if not set, as per requirements
    if (!_prefs.containsKey(_simModeKey)) {
      await _prefs.setBool(_simModeKey, true);
    }
  }

  static bool get isSimulationMode => _prefs.getBool(_simModeKey) ?? true;

  static Future<void> setSimulationMode(bool value) async {
    await _prefs.setBool(_simModeKey, value);
  }
}
