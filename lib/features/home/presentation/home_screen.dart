import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/ads/banner_ad_slot.dart';
import '../../../core/ads/rewarded_unlock.dart';
import '../../../core/ads/rewarded_unlock_card.dart';
import '../../../core/astro/calendar_models.dart';
import '../../../core/astro/panchanga_models.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/purchases/purchase_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../profiles/presentation/add_family_member.dart';
import '../domain/daily_providers.dart';
import '../domain/rahu_now.dart';

/// Built at each use rather than once: a format made at first use keeps the
/// language it was made in, so after switching to Tamil every time on the
/// page still said ප.ව.
DateFormat get _time => DateFormat('h:mm a');

/// The screen users open every morning.
///
/// Retention and ad revenue both rest on this, so the thing people actually
/// came for — rāhu kālaya — is above the fold and never more than a glance
/// away (KAN-92: the hero card, with the day drawn as an arc).
///
/// The app bar went with the redesign. Chart, settings and the account moved
/// into the bottom bar, where they are one tap from anywhere rather than only
/// from here, and the language button into settings, which is now a tab with
/// a symbol for a label — reachable by someone who cannot read the language
/// the app is stuck in, which was the reason the button sat up here.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  /// Ticks on the minute rather than every sixty seconds from whenever the
  /// screen opened, so "Rāhu until 12:00 PM" goes at 12:00 and not at 12:00
  /// and fifty-nine seconds.
  void _scheduleTick() {
    final now = DateTime.now();
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    _timer = Timer(next.difference(now), () {
      if (!mounted) return;
      ref.read(clockProvider.notifier).tick();
      _scheduleTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A new day starts at the top. The calendar hands a day to this tab and
    // switches to it, and the tab kept wherever it had last been scrolled
    // to — the chosen day's rāhu kālaya was off the top of the screen.
    ref.listen(selectedDateProvider, (_, _) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final profile = ref.watch(profileProvider);
    final panchanga = ref.watch(panchangaProvider);
    final palette = BrandPalette.of(context);
    final l = L10n.of(context);

    // Today and every day behind it are free; days ahead are the reward.
    // Looking back has little value to sell, and someone checking what the
    // nekath was last Tuesday should not be made to watch anything.
    //
    // The gate is on the day being *shown*, not on the arrows that move it.
    // The calendar hands a date straight to this screen, so a gate on the
    // switcher alone would be bypassed with one tap.
    final selected = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    final isAhead = selected.isAfter(DateTime(now.year, now.month, now.day));
    final dayLocked =
        isAhead &&
        !ref.watch(unlockStoreProvider).isOpen(RewardedUnlock.futureDay);

    if (profile == null || panchanga == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // The page's own gutter, applied per child rather than to the list, so
    // the explore row can run to the screen edges and scroll under them.
    Widget gutter(Widget child, {double top = 14}) =>
        Padding(padding: EdgeInsets.fromLTRB(18, top, 18, 0), child: child);

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backdrop),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            // Recomputing is cheap, but a pull-to-refresh is what users reach
            // for when a day rolls over while the app is open.
            onRefresh: () async {
              ref.read(clockProvider.notifier).tick();
              ref.invalidate(panchangaProvider);
              await Future<void>.delayed(const Duration(milliseconds: 250));
            },
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.only(top: 4, bottom: 32),
              children: [
                gutter(const _Header(), top: 2),
                gutter(const _DateRow(), top: 6),
                if (dayLocked)
                  gutter(
                    RewardedUnlockCard(
                      unlock: RewardedUnlock.futureDay,
                      title: l.unlockFutureTitle,
                      body: l.unlockFutureBody,
                    ),
                    top: 16,
                  )
                else ...[
                  const _PoyaTodayBanner(),
                  const _NowBanner(),
                  gutter(_RahuHero(panchanga: panchanga), top: 16),
                  gutter(_PanchangaTiles(panchanga: panchanga)),
                  gutter(_SunMoonCard(panchanga: panchanga)),
                  gutter(const _OtherPeriods()),
                  gutter(const _ClearTimes()),
                ],
                gutter(const _ComingUp()),
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: _ExploreRow(),
                ),
                gutter(const _StillToCome()),
                gutter(
                  Text(
                    l.entertainmentOnly,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                  top: 22,
                ),
                // Last thing on the page, well below the rāhu kālaya card and
                // every other control, and the list's bottom padding keeps it
                // clear of the tab bar beneath. Nothing here reveals a
                // reading, so there is no button an accidental tap could be
                // mistaken for.
                const BannerAdSlot(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Today" over the weekday, and the rāhu chip beside them.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final date = ref.watch(selectedDateProvider);
    final now = ref.watch(clockProvider);

    final days = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    final when = switch (days) {
      0 => l.today,
      1 => l.tomorrowLower,
      > 1 => l.inDays(days),
      -1 => l.yesterdayLower,
      _ => l.homeDaysAgo(-days),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                toBeginningOfSentenceCase(when),
                style: TextStyle(fontSize: 13, color: palette.muted),
              ),
              Text(
                DateFormat('EEEE').format(date),
                style: BrandFonts.displayStyle(
                  context,
                  size: 28,
                  color: palette.text,
                ),
              ),
            ],
          ),
        ),
        if (days == 0) const _RahuChip(),
      ],
    );
  }
}

/// When rāhu kālaya ends, or when it starts — only while it is still ahead
/// or running today. After it has gone there is nothing worth a chip.
///
/// A time rather than a countdown ("ends in 28 min"): a countdown is stale
/// the moment it is read, and a time is what the almanac on the wall says.
class _RahuChip extends ConsumerWidget {
  const _RahuChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final semantic = context.semantic;
    final rahu = _rahuOf(ref);
    if (rahu == null) return const SizedBox.shrink();

    final label = switch (RahuNow.of(rahu, ref.watch(clockProvider)).phase) {
      RahuPhase.ahead => l.homeRahuAt(_time.format(rahu.start)),
      RahuPhase.running => l.homeRahuUntil(_time.format(rahu.end)),
      RahuPhase.past => null,
    };
    if (label == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsetsDirectional.only(start: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: semantic.accentSurface,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: semantic.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: semantic.accent,
            ),
          ),
        ],
      ),
    );
  }
}

TimeWindow? _rahuOf(WidgetRef ref) {
  for (final w in ref.watch(inauspiciousProvider)) {
    if (w.kind == WindowKind.rahu) return w;
  }
  return null;
}

class _DateRow extends ConsumerWidget {
  const _DateRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final date = ref.watch(selectedDateProvider);
    final notifier = ref.read(selectedDateProvider.notifier);
    final isToday = isSameDay(date, ref.watch(clockProvider));

    return Row(
      children: [
        RoundIconButton(
          icon: Icons.chevron_left,
          tooltip: l.homePreviousDay,
          onPressed: () => notifier.shift(-1),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                DateFormat('d MMMM yyyy').format(date),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
              if (!isToday)
                TextButton(
                  onPressed: notifier.today,
                  style: TextButton.styleFrom(
                    foregroundColor: context.semantic.accent,
                    minimumSize: const Size(48, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l.today),
                ),
            ],
          ),
        ),
        RoundIconButton(
          icon: Icons.chevron_right,
          tooltip: l.homeNextDay,
          onPressed: () => notifier.shift(1),
        ),
      ],
    );
  }
}

/// Shown when the selected day is itself a poya.
class _PoyaTodayBanner extends ConsumerWidget {
  const _PoyaTodayBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poya = ref.watch(poyaTodayProvider);
    if (poya == null) return const SizedBox.shrink();

    final semantic = context.semantic;
    final palette = BrandPalette.of(context);
    final fullMoon = L10n.of(
      context,
    ).homeFullMoonAt(_time.format(poya.fullMoon));

    return _Banner(
      border: semantic.accent,
      fill: semantic.accentSurface,
      icon: Icon(Icons.circle_outlined, size: 20, color: semantic.accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No English name underneath. A poya is the same word either way —
          // பினர is Binara — so a second line only repeated itself in Latin
          // letters.
          Text(
            poya.label(AppLocale.of(context)),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: semantic.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(fullMoon, style: TextStyle(fontSize: 13, color: palette.muted)),
          // A line of its own: the significance is English-only until a
          // native writer has it (KAN-62), and it must not take the
          // translated time down with it.
          if (poya.note != null)
            Text(
              poya.note!,
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
        ],
      ),
    );
  }
}

/// Shown only while an inauspicious period is running right now.
class _NowBanner extends ConsumerWidget {
  const _NowBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentlyInauspiciousProvider);
    if (current == null) return const SizedBox.shrink();
    final semantic = context.semantic;

    return _Banner(
      border: semantic.inauspicious,
      fill: semantic.inauspiciousSurface,
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 20,
        color: semantic.inauspicious,
      ),
      child: Text(
        // Was an English sentence built inline, so the one banner that
        // interrupts a reader mid-day spoke English at them whatever language
        // the app was in (KAN-59).
        L10n.of(context).homeWindowRunningNow(
          current.kind.label(AppLocale.of(context)),
          _time.format(current.end),
        ),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: BrandPalette.of(context).text,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.border,
    required this.fill,
    required this.icon,
    required this.child,
  });

  final Color border;
  final Color fill;
  final Widget icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// The headline. This is what the app is opened for.
class _RahuHero extends ConsumerWidget {
  const _RahuHero({required this.panchanga});

  final Panchanga panchanga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final bad = semantic.inauspicious;
    final rahu = _rahuOf(ref);
    if (rahu == null) return const SizedBox.shrink();

    final now = ref.watch(clockProvider);
    final isToday = isSameDay(ref.watch(selectedDateProvider), now);
    final state = RahuNow.of(rahu, now);
    final running = isToday && state.phase == RahuPhase.running;

    // The red is laid onto the card colour before it goes into the gradient,
    // so the stops share one transparency. A gradient from a strong red to a
    // clear one interpolates colour and alpha separately and goes muddy in
    // the middle — the brown blob the chart's centre had (KAN-83).
    Color wash(double a) =>
        Color.alphaBlend(bad.withValues(alpha: a), palette.surface);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: bad),
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          stops: const [0, 0.55, 1],
          colors: [wash(0.16), wash(0.04), palette.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 20, color: bad),
                        const SizedBox(width: 8),
                        // The reader's own name for it, in their own script.
                        // It used to lead with රාහු කාලය in every language,
                        // which put a script a Tamil reader does not read at
                        // the top of the card the app is opened for.
                        Flexible(
                          child: Text(
                            l.homeRahuKalaya,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: bad,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Body face, not the display face: Fraunces' 3 and 4 are
                    // easy to misread, and these are the digits people act on.
                    for (final line in [
                      '${_time.format(rahu.start)} –',
                      _time.format(rahu.end),
                    ])
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 34,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: bad,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      l.homeAvoidImportant,
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        border: Border.all(color: palette.line),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        l.durationMinutes(rahu.duration.inMinutes),
                        style: TextStyle(fontSize: 13, color: palette.text),
                      ),
                    ),
                  ],
                ),
              ),
              if (running) ...[
                const SizedBox(width: 12),
                _ProgressRing(progress: state.progress),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _DayArc(
            panchanga: panchanga,
            rahu: rahu,
            sunAt: isToday ? now : null,
          ),
        ],
      ),
    );
  }
}

/// How much of a running rāhu kālaya has gone.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final percent = '${(progress * 100).round()}%';
    return Semantics(
      label: percent,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 64,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress,
            track: palette.line,
            fill: context.semantic.inauspicious,
          ),
          child: Center(
            child: Text(
              percent,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

/// The day from sunrise to sunset as an arc, rāhu kālaya marked on it, and
/// the sun where it is now when the day shown is today.
///
/// A picture of the same times the card prints, not new information: it
/// answers "how long until" at a glance, which the numbers make you work out.
class _DayArc extends StatelessWidget {
  const _DayArc({required this.panchanga, required this.rahu, this.sunAt});

  final Panchanga panchanga;
  final TimeWindow rahu;
  final DateTime? sunAt;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final rise = _time.format(panchanga.sunrise);
    final set = _time.format(panchanga.sunset);
    double at(DateTime t) =>
        dayFraction(panchanga.sunrise, panchanga.sunset, t);

    return Semantics(
      label: L10n.of(context).homeDayArc(rise, set),
      excludeSemantics: true,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 320 / 112,
            child: CustomPaint(
              painter: _ArcPainter(
                rahuFrom: at(rahu.start),
                rahuTo: at(rahu.end),
                sun: sunAt == null ? null : at(sunAt!),
                gold: semantic.accent,
                line: palette.line,
                bad: semantic.inauspicious,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final t in [rise, set])
                  Text(t, style: TextStyle(fontSize: 12, color: palette.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.rahuFrom,
    required this.rahuTo,
    required this.sun,
    required this.gold,
    required this.line,
    required this.bad,
  });

  final double rahuFrom;
  final double rahuTo;
  final double? sun;
  final Color gold;
  final Color line;
  final Color bad;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in the mock's 320 × 112 box and scaled to fit, so the proportions
    // are the mock's whatever the width.
    final k = size.width / 320;
    canvas.scale(k);

    // Half an ellipse over the horizon. Time runs evenly along the angle, so
    // noon is at the top and a 90-minute window is the same length morning
    // or afternoon.
    Offset point(double f) {
      final a = math.pi * (1 - f);
      return Offset(160 + 150 * math.cos(a), 100 - 90 * math.sin(a));
    }

    Path arc(double from, double to) {
      final path = Path()..moveTo(point(from).dx, point(from).dy);
      const steps = 64;
      for (var i = 1; i <= steps; i++) {
        final p = point(from + (to - from) * i / steps);
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    final day = arc(0, 1);
    canvas.drawPath(
      Path.from(day)..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gold.withValues(alpha: 0.18), gold.withValues(alpha: 0)],
        ).createShader(const Rect.fromLTWH(0, 10, 320, 90)),
    );

    final dots = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final metric in day.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 2), dots);
      }
    }

    if (rahuTo > rahuFrom) {
      canvas.drawPath(
        arc(rahuFrom, rahuTo),
        Paint()
          ..color = bad
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    canvas.drawLine(
      const Offset(6, 100),
      const Offset(314, 100),
      Paint()
        ..color = line
        ..strokeWidth = 1,
    );

    if (sun != null) {
      final c = point(sun!);
      canvas.drawCircle(c, 14, Paint()..color = gold.withValues(alpha: 0.25));
      canvas.drawCircle(c, 8, Paint()..color = gold);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.rahuFrom != rahuFrom ||
      old.rahuTo != rahuTo ||
      old.sun != sun ||
      old.gold != gold ||
      old.line != line ||
      old.bad != bad;
}

/// The five limbs: vāra across the top, the four that change during the day
/// in a grid, each with the time it gives way.
class _PanchangaTiles extends StatelessWidget {
  const _PanchangaTiles({required this.panchanga});

  final Panchanga panchanga;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final locale = AppLocale.of(context);

    String? until(DateTime? end) =>
        end == null ? null : l.homeRunningUntil(_time.format(end));

    Widget pair(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
        ],
      ),
    );

    return Column(
      children: [
        // Vāra stays although the weekday heads the page: it runs sunrise to
        // sunrise, it is one of the five limbs the almanac is named for, and
        // its name here is the almanac's, not the calendar's.
        _Tile(label: l.panchangaVara, value: panchanga.vara.label(locale)),
        const SizedBox(height: 10),
        pair(
          _Tile(
            label: l.panchangaTithi,
            value: panchanga.tithi.value.label(locale),
            note: panchanga.paksha.describe(locale),
            until: until(panchanga.tithi.endsAt),
          ),
          _Tile(
            label: l.panchangaNakshatra,
            value: panchanga.nakshatra.value.label(locale),
            until: until(panchanga.nakshatra.endsAt),
          ),
        ),
        const SizedBox(height: 10),
        pair(
          _Tile(
            label: l.panchangaYoga,
            value: panchanga.yoga.value.label(locale),
            until: until(panchanga.yoga.endsAt),
          ),
          _Tile(
            label: l.panchangaKarana,
            value: panchanga.karana.value.label(locale),
            warning: panchanga.karana.value.isInauspicious,
            until: until(panchanga.karana.endsAt),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    this.note,
    this.until,
    this.warning = false,
  });

  final String label;
  final String value;
  final String? note;
  final String? until;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final small = TextStyle(fontSize: 12, color: palette.muted);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: small),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: value,
              children: [
                // An icon as well as the word: Viṣṭi is a karaṇa to avoid,
                // and the old "⚠" was an emoji that drew in colour on some
                // phones and as a box on others.
                if (warning)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 6),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: context.semantic.inauspicious,
                      ),
                    ),
                  ),
              ],
            ),
            style: TextStyle(fontWeight: FontWeight.w600, color: palette.text),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(note!, style: small),
          ],
          if (until != null) ...[
            const SizedBox(height: 2),
            Text(until!, style: small),
          ],
        ],
      ),
    );
  }
}

class _SunMoonCard extends StatelessWidget {
  const _SunMoonCard({required this.panchanga});

  final Panchanga panchanga;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final gold = context.semantic.accent;
    final violet = BrandPalette.of(context).violet;

    return BrandCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _item(
            context,
            Icons.wb_twilight,
            gold,
            _time.format(panchanga.sunrise),
            l.homeSunrise,
          ),
          _item(
            context,
            Icons.wb_sunny_outlined,
            gold,
            _time.format(panchanga.sunset),
            l.homeSunset,
          ),
          _item(
            context,
            Icons.nightlight_outlined,
            violet,
            panchanga.moonrise == null
                ? '—'
                : _time.format(panchanga.moonrise!),
            l.homeMoonrise,
          ),
        ],
      ),
    );
  }

  /// One of the three columns.
  ///
  /// [Expanded] rather than intrinsic width: three unconstrained columns
  /// overflowed by 7px on சூரிய அஸ்தமனம். The time sits above its label, so
  /// a label that wraps to two lines only pushes itself down and the three
  /// times stay on one line.
  Widget _item(
    BuildContext c,
    IconData icon,
    Color colour,
    String time,
    String label,
  ) {
    final palette = BrandPalette.of(c);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: colour),
          const SizedBox(height: 6),
          Text(
            time,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _OtherPeriods extends ConsumerWidget {
  const _OtherPeriods();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = BrandPalette.of(context);
    final bad = context.semantic.inauspicious;
    final windows = ref
        .watch(inauspiciousProvider)
        .where((w) => w.kind != WindowKind.rahu)
        .toList();

    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(L10n.of(context).homeOtherInauspicious),
          const SizedBox(height: 8),
          for (final (i, w) in windows.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: palette.line)),
              ),
              // A Wrap, not a Row: the name and the time sit on one line when
              // they fit and on two when they do not. Neither half can be made
              // short enough for one line in every language — யமகண்டம்
              // broke across a line in the middle of the word.
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: bad),
                        const SizedBox(width: 8),
                        Text(
                          w.kind.label(AppLocale.of(context)),
                          style: TextStyle(color: palette.text),
                        ),
                      ],
                    ),
                    Text(
                      '${_time.format(w.start)} – ${_time.format(w.end)}',
                      style: TextStyle(color: palette.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClearTimes extends ConsumerWidget {
  const _ClearTimes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final good = context.semantic.auspicious;
    final windows = ref.watch(auspiciousProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.semantic.auspiciousSurface,
        borderRadius: BorderRadius.circular(BrandCard.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 20, color: good),
              const SizedBox(width: 8),
              Expanded(child: _CardTitle(l.homeClearTimes, colour: good)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.homeClearTimesHelp,
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
          const SizedBox(height: 6),
          for (final w in windows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: good),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${_time.format(w.start)} – ${_time.format(w.end)}',
                      style: TextStyle(color: palette.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The next poya, and the next festival if that is a different day.
class _ComingUp extends ConsumerWidget {
  const _ComingUp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final poya = ref.watch(nextPoyaProvider);
    final festival = ref.watch(nextFestivalProvider);
    if (poya == null) return const SizedBox.shrink();

    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final entries = <Festival>[
      poya,
      if (festival != null && festival.date != poya.date) festival,
    ]..sort((a, b) => a.date.compareTo(b.date));

    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(l.homeComingUp),
          const SizedBox(height: 6),
          for (final (i, f) in entries.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: palette.line)),
              ),
              child: Row(
                children: [
                  // A full moon for a poya, a celebration for the rest — a
                  // shape each, so the two are told apart without the colour.
                  f.kind == FestivalKind.poya
                      ? Icon(
                          Icons.circle_outlined,
                          size: 20,
                          color: semantic.accent,
                        )
                      : Icon(
                          Icons.celebration_outlined,
                          size: 20,
                          color: semantic.auspicious,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.label(AppLocale.of(context)),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.text,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM').format(f.date),
                          style: TextStyle(fontSize: 12, color: palette.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _countdown(l, f.daysFrom(date)),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: semantic.accent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _countdown(L10n l, int days) => switch (days) {
    0 => l.todayLower,
    1 => l.tomorrowLower,
    _ => l.inDays(days),
  };
}

/// The other places to go, as a row that scrolls sideways.
///
/// Calendar and compatibility are tabs now, but they stay here too, phrased
/// as what you would use them for: the bar says where things are, this says
/// why you might want them this morning.
class _ExploreRow extends ConsumerWidget {
  const _ExploreRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);

    // Several saved charts is the one Pro feature no rewarded ad can open,
    // and in this market the natural one — an almanac in a Sri Lankan house
    // is read for a spouse, a child, a parent (KAN-74). Last in the row: an
    // invitation, not the reason anybody opened the app this morning.
    final family = showFamilyCard(
      savedCharts: ref.watch(savedProfilesProvider).value?.length ?? 0,
      ownsFeature: ref.watch(featureProvider(PaidFeature.multipleProfiles)),
      canBuy: ref.watch(purchasesAvailableProvider),
    );

    final cards = [
      _ExploreCard(
        icon: Icons.calendar_month_outlined,
        title: l.calendarTitle,
        subtitle: l.calendarPickActivity,
        onTap: () => context.go(Routes.calendar),
      ),
      _ExploreCard(
        icon: Icons.favorite_border_rounded,
        title: l.compatTitle,
        subtitle: l.compatIntro,
        onTap: () => context.go(Routes.compatibility),
      ),
      _ExploreCard(
        icon: Icons.auto_awesome_outlined,
        title: l.horoscopeTitle,
        subtitle: l.homeHoroscopeSubtitle,
        onTap: () => context.push(Routes.horoscope),
      ),
      if (family)
        _ExploreCard(
          icon: Icons.group_add_outlined,
          title: l.familyAddTitle,
          subtitle: l.familyAddSubtitle,
          onTap: () => addFamilyMember(context, ref),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, card) in cards.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              card,
            ],
          ],
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return SizedBox(
      width: 150,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: context.semantic.accent),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Honest note on the festivals that are left out.
///
/// Deliberately not filled with guesses: a confidently wrong religious date
/// would undermine the accuracy the rest of the app is built on.
class _StillToCome extends StatelessWidget {
  const _StillToCome();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: palette.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.homeStillToCome,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.homeFestivalsExcluded,
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text, {this.colour});

  final String text;
  final Color? colour;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: colour ?? BrandPalette.of(context).text,
    ),
  );
}
