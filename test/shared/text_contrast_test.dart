import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';

void main() {
  test('Semantic text remains readable on application surfaces', () {
    const foregrounds = {
      'primary': AppColors.textPrimary,
      'secondary': AppColors.textSecondary,
      'muted': AppColors.textMuted,
      'success': AppColors.success,
      'danger': AppColors.danger,
      'warning': AppColors.warning,
      'link': AppColors.primaryPurple,
    };
    const backgrounds = [AppColors.surface, AppColors.canvas, AppColors.surfaceSecondary];
    for (final entry in foregrounds.entries) {
      for (final background in backgrounds) {
        final ratio = (entry.value.computeLuminance() + .05) /
            (background.computeLuminance() + .05);
        expect(1 / ratio, greaterThanOrEqualTo(4.5), reason: '${entry.key} on $background');
      }
    }
  });

  test('White labels remain readable across the hero gradient', () {
    for (final background in AppColors.primaryHeroGradient.colors) {
      final ratio = (Colors.white.computeLuminance() + .05) /
          (background.computeLuminance() + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });
}
