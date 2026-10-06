import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:planespotting/domain/planar_die.dart';

void main() {
  test('the die is one planeswalk, one chaos and four blanks', () {
    final random = Random(7);
    final tally = {for (final face in DieFace.values) face: 0};
    for (var i = 0; i < 6000; i++) {
      tally.update(rollPlanarDie(random), (n) => n + 1);
    }
    expect(tally[DieFace.planeswalk], closeTo(1000, 150));
    expect(tally[DieFace.chaos], closeTo(1000, 150));
    expect(tally[DieFace.blank], closeTo(4000, 250));
  });

  test('the roll flicker ends on the result and never repeats a face back to back', () {
    final random = Random(3);
    for (final result in DieFace.values) {
      final flicker = rollFlicker(result, random);
      expect(flicker, hasLength(9));
      expect(flicker.last, result);
      for (var i = 1; i < flicker.length; i++) {
        expect(flicker[i], isNot(flicker[i - 1]));
      }
    }
  });

  test('the flicker starts fast, slows down, and lands on the last face', () {
    const faces = 9;
    expect(flickerIndex(0, faces), 0);
    expect(flickerIndex(1, faces), faces - 1);

    // Walk the roll and record how long (in progress) each face is shown.
    final shownFor = List.filled(faces, 0.0);
    var previous = 0;
    for (var i = 0; i <= 10000; i++) {
      final index = flickerIndex(i / 10000, faces);
      expect(index, greaterThanOrEqualTo(previous)); // never goes back
      shownFor[index] += 1 / 10000;
      previous = index;
    }
    // Every middle face lasts longer than the one before it.
    for (var i = 2; i < faces - 1; i++) {
      expect(shownFor[i], greaterThan(shownFor[i - 1]));
    }
    // The first change comes quickly, and the result isn't on screen for most of the roll.
    expect(shownFor.first, lessThan(0.05));
    expect(shownFor.last, lessThan(0.2));
  });
}
