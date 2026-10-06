import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/data/services/card_asset_service.dart';
import 'package:planespotting/data/services/settings_service.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

PlanechaseCard testCard(
  String name, {
  String set = 'moc',
  String number = '1',
  CardType type = CardType.plane,
  bool funny = false,
}) {
  return PlanechaseCard(
    name: name,
    set: set,
    setName: switch (set) {
      'moc' => 'March of the Machine Commander',
      'who' => 'Doctor Who',
      _ => 'Unknown Event',
    },
    number: number,
    type: type,
    oracleText: 'Text for $name',
    image: 'assets/cards/$set-$number.webp',
    funny: funny,
  );
}

final List<PlanechaseCard> sampleCards = [
  testCard('Esper', set: 'moc', number: '49'),
  testCard('Chaotic Aether', set: 'moc', number: '141', type: CardType.phenomenon),
  testCard('TARDIS Bay', set: 'who', number: '600'),
  testCard('Amy\'s Home', set: 'who', number: '566'),
  testCard('The Bean', set: 'punk', number: 'PLA002a', funny: true),
];

class FakeCardAssetService implements CardAssetService {
  FakeCardAssetService([List<PlanechaseCard>? cards]) : _cards = cards ?? sampleCards;

  final List<PlanechaseCard> _cards;

  @override
  Future<List<PlanechaseCard>> loadCards() async => _cards;
}

Future<CardRepository> loadedCardRepository([List<PlanechaseCard>? cards]) async {
  final repository = CardRepository(FakeCardAssetService(cards));
  await repository.load();
  return repository;
}

Future<SettingsRepository> loadedSettingsRepository(
  CardRepository cards, [
  Map<String, Object> initialValues = const {},
]) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return loadedSettingsRepositoryFromExisting(cards);
}

/// Builds a repository over whatever [SharedPreferences] currently holds.
Future<SettingsRepository> loadedSettingsRepositoryFromExisting(CardRepository cards) async {
  final repository = SettingsRepository(await SettingsService.create());
  await repository.load(cards.sets);
  return repository;
}
