import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/domain/planar_die.dart';

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
  /// The plane in play, or null until the game has started (see [start]).
  PlanechaseCard? get current => hasCards && _started ? _history[_index] : null;

  bool _started = false;

  /// False until the first planeswalk reveals a card. The deck is already drawn by then.
  bool get started => _started;

  /// Reveals the first card.
  void start() {
    if (_started || !hasCards) return;
    _started = true;
    notifyListeners();
  }

  DieFace? _lastRoll;
  int _rollCount = 0;

  /// The result of the latest die roll on the current plane, if any.
  DieFace? get lastRoll => _lastRoll;

  /// Rolls so far, so the UI can tell two identical results in a row apart.
  int get rollCount => _rollCount;

  DieFace? _pendingRoll;

  /// Starts a roll and returns the face it will land on, so the UI can animate towards it.
  /// The very first roll is always a planeswalk: it reveals the opening plane.
  DieFace beginRoll() => _pendingRoll = _started ? rollPlanarDie(_random) : DieFace.planeswalk;

  /// Lands the roll begun with [beginRoll] and returns the face it landed on. Returns null when
  /// nothing was pending, or for the opening roll, which only reveals the first plane.
  DieFace? finishRoll() {
    final result = _pendingRoll;
    if (result == null) return null;
    _pendingRoll = null;
    if (!_started) {
      start();
      return null;
    }
    _lastRoll = result;
    _rollCount++;
    notifyListeners();
    return result;
  }

  void onPageChanged(int index) {
    _started = true;
    _index = index;
    // A result belongs to the plane it was rolled on.
    _lastRoll = null;
    if (_index == _history.length - 1) _addUpcoming();
    notifyListeners();
  }

  /// Re-reads the settings (e.g. after the Options screen). Keeps the cards
  /// already shown and redraws the upcoming one.
  void refresh() {
    if (!hasCards || !_started) {
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
