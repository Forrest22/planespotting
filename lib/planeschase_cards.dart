import 'package:flutter/material.dart';

class PlanechaseCard {
  final String name;
  final String imagePath;
  final String setCode;
  final String cardType;
  final bool denylist;

  PlanechaseCard({
    required this.name,
    required this.imagePath,
    required this.setCode,
    required this.cardType,
    this.denylist = false,
  });
}

final List<PlanechaseCard> planechaseCards = [
  PlanechaseCard(name: "The Caldaia", imagePath: "assets/planeschase/moc-47-the-caldaia.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Enigma Ridges", imagePath: "assets/planeschase/moc-48-enigma-ridges.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Esper", imagePath: "assets/planeschase/moc-49-esper.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "The Fertile Lands of Saulvinia", imagePath: "assets/planeschase/moc-50-the-fertile-lands-of-saulvinia.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Ghirapur", imagePath: "assets/planeschase/moc-51-ghirapur.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "The Golden City of Orazca", imagePath: "assets/planeschase/moc-52-the-golden-city-of-orazca.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "The Great Aerie", imagePath: "assets/planeschase/moc-53-the-great-aerie.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Inys Haen", imagePath: "assets/planeschase/moc-54-inys-haen.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Ketria", imagePath: "assets/planeschase/moc-55-ketria.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Littiara", imagePath: "assets/planeschase/moc-56-littiara.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Megaflora Jungle", imagePath: "assets/planeschase/moc-57-megaflora-jungle.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Naktamun", imagePath: "assets/planeschase/moc-58-naktamun.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "New Argive", imagePath: "assets/planeschase/moc-59-new-argive.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Norn's Seedcore", imagePath: "assets/planeschase/moc-60-norn-s-seedcore.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Nyx", imagePath: "assets/planeschase/moc-61-nyx.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Paliano", imagePath: "assets/planeschase/moc-62-paliano.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "The Pit", imagePath: "assets/planeschase/moc-63-the-pit.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Riptide Island", imagePath: "assets/planeschase/moc-64-riptide-island.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Strixhaven", imagePath: "assets/planeschase/moc-65-strixhaven.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Ten Wizards Mountain", imagePath: "assets/planeschase/moc-66-ten-wizards-mountain.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Towashi", imagePath: "assets/planeschase/moc-67-towashi.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Unyaro", imagePath: "assets/planeschase/moc-68-unyaro.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Valor's Reach", imagePath: "assets/planeschase/moc-69-valor-s-reach.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "The Western Cloud", imagePath: "assets/planeschase/moc-70-the-western-cloud.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "The Wilds", imagePath: "assets/planeschase/moc-71-the-wilds.png", setCode: "MOC", cardType: "Plane"),
  PlanechaseCard(name: "Interplanar Tunnel", imagePath: "assets/planeschase/opca-2-interplanar-tunnel.png", setCode: "OPCA", cardType: "Phenomenon"),
  PlanechaseCard(name: "Morphic Tide", imagePath: "assets/planeschase/opca-3-morphic-tide.png", setCode: "OPCA", cardType: "Phenomenon"),
  PlanechaseCard(name: "Time Distortion", imagePath: "assets/planeschase/opca-8-time-distortion.png", setCode: "OPCA", cardType: "Phenomenon"),
  PlanechaseCard(name: "The Dark Barony", imagePath: "assets/planeschase/opca-19-the-dark-barony.png", setCode: "OPCA", cardType: "Plane"),
  PlanechaseCard(name: "Edge of Malacol", imagePath: "assets/planeschase/opca-20-edge-of-malacol.png", setCode: "OPCA", cardType: "Plane"),
  PlanechaseCard(name: "Eloren Wilds", imagePath: "assets/planeschase/opca-21-eloren-wilds.png", setCode: "OPCA", cardType: "Plane"),
  PlanechaseCard(name: "The Eon Fog", imagePath: "assets/planeschase/opca-22-the-eon-fog.png", setCode: "OPCA", cardType: "Plane"),
];

List<PlanechaseCard> filterCards({String? setCode, String? cardType, bool? denylist}) {
  return planechaseCards.where((card) {
    final matchesSetCode = setCode == null || card.setCode == setCode;
    final matchesCardType = cardType == null || card.cardType == cardType;
    final matchesDenylist = denylist == null || card.denylist == denylist;
    return matchesSetCode && matchesCardType && matchesDenylist;
  }).toList();
}

class PlanechaseViewer extends StatefulWidget {
  final List<PlanechaseCard> cards;

  const PlanechaseViewer({super.key, required this.cards});

  @override
  State<PlanechaseViewer> createState() => _PlanechaseViewerState();
}

class _PlanechaseViewerState extends State<PlanechaseViewer> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planechase Deck')),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          final card = widget.cards[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Column(
              children: [
                Text(
                  card.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        card.imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Set: ${card.setCode} · Type: ${card.cardType}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (card.denylist)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '⚠️ Denylisted',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
