import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

/// A shuffled Planechase deck with swipe-back history.
///
/// [history] always ends with one pre-drawn "upcoming" card, so a page view
/// can show it as soon as the user swipes forward.
class GameViewModel extends ChangeNotifier {
  GameViewModel({
    required CardRepository cardRepository,
    required SettingsRepository settingsRepository,
    Random? random,
  })  : _cards = cardRepository,
        _settings = settingsRepository,
        _random = random ?? Random() {
    _start();
  }

  final CardRepository _cards;
  final SettingsRepository _settings;
  final Random _random;

  final List<PlanechaseCard> _history = [];
  final List<PlanechaseCard> _deck = [];
  int _index = 0;

  List<PlanechaseCard> get history => List.unmodifiable(_history);
  int get index => _index;
  bool get hasCards => _history.isNotEmpty;
  bool get canGoBack => _index > 0;
  PlanechaseCard? get current => hasCards ? _history[_index] : null;

  void onPageChanged(int index) {
    _index = index;
    if (_index == _history.length - 1) _addUpcoming();
    notifyListeners();
  }

  /// Re-reads the settings (e.g. after the Options screen). Keeps the cards
  /// already shown and redraws the upcoming one.
  void refresh() {
    if (!hasCards) {
      _start();
    } else {
      _history.removeRange(_index + 1, _history.length);
      _deck.clear();
      _refill(exclude: {for (final card in _history) card.id});
      _addUpcoming();
    }
    notifyListeners();
  }

  void _start() {
    _history.clear();
    _deck.clear();
    _index = 0;
    _addUpcoming();
    _addUpcoming();
  }

  void _addUpcoming() {
    if (_deck.isEmpty) _refill();
    if (_deck.isNotEmpty) _history.add(_deck.removeLast());
  }

  void _refill({Set<String> exclude = const {}}) {
    final eligible = _cards
        .filter(
          enabledSets: _settings.enabledSets,
          enabledTypes: _settings.enabledTypes,
          denylist: {..._settings.denylist, ...exclude},
        )
      ..shuffle(_random);
    // Cards are drawn from the end, so don't let the card just shown come up again.
    if (_history.isNotEmpty && eligible.length > 1 && eligible.last.id == _history.last.id) {
      final last = eligible.removeLast();
      eligible.insert(0, last);
    }
    _deck.addAll(eligible);
    // Everything eligible has already been seen this pass: start a new pass.
    if (_deck.isEmpty && exclude.isNotEmpty) _refill();
  }
}
