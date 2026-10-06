import 'package:flutter/material.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

/// A card image with rounded corners and a soft shadow.
///
/// Card files are portrait with the card printed sideways, so [quarterTurns]
/// = 1 shows the card upright. If the file is missing (see
/// `tool/fetch_cards.py`) the card's name and text are shown instead.
class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.card, this.quarterTurns = 0});

  final PlanechaseCard card;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              card.image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _MissingImage(card: card),
            ),
          ),
        ),
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
