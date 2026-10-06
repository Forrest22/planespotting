import 'package:flutter/foundation.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

class OptionItem {
  final String label;
  final int count;

  /// Cards still in play: [count] minus the ones excluded one by one in the browser.
  final int activeCount;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const OptionItem({
    required this.label,
    required this.count,
    required this.activeCount,
    required this.enabled,
    required this.onChanged,
  });
}

class OptionSection {
  final String title;
  final List<OptionItem> items;
  final ValueChanged<bool> onSetAll;

  const OptionSection({required this.title, required this.items, required this.onSetAll});

  bool get allEnabled => items.every((item) => item.enabled);

  /// Cards covered by the enabled options in this section.
  int get enabledCardCount => items.where((item) => item.enabled).fold(0, (sum, item) => sum + item.activeCount);
}

class OptionsViewModel extends ChangeNotifier {
  OptionsViewModel({required CardRepository cardRepository, required SettingsRepository settingsRepository})
      : _cards = cardRepository,
        _settings = settingsRepository {
    _settings.addListener(notifyListeners);
  }

  final CardRepository _cards;
  final SettingsRepository _settings;

  /// Cards excluded one by one in the browser.
  int get excludedCount => _settings.denylist.length;

  Future<void> restoreExcluded() => _settings.clearExcluded();

  int _activeWhere(bool Function(PlanechaseCard card) test) =>
      _cards.cards.where((card) => test(card) && !_settings.isExcluded(card.id)).length;

  List<OptionSection> get sections {
    final sets = _cards.sets;
    return [
      _setSection('Sets', sets.where((set) => !set.funny)),
      _setSection('Un-cards', sets.where((set) => set.funny)),
      OptionSection(
        title: 'Types',
        items: [
          for (final type in CardType.values)
            OptionItem(
              label: _typeLabel(type),
              count: _cards.countOfType(type),
              activeCount: _activeWhere((card) => card.type == type),
              enabled: _settings.isTypeEnabled(type),
              onChanged: (value) => _settings.setTypeEnabled(type, value),
            ),
        ],
        onSetAll: (value) {
          for (final type in CardType.values) {
            _settings.setTypeEnabled(type, value);
          }
        },
      ),
    ];
  }

  OptionSection _setSection(String title, Iterable<CardSet> sets) {
    final list = sets.toList();
    return OptionSection(
      title: title,
      items: [
        for (final set in list)
          OptionItem(
            label: set.name,
            count: _cards.countInSet(set.code),
            activeCount: _activeWhere((card) => card.set == set.code),
            enabled: _settings.isSetEnabled(set.code),
            onChanged: (value) => _settings.setSetEnabled(set.code, value),
          ),
      ],
      onSetAll: (value) {
        for (final set in list) {
          _settings.setSetEnabled(set.code, value);
        }
      },
    );
  }

  String _typeLabel(CardType type) => switch (type) {
        CardType.plane => 'Planes',
        CardType.phenomenon => 'Phenomena',
      };

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
