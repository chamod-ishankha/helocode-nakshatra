import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/astro/calendar_models.dart';
import '../../../core/astro/muhurta.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/astro/sri_lankan_calendar.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
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
    final month = ref.watch(visibleMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.calendarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrHome(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => ref.read(visibleMonthProvider.notifier).today(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          _MonthHeader(month: month),
          const SizedBox(height: AppSpacing.sm),
          const _WeekdayRow(),
          const _MonthGrid(),
          const SizedBox(height: AppSpacing.sm),
          const _Legend(),
          const SizedBox(height: AppSpacing.xl),
          const _MonthEvents(),
          const SizedBox(height: AppSpacing.xl),
          const _BestDays(),
        ],
      ),
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(visibleMonthProvider.notifier);
    final locale = Localizations.localeOf(context).languageCode;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => notifier.shift(-1),
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM(locale).format(month),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
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
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    // Built from a known Monday so the labels follow the locale rather than
    // being hardcoded English initials.
    final monday = DateTime(2024, 1, 1);

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Text(
                DateFormat.E(locale).format(monday.add(Duration(days: i))),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
                      return const SizedBox(height: AppSpacing.huge);
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
    final theme = Theme.of(context);
    final isPoya = events.any((e) => e is PoyaDay);
    final hasFestival = events.any((e) => e is! PoyaDay);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        // Select the day and hand back to home, which is the day view.
        ref.read(selectedDateProvider.notifier).set(date);
        popOrHome(context);
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isToday
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : null,
          border: isToday ? Border.all(color: theme.colorScheme.primary) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : null,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPoya) _Dot(colour: context.semantic.accent),
                if (hasFestival) _Dot(colour: context.semantic.auspicious),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);

    Widget item(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(colour: c),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item(context.semantic.accent, l.calendarPoya),
        const SizedBox(width: 20),
        item(context.semantic.auspicious, l.calendarFestival),
      ],
    );
  }
}

/// What the dots on the grid actually are.
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
    final theme = Theme.of(context);
    final locale = AppLocale.of(context);
    final markers = ref.watch(monthMarkersProvider);

    final days = markers.keys.toList()..sort();
    final month = ref.watch(visibleMonthProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.calendarThisMonth, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        if (days.isEmpty)
          Text(
            l.calendarNoEvents,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

        for (final day in days)
          for (final event in markers[day]!)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _Dot(
                      colour: event is PoyaDay
                          ? context.semantic.accent
                          : context.semantic.auspicious,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '$day',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Text(event.label(locale))),
                ],
              ),
            ),

        const SizedBox(height: 20),
        Text(l.calendarAnnounced, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l.calendarAnnouncedHelp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          SriLankanCalendar.unsupportedFestivals.keys.join(' \u00b7 '),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        // The year is stated because the list above is this month's and this
        // one is not; without it the two read as the same list.
        Text(
          '${month.year}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
    final theme = Theme.of(context);
    final month = ref.watch(visibleMonthProvider);
    final activity = ref.watch(chosenActivityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.calendarBestDays, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l.calendarPickActivity,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in Activity.values)
              ChoiceChip(
                label: Text(activityLabel(l, a)),
                selected: activity == a,
                // Tapping the selected chip clears it, so the scan can be
                // dismissed without leaving the screen.
                onSelected: (on) => ref
                    .read(chosenActivityProvider.notifier)
                    .set(on ? a : null),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (activity != null) _ScanResults(month: month, activity: activity),
      ],
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
    final theme = Theme.of(context);
    final scan = ref.watch(monthScanProvider(ScanRequest(month, activity)));

    return scan.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(l.calendarScanning, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      error: (e, _) => Text(
        '$e',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      data: (days) {
        // Only days that actually score well are offered. Listing the least
        // bad day of a poor month as a recommendation would be misleading.
        final good = days.where((d) => d.best.isRecommended).toList();
        if (good.isEmpty) {
          return Text(l.calendarNoGoodDays, style: theme.textTheme.bodyMedium);
        }

        return Column(
          children: [for (final d in good.take(8)) _DayRow(score: d)],
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
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final time = DateFormat.jm(locale);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () {
        ref.read(selectedDateProvider.notifier).set(score.date);
        popOrHome(context);
      },
      title: Text(DateFormat.MMMEd(locale).format(score.date)),
      subtitle: Text(
        '${time.format(score.best.start)} — ${time.format(score.best.end)}'
        '\n${score.best.reasons.map((r) => reasonLabel(l, r)).join(' · ')}',
        style: theme.textTheme.bodySmall,
      ),
      isThreeLine: true,
      trailing: Text(
        '${score.best.score}',
        style: theme.textTheme.titleMedium?.copyWith(
          color: score.best.score >= 80
              ? context.semantic.auspicious
              : context.semantic.accent,
          fontWeight: FontWeight.w700,
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
