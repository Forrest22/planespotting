import 'package:flutter/material.dart';
import 'package:planespotting/domain/formatting.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/ui/core/ui_constants.dart';

/// The card's name, type line, rules text and artist, on a sheet attached to the bottom bar
/// (or, with a different [borderRadius], a side panel).
class CardTextPanel extends StatelessWidget {
  const CardTextPanel({
    super.key,
    required this.card,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(panelRadius)),
  });

  final PlanechaseCard card;

  /// Rounded on top by default: the bottom edge sits flush on the bar.
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final kind = card.type == CardType.plane ? 'Plane' : 'Phenomenon';
    return Material(
      elevation: 6,
      borderRadius: borderRadius,
      color: colors.surface.withValues(alpha: 0.96),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(card.id),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.name, style: theme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '$kind · ${card.setName} · ${card.number}',
                style: theme.labelLarge,
              ),
              const SizedBox(height: 12),
              // Full width so the text lines up whatever its length.
              SizedBox(
                width: double.infinity,
                child: Text(
                  formatOracleText(card.oracleText),
                  style: theme.bodyLarge,
                ),
              ),
              if (card.artist.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Illustrated by ${card.artist}',
                  style: theme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
