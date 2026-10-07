import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:planespotting/domain/planar_die.dart';

// Small-size variants of cards-lens.svg and chaos.svg: the originals are too detailed for a die face.
const String planeswalkFaceAsset = 'assets/die/planeswalk_small.svg';
const String chaosFaceAsset = 'assets/die/chaos_small.svg';

// One spec for the die, so the button and the start-screen face are drawn alike. The body is the
// theme's primary container, with on-primary-container ink and a primary outline, in light and dark.
double _dieRadius(double size) => size * 0.22;
double _dieBorder(double size) => (size / 32).clamp(1.5, 3.0);
// Whole pixels, so the artwork's edges land on pixel boundaries and stay crisp.
double _dieInset(double size) => (size / 12).roundToDouble();
// What is left for the glyph inside the die's border and inset.
double _dieGlyphSize(double size) => size - 2 * _dieInset(size) - 2 * _dieBorder(size);

/// What is printed on a die face: the SVG, a letter if it can't be loaded, or nothing for a blank.
class PlanarDieGlyph extends StatelessWidget {
  const PlanarDieGlyph({super.key, required this.face, this.size = 32, this.color});

  final DieFace? face;
  final double size;

  /// The ink colour, by default the theme's on-primary-container (the die's own ink). The artwork
  /// is single-colour, so it can be tinted to suit its background.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Theme.of(context).colorScheme.onPrimaryContainer;
    final (asset, letter, label) = switch (face) {
      DieFace.planeswalk => (planeswalkFaceAsset, 'P', 'Planeswalk'),
      DieFace.chaos => (chaosFaceAsset, 'C', 'Chaos'),
      _ => (null, '', 'Blank'),
    };
    // A blank (or resting) face shows a naught, so a spinning die is visible whatever it lands on.
    if (asset == null) {
      return Semantics(
        label: label,
        child: CustomPaint(size: Size.square(size), painter: _NaughtPainter(color)),
      );
    }
    return Semantics(
      label: label,
      child: SvgPicture.asset(
        asset,
        width: size,
        height: size,
        excludeFromSemantics: true,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        errorBuilder: (context, error, stackTrace) => SizedBox.square(
          dimension: size,
          child: FittedBox(
            child: Text(letter, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

/// A 0 with a line through it.
class _NaughtPainter extends CustomPainter {
  const _NaughtPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final center = size.center(Offset.zero);
    final radius = size.width * 0.3;
    canvas.drawCircle(center, radius, paint);
    // The slash runs bottom-left to top-right and pokes out past the circle.
    final reach = radius * 1.3;
    canvas.drawLine(center + Offset(-reach, reach), center + Offset(reach, -reach), paint);
  }

  @override
  bool shouldRepaint(_NaughtPainter oldDelegate) => oldDelegate.color != color;
}

/// A die face drawn as a die: the start screen's resting face. The banner uses just the symbol.
class PlanarDieFace extends StatelessWidget {
  const PlanarDieFace({super.key, required this.face, this.size = 56});

  final DieFace? face;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(_dieInset(size)),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        border: Border.all(color: scheme.primary, width: _dieBorder(size)),
        borderRadius: BorderRadius.circular(_dieRadius(size)),
      ),
      child: PlanarDieGlyph(face: face, size: _dieGlyphSize(size)),
    );
  }
}

/// The roll button, sitting in the bottom bar. While [rolling] runs it flashes through [flicker]
/// like a slot machine, fast at first and slowing down until it lands on the last face. The screen
/// owns the animation so the keyboard shortcut and the button share one code path.
class PlanarDieButton extends StatelessWidget {
  const PlanarDieButton({
    super.key,
    required this.face,
    this.size = 64,
    required this.rolling,
    required this.flicker,
    required this.onRoll,
  });

  /// The face at rest.
  final DieFace? face;

  /// Width and height of the button.
  final double size;
  final AnimationController rolling;
  final List<DieFace> flicker;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      side: BorderSide(color: scheme.primary, width: _dieBorder(size)),
      borderRadius: BorderRadius.circular(_dieRadius(size)),
    );
    // Bigger than the default FAB, because the faces are detailed.
    return FloatingActionButtonTheme(
      data: FloatingActionButtonThemeData(largeSizeConstraints: BoxConstraints.tightFor(width: size, height: size)),
      child: FloatingActionButton.large(
        tooltip: 'Roll die',
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: shape,
        onPressed: onRoll,
        child: AnimatedBuilder(
          animation: rolling,
          builder: (context, _) {
            var shown = face;
            if (rolling.isAnimating && flicker.isNotEmpty) {
              // Quick blur at first, then each face lingers longer as the die comes to rest.
              shown = flicker[flickerIndex(rolling.value, flicker.length)];
            }
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 60),
              child: PlanarDieGlyph(key: ValueKey(shown), face: shown, size: _dieGlyphSize(size)),
            );
          },
        ),
      ),
    );
  }
}
