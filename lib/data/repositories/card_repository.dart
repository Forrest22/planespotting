import 'package:planespotting/data/services/card_asset_service.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

class CardSet {
  final String code;
  final String name;
  final bool funny;

  const CardSet({required this.code, required this.name, required this.funny});
}

class CardRepository {
  CardRepository(this._service);

  final CardAssetService _service;
  List<PlanechaseCard> _cards = const [];

  List<PlanechaseCard> get cards => _cards;

  Future<void> load() async {
    _cards = await _service.loadCards();
  }

  /// Distinct sets in the order they first appear in the card data.
  List<CardSet> get sets {
    final seen = <String, CardSet>{};
    for (final card in _cards) {
      seen.putIfAbsent(card.set, () => CardSet(code: card.set, name: card.setName, funny: card.funny));
    }
    return seen.values.toList();
  }

  List<PlanechaseCard> filter({
    required Set<String> enabledSets,
    required Set<CardType> enabledTypes,
    Set<String> denylist = const {},
  }) {
    return _cards
        .where((card) =>
            enabledSets.contains(card.set) && enabledTypes.contains(card.type) && !denylist.contains(card.id))
        .toList();
  }

  int countInSet(String setCode) => _cards.where((card) => card.set == setCode).length;

  int countOfType(CardType type) => _cards.where((card) => card.type == type).length;
}
