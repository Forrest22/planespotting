import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:planespotting/domain/planar_die.dart';

// Small-size variants of cards-lens.svg and chaos.svg: the originals are too detailed for a die face.
const String planeswalkFaceAsset = 'assets/die/planeswalk_small.svg';
const String chaosFaceAsset = 'assets/die/chaos_small.svg';

// The die stays light in dark mode too, so the black artwork stays readable.
const Color _dieColor = Color(0xFFF3EAD3);
const Color _dieInk = Color(0xFF2B2A28);

/// What is printed on a die face: the SVG, a letter if it can't be loaded, or nothing for a blank.
class PlanarDieGlyph extends StatelessWidget {
  const PlanarDieGlyph({super.key, required this.face, this.size = 32, this.color = _dieInk});

  final DieFace? face;
  final double size;

  /// The ink colour. The artwork is single-colour, so it can be tinted to suit its background.
  final Color color;

  @override
  Widget build(BuildContext context) {
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

/// A small die face for the result banner and the start screen.
class PlanarDieFace extends StatelessWidget {
  const PlanarDieFace({super.key, required this.face, this.size = 56});

  final DieFace? face;
  final double size;

  static const double _border = 2;

  @override
  Widget build(BuildContext context) {
    // Whole pixels all round, so the artwork's edges land on pixel boundaries and stay crisp.
    final padding = (size / 12).roundToDouble();
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _dieColor,
        border: Border.all(color: _dieInk, width: _border),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: PlanarDieGlyph(face: face, size: size - 2 * padding - 2 * _border),
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
    required this.rolling,
    required this.flicker,
    required this.onRoll,
  });

  /// The face at rest.
  final DieFace? face;
  final AnimationController rolling;
  final List<DieFace> flicker;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      side: const BorderSide(color: _dieInk, width: 2.5),
      borderRadius: BorderRadius.circular(20),
    );
    // Bigger than the default FAB, because the faces are detailed.
    return FloatingActionButtonTheme(
      data: const FloatingActionButtonThemeData(largeSizeConstraints: BoxConstraints.tightFor(width: 64, height: 64)),
      child: FloatingActionButton.large(
        tooltip: 'Roll planar die',
        backgroundColor: _dieColor,
        foregroundColor: _dieInk,
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
              child: PlanarDieGlyph(key: ValueKey(shown), face: shown, size: 56),
            );
          },
        ),
      ),
    );
  }
}
