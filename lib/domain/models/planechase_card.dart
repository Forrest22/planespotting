enum CardType { plane, phenomenon }

class PlanechaseCard {
  final String name;
  final String set;
  final String setName;
  final String number;
  final CardType type;
  final String oracleText;
  final String image;
  final bool funny;

  const PlanechaseCard({
    required this.name,
    required this.set,
    required this.setName,
    required this.number,
    required this.type,
    required this.oracleText,
    required this.image,
    required this.funny,
  });

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
      'image': image,
      'funny': funny,
    };
  }
}
