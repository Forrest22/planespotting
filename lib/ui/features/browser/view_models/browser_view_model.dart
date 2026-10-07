import 'package:flutter/foundation.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

/// Search and filter state for the card browser, plus excluding cards from the game.
///
/// The set and type filters only narrow what the browser lists; which sets and types the
/// game draws from is set in the deck settings sheet.
class BrowserViewModel extends ChangeNotifier {
  BrowserViewModel({required CardRepository cardRepository, required SettingsRepository settingsRepository})
      : _cards = cardRepository,
        _settings = settingsRepository {
    _settings.addListener(notifyListeners);
  }

  final CardRepository _cards;
  final SettingsRepository _settings;

  String _query = '';
  final Set<String> _selectedSets = {};
  final Set<CardType> _selectedTypes = {};
  bool _excludedOnly = false;
  bool _includedOnly = false;

  String get query => _query;
  Set<String> get selectedSets => Set.unmodifiable(_selectedSets);
  Set<CardType> get selectedTypes => Set.unmodifiable(_selectedTypes);
  bool get excludedOnly => _excludedOnly;

  /// Only cards the game can draw: not excluded, and in a set and of a type that are on.
  bool get includedOnly => _includedOnly;
  List<CardSet> get sets => _cards.sets;

  bool get hasActiveFilters =>
      _query.isNotEmpty || _selectedSets.isNotEmpty || _selectedTypes.isNotEmpty || _excludedOnly || _includedOnly;

  /// Cards passing every filter, in repository order, except that cards whose set or type is
  /// turned off in the deck settings come last. (Cards excluded one by one stay where they are, so a tile
  /// doesn't jump away the moment you exclude it.) An empty set or type selection means all.
  List<PlanechaseCard> get entries {
    final shown = _filtered;
    return [
      ...shown.where((card) => !isOutOfDeck(card)),
      ...shown.where(isOutOfDeck),
    ];
  }

  List<PlanechaseCard> get _filtered {
    final needle = _query.trim().toLowerCase();
    return _cards.cards.where((card) {
      if (_selectedSets.isNotEmpty && !_selectedSets.contains(card.set)) return false;
      if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(card.type)) return false;
      if (_excludedOnly && !isExcluded(card)) return false;
      if (_includedOnly && !isInPlay(card)) return false;
      if (needle.isEmpty) return true;
      return card.name.toLowerCase().contains(needle) ||
          card.oracleText.toLowerCase().contains(needle) ||
          card.artist.toLowerCase().contains(needle);
    }).toList();
  }

  /// Excluded one by one, as opposed to out of the deck because its set or type is off.
  bool isExcluded(PlanechaseCard card) => _settings.isExcluded(card.id);

  /// Whether the game can draw this card.
  bool isInPlay(PlanechaseCard card) =>
      _settings.isSetEnabled(card.set) && _settings.isTypeEnabled(card.type) && !isExcluded(card);

  /// Out of the deck because its set or type is off in the deck settings, rather than excluded on its own.
  bool isOutOfDeck(PlanechaseCard card) => !_settings.isSetEnabled(card.set) || !_settings.isTypeEnabled(card.type);

  /// Cards the game will actually draw from: enabled sets and types, minus excluded cards.
  int get deckCount => _cards
      .filter(enabledSets: _settings.enabledSets, enabledTypes: _settings.enabledTypes, denylist: _settings.denylist)
      .length;

  Future<void> toggleExcluded(PlanechaseCard card) => _settings.setCardExcluded(card.id, !isExcluded(card));

  /// How many of the cards now shown a bulk exclude / include would change.
  int get excludableCount => _filtered.where((card) => !isExcluded(card)).length;
  int get includableCount => _filtered.where(isExcluded).length;

  /// Excludes every card now shown (after search and filters) from the game.
  Future<void> excludeShown() =>
      _settings.setCardsExcluded(_filtered.where((card) => !isExcluded(card)).map((card) => card.id), true);

  /// Puts every excluded card now shown back into the game.
  Future<void> includeShown() =>
      _settings.setCardsExcluded(_filtered.where(isExcluded).map((card) => card.id), false);

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void toggleSet(String code) {
    if (!_selectedSets.remove(code)) _selectedSets.add(code);
    notifyListeners();
  }

  void toggleType(CardType type) {
    if (!_selectedTypes.remove(type)) _selectedTypes.add(type);
    notifyListeners();
  }

  // Excluded only and included only can't both hold, so turning one on turns the other off.
  void setExcludedOnly(bool value) {
    _excludedOnly = value;
    if (value) _includedOnly = false;
    notifyListeners();
  }

  void setIncludedOnly(bool value) {
    _includedOnly = value;
    if (value) _excludedOnly = false;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _selectedSets.clear();
    _selectedTypes.clear();
    _excludedOnly = false;
    _includedOnly = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
