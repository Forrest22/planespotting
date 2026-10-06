enum CardType { plane, phenomenon }

class PlanechaseCard {
  final String name;
  final String set;
  final String setName;
  final String number;
  final CardType type;
  final String oracleText;

  /// Empty when the card has no credited artist (e.g. Unknown Event cards).
  final String artist;
  final String image;
  final bool funny;

  const PlanechaseCard({
    required this.name,
    required this.set,
    required this.setName,
    required this.number,
    required this.type,
    required this.oracleText,
    this.artist = '',
    required this.image,
    required this.funny,
  });

  /// A small copy of [image] (made by `tool/fetch_cards.py`) for lists and grids.
  String get thumbnail => image.replaceFirst('assets/cards/', 'assets/cards_thumb/');

  /// Stable identifier, used by the denylist.
  String get id => '$set-$number';

  factory PlanechaseCard.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'name': String name,
        'set': String set,
        'setName': String setName,
        'number': String number,
        'type': String type,
        'oracleText': String oracleText,
        'image': String image,
        'funny': bool funny,
      } =>
        PlanechaseCard(
          name: name,
          set: set,
          setName: setName,
          number: number,
          type: CardType.values.byName(type),
          oracleText: oracleText,
          artist: json['artist'] as String? ?? '',
          image: image,
          funny: funny,
        ),
      _ => throw const FormatException('Failed to load PlanechaseCard.'),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'set': set,
      'setName': setName,
      'number': number,
      'type': type.name,
      'oracleText': oracleText,
      'artist': artist,
      'image': image,
      'funny': funny,
    };
  }
}
