import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen from sleeping. Never throws: on a platform without wakelock support (or where
/// the plugin isn't registered, as in tests) the calls do nothing.
class ScreenAwakeService {
  const ScreenAwakeService();

  Future<void> enable() => _set(true);

  Future<void> disable() => _set(false);

  Future<void> _set(bool enable) async {
    try {
      await WakelockPlus.toggle(enable: enable);
    } catch (_) {
      // Unsupported platform or missing plugin: the screen just sleeps as usual.
    }
  }
}
