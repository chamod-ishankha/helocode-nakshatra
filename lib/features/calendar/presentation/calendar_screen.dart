import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/astro/calendar_models.dart';
import '../../../core/astro/muhurta.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/astro/sri_lankan_calendar.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/info_notice.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/daily_providers.dart';
import '../domain/calendar_providers.dart';

/// The nekath calendar (KAN-30).
///
/// Two things in one screen: a month at a glance with poya days and festivals
/// marked, and the question people actually come with — "when this month
/// should I start X?".
///
/// Tapping a day selects it and returns home rather than opening a second day
/// view. The home screen already renders a full pañcāṅga with every window for
/// whatever date is selected; a parallel detail screen would duplicate it and
/// drift out of step.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backdrop),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => popOrHome(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.calendarTitle,
                      style: BrandFonts.displayStyle(
                        context,
                        size: 26,
                        color: palette.text,
                      ),
                    ),
                  ),
                  // Had no tooltip, so a screen reader announced it as an
                  // unlabelled button (KAN-85).
                  RoundIconButton(
                    icon: Icons.today_rounded,
                    tooltip: l.calendarThisMonth,
                    onPressed: () =>
                        ref.read(visibleMonthProvider.notifier).today(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const BrandCard(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  children: [
                    _MonthHeader(),
                    SizedBox(height: AppSpacing.md),
                    _WeekdayRow(),
                    SizedBox(height: AppSpacing.xs),
                    _MonthGrid(),
                    SizedBox(height: AppSpacing.md),
                    _Legend(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _MonthEvents(),
              const SizedBox(height: AppSpacing.xl),
              const _BestDays(),
              const SizedBox(height: AppSpacing.xl),
              // Was the one astrological screen without it, and the best-day
              // scores are astrological output (KAN-85).
              Text(
                l.entertainmentOnly,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: BrandFonts.displayStyle(
      context,
      size: 20,
      color: BrandPalette.of(context).text,
    ),
  );
}

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(visibleMonthProvider);
    final notifier = ref.read(visibleMonthProvider.notifier);
    final locale = Localizations.localeOf(context).languageCode;
    final material = MaterialLocalizations.of(context);

    return Row(
      children: [
        RoundIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: material.previousMonthTooltip,
          onPressed: () => notifier.shift(-1),
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM(locale).format(month),
            textAlign: TextAlign.center,
            style: BrandFonts.displayStyle(
              context,
              size: 20,
              color: BrandPalette.of(context).text,
            ),
          ),
        ),
        RoundIconButton(
          icon: Icons.chevron_right_rounded,
          tooltip: material.nextMonthTooltip,
          onPressed: () => notifier.shift(1),
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    // Built from a known Monday so the labels follow the locale rather than
    // being hardcoded English initials.
    final monday = DateTime(2024, 1, 1);

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat.E(locale).format(monday.add(Duration(days: i))),
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(visibleMonthProvider);
    final markers = ref.watch(monthMarkersProvider);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // DateTime.weekday is 1..7 from Monday, which is the order the header row
    // above uses too.
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    final today = DateTime.now();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: () {
                    final index = row * 7 + col;
                    final day = index - leading + 1;
                    if (day < 1 || day > daysInMonth) {
                      return const SizedBox(height: 52);
                    }
                    final date = DateTime(month.year, month.month, day);
                    return _DayCell(
                      date: date,
                      events: markers[day] ?? const [],
                      isToday:
                          date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day,
                    );
                  }(),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends ConsumerWidget {
  const _DayCell({
    required this.date,
    required this.events,
    required this.isToday,
  });

  final DateTime date;
  final List<Festival> events;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final isPoya = events.any((e) => e is PoyaDay);
    final hasFestival = events.any((e) => e is! PoyaDay);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isToday ? semantic.accentSurface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isToday ? BorderSide(color: semantic.accent) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Select the day and hand back to home, which is the day view.
            ref.read(selectedDateProvider.notifier).set(date);
            popOrHome(context);
          },
          child: SizedBox(
            height: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                    color: isToday ? semantic.accent : palette.text,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPoya) const _Marker(poya: true),
                      if (isPoya && hasFestival) const SizedBox(width: 3),
                      if (hasFestival) const _Marker(poya: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A poya is a circle and a festival a diamond (KAN-85).
///
/// They were a gold dot and a green dot, five pixels each, and only the legend
/// said which was which. Gold and green are the pair a colour-blind reader is
/// most likely to confuse, so the shape carries the meaning and the colour
/// only supports it.
class _Marker extends StatelessWidget {
  const _Marker({required this.poya});

  final bool poya;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return poya
        ? Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: semantic.accent,
              shape: BoxShape.circle,
            ),
          )
        : Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: semantic.auspicious,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);

    Widget item(bool poya, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Marker(poya: poya),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: palette.text)),
      ],
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 6,
      children: [item(true, l.calendarPoya), item(false, l.calendarFestival)],
    );
  }
}

/// What the markers on the grid actually are.
///
/// The grid marked days and never named them, so a month with no festival in
/// it — September, which is the one that got looked at — read as though the
/// app knew about poya days and nothing else (KAN-23).
///
/// The second half of this is the more useful half: the festivals the app
/// **cannot** compute are named here too. Four of Sri Lanka's public holidays
/// are set by moon sighting or local custom and are gazetted rather than
/// calculated, and a calendar that silently omits them is telling the reader
/// something false about the year.
class _MonthEvents extends ConsumerWidget {
  const _MonthEvents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final locale = AppLocale.of(context);
    final palette = BrandPalette.of(context);
    final markers = ref.watch(monthMarkersProvider);

    final days = markers.keys.toList()..sort();
    final month = ref.watch(visibleMonthProvider);
    final rows = [
      for (final day in days)
        for (final event in markers[day]!) (day: day, event: event),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l.calendarThisMonth),
        const SizedBox(height: AppSpacing.md),
        BrandCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    l.calendarNoEvents,
                    style: TextStyle(color: palette.muted),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: i == 0
                              ? null
                              : Border(top: BorderSide(color: palette.line)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '${rows[i].day}',
                                  style: BrandFonts.displayStyle(
                                    context,
                                    size: 18,
                                    color: palette.text,
                                  ),
                                ),
                              ),
                              _Marker(poya: rows[i].event is PoyaDay),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  rows[i].event.label(locale),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: palette.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        // The year is stated because the list above is this month's and this
        // one is not; without it the two read as the same list.
        InfoNotice(
          icon: Icons.info_outline,
          text:
              '${l.calendarAnnounced} (${month.year})\n'
              '${l.calendarAnnouncedHelp}\n'
              '${SriLankanCalendar.unsupportedFestivals.keys.join(' · ')}',
        ),
      ],
    );
  }
}

/// "When this month should I start X?" — the payoff of the KAN-22 engine.
class _BestDays extends ConsumerWidget {
  const _BestDays();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final month = ref.watch(visibleMonthProvider);
    final activity = ref.watch(chosenActivityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l.calendarBestDays),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l.calendarPickActivity,
          style: TextStyle(fontSize: 13, color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in Activity.values)
              _ActivityChip(
                label: activityLabel(l, a),
                selected: activity == a,
                // Tapping the selected chip clears it, so the scan can be
                // dismissed without leaving the screen.
                onTap: () => ref
                    .read(chosenActivityProvider.notifier)
                    .set(activity == a ? null : a),
                gold: semantic.accent,
                goldSurface: semantic.accentSurface,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (activity != null) _ScanResults(month: month, activity: activity),
      ],
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.gold,
    required this.goldSurface,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color gold, goldSurface;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? goldSurface : palette.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? gold : palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A tick on the chosen one: the gold alone would be colour
                // carrying the meaning.
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 16, color: gold),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? gold : palette.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanResults extends ConsumerWidget {
  const _ScanResults({required this.month, required this.activity});

  final DateTime month;
  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final scan = ref.watch(monthScanProvider(ScanRequest(month, activity)));

    return scan.when(
      loading: () => BrandCard(
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l.calendarScanning,
                style: TextStyle(color: palette.muted),
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => InfoNotice(text: '$e', tone: NoticeTone.caution),
      data: (days) {
        // Only days that actually score well are offered. Listing the least
        // bad day of a poor month as a recommendation would be misleading.
        final good = days.where((d) => d.best.isRecommended).take(8).toList();
        if (good.isEmpty) {
          return BrandCard(
            child: Text(
              l.calendarNoGoodDays,
              style: TextStyle(color: palette.text),
            ),
          );
        }

        return BrandCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < good.length; i++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(top: BorderSide(color: palette.line)),
                  ),
                  child: _DayRow(score: good[i]),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DayRow extends ConsumerWidget {
  const _DayRow({required this.score});

  final DayScore score;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final time = DateFormat.jm(locale);
    final strong = score.best.score >= 80;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ref.read(selectedDateProvider.notifier).set(score.date);
        popOrHome(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.MMMEd(locale).format(score.date),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${time.format(score.best.start)} — ${time.format(score.best.end)}'
                    ' · ${score.best.reasons.map((r) => reasonLabel(l, r)).join(' · ')}',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // The number is the signal; the colour only says whether it
            // cleared 80.
            Text(
              '${score.best.score}',
              style: BrandFonts.displayStyle(
                context,
                size: 22,
                color: strong
                    ? context.semantic.auspicious
                    : context.semantic.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String activityLabel(L10n l, Activity a) => switch (a) {
  Activity.travel => l.activityTravel,
  Activity.workOrStudy => l.activityWorkOrStudy,
  Activity.business => l.activityBusiness,
  Activity.marriage => l.activityMarriage,
  Activity.houseEntry => l.activityHouseEntry,
  Activity.vehicle => l.activityVehicle,
};

String reasonLabel(L10n l, MuhurtaReason r) => switch (r) {
  MuhurtaReason.nakshatraFavours => l.reasonNakshatraFavours,
  MuhurtaReason.nakshatraNeutral => l.reasonNakshatraNeutral,
  MuhurtaReason.nakshatraWarnsAgainst => l.reasonNakshatraWarnsAgainst,
  MuhurtaReason.tithiRikta => l.reasonTithiRikta,
  MuhurtaReason.tithiFavourable => l.reasonTithiFavourable,
  MuhurtaReason.yogaInauspicious => l.reasonYogaInauspicious,
  MuhurtaReason.karanaVishti => l.reasonKaranaVishti,
  MuhurtaReason.varaUnfavourable => l.reasonVaraUnfavourable,
  MuhurtaReason.varaFavourable => l.reasonVaraFavourable,
  MuhurtaReason.shortenedByChange => l.reasonShortenedByChange,
};
