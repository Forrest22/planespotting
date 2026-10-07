import 'package:flutter/material.dart';
import 'package:planespotting/ui/core/ui_constants.dart';

/// A card's outline: a rounded rectangle whose corner radius is a fixed share of its short side,
/// like a real card's, cut in a hair from the image's edge. The card files have their transparent
/// corners filled in (black or white) and a faint fringe on the outermost pixels, so clipping and
/// shadows must follow the card's own corner size at any display size.
class CardBorder extends ShapeBorder {
  const CardBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final side = rect.shortestSide;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect.deflate(side * cardEdgeTrim), Radius.circular(side * cardCornerRatio)));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
