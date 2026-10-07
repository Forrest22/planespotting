import 'package:flutter/foundation.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';

class OptionsViewModel extends ChangeNotifier {
  OptionsViewModel({required CardRepository cardRepository, required SettingsRepository settingsRepository})
      : _cards = cardRepository,
        _settings = settingsRepository {
    _settings.addListener(notifyListeners);
  }

  final CardRepository _cards;
  final SettingsRepository _settings;

  bool get autoPlaneswalk => _settings.autoPlaneswalk;

  Future<void> setAutoPlaneswalk(bool value) => _settings.setAutoPlaneswalk(value);

  /// Cards the game will actually draw from: enabled sets and types, minus excluded cards.
  int get deckCount => _cards
      .filter(enabledSets: _settings.enabledSets, enabledTypes: _settings.enabledTypes, denylist: _settings.denylist)
      .length;

  bool get keepScreenOn => _settings.keepScreenOn;

  Future<void> setKeepScreenOn(bool value) => _settings.setKeepScreenOn(value);

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
