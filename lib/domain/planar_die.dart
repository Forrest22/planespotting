import 'dart:math';

/// The faces of the planar die: one Planeswalk, one Chaos and four blanks.
enum DieFace { planeswalk, chaos, blank }

/// The faces a rolling die flashes through before landing on [result] (the last entry).
/// Neighbours always differ, so every tick of the animation is visible.
List<DieFace> rollFlicker(DieFace result, Random random, {int length = 9}) {
  final faces = [result];
  while (faces.length < length) {
    final others = DieFace.values.where((face) => face != faces.first).toList();
    faces.insert(0, others[random.nextInt(others.length)]);
  }
  return faces;
}

// Each face of the roll lasts this much longer than the one before, so it starts fast and slows sharply.
const double _flickerGrowth = 1.35;

// The last change happens at this fraction of the roll; the result then holds for the remainder.
const double _flickerSettle = 0.88;

/// Which of [faces] the roll animation shows at [progress] (0 to 1): a geometric schedule with
/// short early gaps (a blur) and long late ones (suspense) before landing on the last face.
int flickerIndex(double progress, int faces) {
  if (faces <= 1) return 0;
  final changes = faces - 1;
  final scale = _flickerSettle / (pow(_flickerGrowth, changes) - 1);
  var index = 0;
  while (index < changes && progress >= scale * (pow(_flickerGrowth, index + 1) - 1)) {
    index++;
  }
  return index;
}

DieFace rollPlanarDie(Random random) {
  return switch (random.nextInt(6)) {
    0 => DieFace.planeswalk,
    1 => DieFace.chaos,
    _ => DieFace.blank,
  };
}
