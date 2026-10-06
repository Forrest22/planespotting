import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over [SharedPreferences].
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsService> create() async {
    return SettingsService(await SharedPreferences.getInstance());
  }

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  List<String> getStringList(String key) => _prefs.getStringList(key) ?? const [];

  Future<void> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);
}
