import 'package:flutter/material.dart';
import 'package:planespotting/domain/models/planechase_card.dart';
import 'package:planespotting/ui/core/card_border.dart';

/// A card image with rounded corners and a soft shadow.
///
/// Card files are portrait with the card printed sideways, so [quarterTurns]
/// = 1 shows the card upright. If the file is missing (see
/// `tool/fetch_cards.py`) the card's name and text are shown instead.
class CardImage extends StatelessWidget {
  const CardImage({
    super.key,
    required this.card,
    this.quarterTurns = 0,
    this.cacheWidth,
    this.fadeIn = false,
    this.excludeFromSemantics = false,
    this.thumbnail = false,
    this.shadow = true,
  });

  final PlanechaseCard card;
  final int quarterTurns;

  /// Decode the file at this width (in pixels) instead of full size, to keep thumbnails light.
  final int? cacheWidth;

  /// Fade the image in when it has loaded, instead of popping in. For use over a placeholder.
  final bool fadeIn;

  /// Hide the image from screen readers, when something next to it already names the card.
  final bool excludeFromSemantics;

  /// Load the small copy ([PlanechaseCard.thumbnail]) instead of the full image, which is far
  /// cheaper to decode. Falls back to the full image if the small one is missing.
  final bool thumbnail;

  /// A soft drop shadow under the card. Turn it off for many small cards at once (a grid), where
  /// the blur is costly to draw.
  final bool shadow;

  Widget _missing(BuildContext context, Object error, StackTrace? stackTrace) => _MissingImage(card: card);

  Widget _asset(String path, ImageErrorWidgetBuilder onError) {
    return Image.asset(
      path,
      semanticLabel: card.name,
      excludeFromSemantics: excludeFromSemantics,
      cacheWidth: cacheWidth,
      fit: BoxFit.contain,
      frameBuilder: fadeIn
          ? (context, child, frame, wasSynchronouslyLoaded) => wasSynchronouslyLoaded
              ? child
              : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: child,
                )
          : null,
      errorBuilder: onError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: Center(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const CardBorder(),
            shadows: shadow ? const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))] : null,
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: const CardBorder()),
            child: thumbnail
                ? _asset(card.thumbnail, (context, error, stackTrace) => _asset(card.image, _missing))
                : _asset(card.image, _missing),
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
      // Shrinks to fit a small space (e.g. a browser thumbnail) instead of overflowing.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(card.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(card.oracleText, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
