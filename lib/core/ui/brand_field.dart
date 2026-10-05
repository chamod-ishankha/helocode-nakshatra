import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/semantic_colors.dart';

/// The redesign's text field: a filled, rounded box with a gold focus ring
/// (KAN-82). Shared by onboarding and the partner form, which ask for the same
/// details and should look like the same form.
InputDecoration brandFieldDecoration(
  BuildContext context, {
  String? label,
  IconData? icon,
}) {
  final palette = BrandPalette.of(context);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon, color: palette.muted),
    filled: true,
    fillColor: palette.surface,
    labelStyle: TextStyle(color: palette.muted),
    floatingLabelStyle: TextStyle(color: context.semantic.accent),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: border(palette.line),
    enabledBorder: border(palette.line),
    focusedBorder: border(context.semantic.accent, 1.5),
  );
}
