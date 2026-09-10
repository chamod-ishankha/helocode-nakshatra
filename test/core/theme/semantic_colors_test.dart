import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/core/theme/semantic_colors.dart';

/// The colours that carry meaning (KAN-51).
///
/// This app tells people which times are favourable and which to avoid, so a
/// colour that cannot be read, or cannot be told apart, is not a cosmetic
/// problem. The numbers here are WCAG relative luminance and contrast, checked
/// against the surfaces Material actually generates rather than against
/// assumed ones.
void main() {
  /// WCAG 2.1 relative luminance.
  double luminance(Color c) {
    double channel(double v) =>
        v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;

    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Simulates the two common red-green deficiencies, in linear RGB.
  Color asSeenWith(Color c, String kind) {
    double lin(double v) =>
        v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
    double enc(double v) {
      final x = v.clamp(0.0, 1.0);
      return x <= 0.0031308 ? 12.92 * x : 1.055 * math.pow(x, 1 / 2.4) - 0.055;
    }

    final r = lin(c.r);
    final g = lin(c.g);
    final b = lin(c.b);

    final (double rr, double gg, double bb) = kind == 'protanopia'
        ? (
            0.170556992 * r + 0.829443014 * g,
            0.170556991 * r + 0.829443008 * g,
            -0.004517144 * r + 0.004517144 * g + b,
          )
        : (
            0.33066007 * r + 0.66933993 * g,
            0.33066007 * r + 0.66933993 * g,
            -0.02785538 * r + 0.02785538 * g + b,
          );

    return Color.from(alpha: 1, red: enc(rr), green: enc(gg), blue: enc(bb));
  }

  final light = AppTheme.light(AppLocale.en);
  final dark = AppTheme.dark(AppLocale.en);

  group('every meaning-carrying colour is readable on its own surface', () {
    // 4.5:1 is the WCAG AA threshold for body text. These are used for values
    // a person reads and acts on — the start of rāhu kālaya, a nekath window —
    // so the text threshold is the right one, not the large-text one.
    const required = 4.5;

    for (final (name, theme) in [('light', light), ('dark', dark)]) {
      final colours = theme.extension<SemanticColors>()!;
      final surface = theme.colorScheme.surface;

      test('on the $name theme', () {
        for (final (label, colour) in [
          ('accent', colours.accent),
          ('inauspicious', colours.inauspicious),
          ('auspicious', colours.auspicious),
        ]) {
          final ratio = contrast(colour, surface);
          expect(
            ratio,
            greaterThanOrEqualTo(required),
            reason:
                '$label on the $name surface is only '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
      });
    }

    test('the theme really hands them over', () {
      // The extension is what makes `context.semantic` correct. Forget to
      // register it and every screen silently falls back to the light set,
      // including on the dark theme.
      expect(light.extension<SemanticColors>(), SemanticColors.light);
      expect(dark.extension<SemanticColors>(), SemanticColors.dark);
    });
  });

  group('colour alone cannot carry the meaning', () {
    // The finding this whole design rests on, pinned so it is not quietly
    // "fixed" later by someone picking nicer colours.
    //
    // Red for inauspicious and green for auspicious is the reading this
    // audience expects, and roughly one Sri Lankan man in twelve cannot see
    // the difference. Separating them under that deficiency needs a difference
    // in *lightness*, and a red dark enough to manage it stops reading as red.
    //
    // So the rule is the other one: every place these appear must also carry a
    // word, an icon or a shape. If this test ever starts failing, somebody has
    // found a pair that works and the rule can be relaxed — check the claim
    // carefully before believing it.
    for (final (name, colours) in [
      ('light', SemanticColors.light),
      ('dark', SemanticColors.dark),
    ]) {
      test('on the $name theme they stay indistinguishable', () {
        for (final kind in ['protanopia', 'deuteranopia']) {
          final ratio = contrast(
            asSeenWith(colours.inauspicious, kind),
            asSeenWith(colours.auspicious, kind),
          );
          expect(
            ratio,
            lessThan(3.0),
            reason:
                'with $kind the pair is ${ratio.toStringAsFixed(2)}:1 apart — '
                'if that is genuinely above 3:1, the never-colour-alone note '
                'in SemanticColors needs revisiting',
          );
        }
      });
    }
  });

  group('what the old palette got wrong', () {
    test('one constant could not have covered both surfaces', () {
      // The reason these are a pair rather than a constant. The previous gold
      // measured 8.03:1 on the dark surface and 2.26:1 on the light one, and
      // no single gold clears 4.5:1 on both.
      const oldGold = Color(0xFFD4A24C);

      expect(contrast(oldGold, dark.colorScheme.surface), greaterThan(4.5));
      expect(contrast(oldGold, light.colorScheme.surface), lessThan(4.5));
    });
  });
}
