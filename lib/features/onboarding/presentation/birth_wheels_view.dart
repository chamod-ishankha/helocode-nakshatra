import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../domain/birth_wheels.dart';

/// Day, month and year on three wheels, inline (KAN-82).
///
/// Replaces the Material date dialog, which opened a calendar on today: a
/// reader born in 1966 paged back sixty years a month at a time, or found the
/// year list behind a tap nobody knew was there. A wheel per part is how
/// birth dates are entered on every form here, and it is all on one screen.
class BirthDateWheels extends StatefulWidget {
  const BirthDateWheels({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Null until the reader moves a wheel. The wheels show a starting point,
  /// but a starting point is not an answer.
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  State<BirthDateWheels> createState() => _BirthDateWheelsState();
}

class _BirthDateWheelsState extends State<BirthDateWheels> {
  late final DateTime _today = DateUtils.dateOnly(DateTime.now());
  late final List<int> _years = BirthWheels.years(_today);

  /// Where the wheels open when nothing is chosen yet: an adult's birth year,
  /// so most readers scroll a few years rather than a century.
  late DateTime _shown = widget.value ?? DateTime(_today.year - 25, 1, 1);

  late final _year = FixedExtentScrollController(
    initialItem: _years.indexOf(_shown.year),
  );

  void _set({int? year, int? month, int? day}) {
    final settled = BirthWheels.settle(
      year: year ?? _shown.year,
      month: month ?? _shown.month,
      day: day ?? _shown.day,
      today: _today,
    );
    setState(() => _shown = settled);
    widget.onChanged(settled);
  }

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = BirthWheels.monthCount(_shown.year, _today);
    final days = BirthWheels.dayCount(_shown.year, _shown.month, _today);
    final monthName = DateFormat.MMMM();

    return _WheelRow(
      children: [
        // Keyed on how many items they hold, so a wheel whose range changed —
        // February after March, this year after last — is rebuilt on the
        // settled value instead of pointing past its own end.
        _Wheel(
          key: ValueKey('day$days'),
          flex: 2,
          count: days,
          initial: _shown.day - 1,
          label: (i) => '${i + 1}',
          onSelected: (i) => _set(day: i + 1),
        ),
        _Wheel(
          key: ValueKey('month$months'),
          flex: 4,
          count: months,
          initial: _shown.month - 1,
          label: (i) => monthName.format(DateTime(2000, i + 1)),
          onSelected: (i) => _set(month: i + 1),
        ),
        _Wheel(
          flex: 3,
          count: _years.length,
          controller: _year,
          label: (i) => '${_years[i]}',
          onSelected: (i) => _set(year: _years[i]),
        ),
      ],
    );
  }
}

/// Hour, minute, and morning or afternoon (KAN-82).
///
/// Twelve-hour with the marker in the reader's language, because that is how
/// a birth time is written on a certificate here. The minutes wheel loops, so
/// 59 is one flick from 00.
class BirthTimeWheels extends StatefulWidget {
  const BirthTimeWheels({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final Duration? value;

  /// False when the reader has said they do not know the time. The wheels
  /// stay visible, dimmed, so un-ticking the box returns them to where they
  /// were.
  final bool enabled;
  final ValueChanged<Duration> onChanged;

  @override
  State<BirthTimeWheels> createState() => _BirthTimeWheelsState();
}

class _BirthTimeWheelsState extends State<BirthTimeWheels> {
  /// Six in the morning when nothing is chosen: the sunrise fallback, so a
  /// reader who scrolls nothing and ticks "I don't know" sees the time used.
  late var _shown = BirthWheels.wheelsFor(
    widget.value ?? const Duration(hours: 6),
  );

  void _set({int? hour12, int? minute, bool? pm}) {
    _shown = (
      hour12: hour12 ?? _shown.hour12,
      minute: minute ?? _shown.minute,
      pm: pm ?? _shown.pm,
    );
    widget.onChanged(
      BirthWheels.timeOf(
        hour12: _shown.hour12,
        minute: _shown.minute,
        pm: _shown.pm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The markers come from the locale, never "AM"/"PM" by hand: the time
    // step once printed English in a Sinhala app exactly that way.
    final marker = DateFormat('a');
    final markers = [
      marker.format(DateTime(2000, 1, 1, 9)),
      marker.format(DateTime(2000, 1, 1, 21)),
    ];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.enabled ? 1 : 0.35,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: _WheelRow(
          children: [
            _Wheel(
              flex: 3,
              count: 12,
              looping: true,
              initial: _shown.hour12 - 1,
              label: (i) => '${i + 1}',
              onSelected: (i) => _set(hour12: i + 1),
            ),
            _Wheel(
              flex: 3,
              count: 60,
              looping: true,
              initial: _shown.minute,
              label: (i) => i.toString().padLeft(2, '0'),
              onSelected: (i) => _set(minute: i),
            ),
            _Wheel(
              flex: 3,
              count: 2,
              initial: _shown.pm ? 1 : 0,
              label: (i) => markers[i],
              onSelected: (i) => _set(pm: i == 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelRow extends StatelessWidget {
  const _WheelRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          children[i],
        ],
      ],
    ),
  );
}

class _Wheel extends StatefulWidget {
  const _Wheel({
    super.key,
    required this.flex,
    required this.count,
    required this.label,
    required this.onSelected,
    this.initial = 0,
    this.controller,
    this.looping = false,
  });

  final int flex;
  final int count;
  final int initial;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  /// Supplied when the parent has to keep the position across rebuilds.
  final FixedExtentScrollController? controller;
  final bool looping;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  FixedExtentScrollController? _own;

  FixedExtentScrollController get _controller =>
      widget.controller ??
      (_own ??= FixedExtentScrollController(
        initialItem: widget.initial.clamp(0, widget.count - 1),
      ));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final gold = context.semantic.accent;

    return Expanded(
      flex: widget.flex,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.line),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CupertinoPicker(
            scrollController: _controller,
            itemExtent: 44,
            diameterRatio: 1.6,
            squeeze: 1,
            useMagnifier: true,
            magnification: 1.12,
            looping: widget.looping,
            selectionOverlay: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.14),
                border: Border.all(color: gold),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSelectedItemChanged: (i) => widget.onSelected(i % widget.count),
            children: [
              for (var i = 0; i < widget.count; i++)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label(i),
                        style: TextStyle(
                          fontFamilyFallback: AppTheme.scriptFallbacks,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
