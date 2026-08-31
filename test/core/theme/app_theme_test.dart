// test/core/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/theme/app_theme.dart';

/// Absolute hue distance on the 0-360° color wheel (accounting for wraparound).
double _hueDistance(double a, double b) {
  final diff = (a - b).abs() % 360;
  return diff > 180 ? 360 - diff : diff;
}

void main() {
  test(
    'AppColors.success is widely hue-separated from AppColors.biology '
    '(item 6)',
    () {
      final successHue = HSLColor.fromColor(AppColors.success).hue;
      final biologyHue = HSLColor.fromColor(AppColors.biology).hue;

      final distance = _hueDistance(successHue, biologyHue);

      // The pre-fix value was only ~16° apart — too close to read as
      // unambiguously different colors when shown together. Assert a wide
      // margin so this can't silently regress back toward biology's green.
      expect(
        distance,
        greaterThan(30),
        reason:
            'success ($successHue°) and biology ($biologyHue°) must stay '
            'clearly distinguishable — got only $distance° apart',
      );
    },
  );
}
