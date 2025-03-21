// ignore_for_file: non_constant_identifier_names

class SetCode {
  final String setCode;
  final String fullSetName;
  
  SetCode({required this.setCode, required this.fullSetName});
}

class CardType {
  final String cardType;

  CardType({required this.cardType});
}

// PlanechaseCard class to represent each card's details
class PlanechaseCard {
  final String name;
  final String imagePath;
  final SetCode setCode;
  final CardType cardType;
  final bool denylist; // TODO: future denylist

  PlanechaseCard({
    required this.name,
    required this.imagePath,
    required this.setCode,
    required this.cardType,
    this.denylist = false,

  });
}

final CardTypePlane = CardType(cardType: "Plane");
final CardTypePhenomenon = CardType(cardType: "Phenomenon");


final SetCodeMOC = SetCode(setCode: "MOC", fullSetName: "March of the Machine Commander");
final SetCodeOPCA = SetCode(setCode: "OPCA", fullSetName: "Planechase Anthology Planes");

// List of all available planechase cards from multiple sets
final List<PlanechaseCard> planechaseCards = [
  // from MOC 
  PlanechaseCard(name: "The Caldaia", imagePath: "assets/planeschase/moc-47-the-caldaia.png", setCode: SetCodeMOC, cardType: CardTypePlane),
  PlanechaseCard(name: "Planewide Disaster", imagePath: "assets/planeschase/moc-154-planewide-disaster.png", setCode: SetCodeMOC, cardType: CardTypePhenomenon),
  PlanechaseCard(name: "Reality Shaping", imagePath: "assets/planeschase/moc-155-reality-shaping.png", setCode: SetCodeMOC, cardType: CardTypePhenomenon),
  PlanechaseCard(name: "Selesnya Loft Gardens", imagePath: "assets/planeschase/moc-156-selesnya-loft-gardens.png", setCode: SetCodeMOC, cardType: CardTypePlane),
  PlanechaseCard(name: "Sokenzan", imagePath: "assets/planeschase/moc-157-sokenzan.png", setCode: SetCodeMOC, cardType: CardTypePlane),

  // from OPCA
  PlanechaseCard(name: "Time Distortion", imagePath: "assets/planeschase/opca-8-time-distortion.png", setCode: SetCodeOPCA, cardType: CardTypePhenomenon),
  PlanechaseCard(name: "The Zephyr Maze", imagePath: "assets/planeschase/opca-86-the-zephyr-maze.png", setCode: SetCodeOPCA, cardType: CardTypePlane),
  // Add the rest of the cards following the same pattern here.
];

List<PlanechaseCard> filterCards({SetCode? setCode, CardType? cardType, bool? denylist}) {
  return planechaseCards.where((card) {
    final matchesSetCode = setCode == null || card.setCode == setCode;
    final matchesCardType = cardType == null || card.cardType == cardType;
    final matchesDenylist = denylist == null || card.denylist == denylist;
    return matchesSetCode && matchesCardType && matchesDenylist;
  }).toList();
}