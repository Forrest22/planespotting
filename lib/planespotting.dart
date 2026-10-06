import 'dart:math';

import 'package:flutter/material.dart';
import 'package:planespotting/data/repositories/card_repository.dart';
import 'package:planespotting/data/repositories/settings_repository.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/routes.dart';

class PlaneschasingStartPage extends StatefulWidget {
  const PlaneschasingStartPage({super.key, required this.cardRepository, required this.settingsRepository});

  final CardRepository cardRepository;
  final SettingsRepository settingsRepository;

  @override
  PlaneschasingStartPageState createState() => PlaneschasingStartPageState();
}

class PlaneschasingStartPageState extends State<PlaneschasingStartPage> {
  bool _isExpanded = false;

  PlanechaseCard? _card;

  // Picks a random card from the cards allowed by the saved options.
  void _reroll() {
    final settings = widget.settingsRepository;
    final candidates = widget.cardRepository.filter(
      enabledSets: settings.enabledSets,
      enabledTypes: settings.enabledTypes,
      denylist: settings.denylist,
    );

    setState(() {
      _card = candidates.isEmpty ? null : candidates[Random().nextInt(candidates.length)];
    });
  }

  // Function to handle image rotation
  void _rotate() {
    // Logic to rotate the image (you can modify the angle as needed)
    setState(() {
      // Toggle the rotation angle
      _imageRotation = (_imageRotation + 90) % 360;
    });
  }

  double _imageRotation = 90;

  @override
  void initState() {
    super.initState(); // make sure this is called in the beggining
    _reroll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Planeschasing View")),
      body: Stack(
        children: [
          Center(
            child: _card == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No cards match your options'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, optionsRoute).then((_) => _reroll()),
                        child: const Text('Open Options'),
                      ),
                    ],
                  )
                : Transform.rotate(
                    angle: _imageRotation * 3.14159 / 180, // Rotate image based on angle
                    child: Image.asset(
                      _card!.image,
                      // Falls back to text if the image wasn't downloaded (see tool/fetch_cards.py).
                      errorBuilder: (context, error, stackTrace) => _MissingImage(card: _card!),
                    ),
                  ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              child: _isExpanded
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Reroll Button
                        IconButton(
                          key: ValueKey('reroll'),
                          icon: Icon(Icons.autorenew),
                          onPressed: _reroll,
                          tooltip: 'New Card',
                        ),
                        SizedBox(width: 10),
                        // Rotate Button
                        IconButton(
                          key: ValueKey('rotate'),
                          icon: Icon(Icons.rotate_right),
                          onPressed: _rotate,
                          tooltip: 'Rotate Image',
                        ),
                      ],
                    )
                  : FloatingActionButton(
                      key: ValueKey('fab'),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Icon(Icons.add),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingImage extends StatelessWidget {
  const _MissingImage({required this.card});

  final PlanechaseCard card;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(card.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(card.oracleText, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
