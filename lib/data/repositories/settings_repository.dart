import 'package:flutter/foundation.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/services/settings_service.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

/// Which sets/types are enabled and which cards are excluded.
///
/// Sets default to enabled, except funny (Un-set) sets, which default to off.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._service);

  final SettingsService _service;
  final Map<String, bool> _sets = {};
  final Map<CardType, bool> _types = {};
  Set<String> _denylist = {};

  Set<String> get denylist => Set.unmodifiable(_denylist);

  Future<void> load(List<CardSet> sets) async {
    for (final set in sets) {
      _sets[set.code] = _service.getBool('set_${set.code}') ?? !set.funny;
    }
    for (final type in CardType.values) {
      _types[type] = _service.getBool('type_${type.name}') ?? true;
    }
    _denylist = _service.getStringList('denylist').toSet();
  }

  bool isSetEnabled(String code) => _sets[code] ?? false;

  bool isTypeEnabled(CardType type) => _types[type] ?? true;

  Set<String> get enabledSets => {
        for (final entry in _sets.entries)
          if (entry.value) entry.key,
      };

  Set<CardType> get enabledTypes => {
        for (final entry in _types.entries)
          if (entry.value) entry.key,
      };

  Future<void> setSetEnabled(String code, bool enabled) async {
    _sets[code] = enabled;
    notifyListeners();
    await _service.setBool('set_$code', enabled);
  }

  Future<void> setTypeEnabled(CardType type, bool enabled) async {
    _types[type] = enabled;
    notifyListeners();
    await _service.setBool('type_${type.name}', enabled);
  }

  Future<void> setCardExcluded(String cardId, bool excluded) async {
    final updated = {..._denylist};
    excluded ? updated.add(cardId) : updated.remove(cardId);
    _denylist = updated;
    notifyListeners();
    await _service.setStringList('denylist', _denylist.toList());
  }
}
