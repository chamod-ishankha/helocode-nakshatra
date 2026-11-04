import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/semantic_colors.dart';

/// One choice of a [PillSegments].
typedef PillSegment<T> = ({T value, String label});

/// A segmented control as a pill with a raised thumb (KAN-80).
///
/// Labels wrap rather than truncate: "Navāṁśa (D9)" is short in English and
/// not in Tamil, and a cut-off chart name is a wrong chart name.
class PillSegments<T> extends StatelessWidget {
  const PillSegments({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.dotted = const {},
    this.dotLabel,
  });

  final List<PillSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Segments with something unread, marked with a gold dot.
  final Set<T> dotted;

  /// What the dot says to a screen reader.
  final String? dotLabel;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: Semantics(
                selected: s.value == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(s.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.value == selected
                          ? palette.surfaceHigh
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: s.value == selected
                          ? const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            s.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: s.value == selected
                                  ? palette.text
                                  : palette.muted,
                            ),
                          ),
                        ),
                        if (dotted.contains(s.value)) ...[
                          const SizedBox(width: 6),
                          UnreadDot(label: dotLabel),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The gold dot that says there is something not yet opened.
class UnreadDot extends StatelessWidget {
  const UnreadDot({this.label, super.key});

  /// What it says to a screen reader; colour alone says nothing there.
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: context.semantic.accent,
        shape: BoxShape.circle,
      ),
    ),
  );
}
