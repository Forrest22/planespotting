import 'package:flutter/material.dart';
import 'package:planespotting/ui/core/card_image.dart';
import 'package:planespotting/domain/models/planechase_card.dart';

/// How far a card can be pinched in.
const double cardMaxZoom = 4;

/// A [TransformationController] that also says whether the card is zoomed in, so screens can stop
/// the page view from turning pages while the card is being panned.
class CardZoomController extends TransformationController {
  CardZoomController() {
    addListener(_update);
  }

  /// Changes only when the card crosses between zoomed in and not.
  final ValueNotifier<bool> zoomed = ValueNotifier(false);

  bool get isZoomed => zoomed.value;

  void _update() => zoomed.value = value.getMaxScaleOnAxis() > 1.01;

  void reset() => value = Matrix4.identity();

  @override
  void dispose() {
    zoomed.dispose();
    super.dispose();
  }
}

/// A card that can be pinched to zoom, turned upright in a wide window. Used for each page of
/// the game and of the browser's viewer.
class ZoomableCard extends StatelessWidget {
  const ZoomableCard({
    super.key,
    required this.card,
    required this.controller,
    this.extraTurns = 0,
    this.onDoubleTapDown,
    this.onDoubleTap,
  });

  final PlanechaseCard card;
  final CardZoomController controller;

  /// Quarter turns on top of the automatic fit.
  final int extraTurns;
  final GestureTapDownCallback? onDoubleTapDown;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The card file is portrait with sideways text: a tall window shows it as is, and a
          // wide one turns it upright.
          final autoTurns = constraints.maxWidth > constraints.maxHeight ? 1 : 0;
          return GestureDetector(
            onDoubleTapDown: onDoubleTapDown,
            onDoubleTap: onDoubleTap,
            child: InteractiveViewer(
              transformationController: controller,
              maxScale: cardMaxZoom,
              panEnabled: controller.isZoomed,
              child: CardImage(card: card, quarterTurns: (autoTurns + extraTurns) % 4),
            ),
          );
        },
      ),
    );
  }
}
