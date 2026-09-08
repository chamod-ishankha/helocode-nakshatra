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
import '../../../core/router/app_router.dart';
import '../../../core/sync/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';
import '../domain/daily_providers.dart';

/// The screen users open every morning.
///
/// Retention and ad revenue both rest on this, so the thing people actually
/// came for — rāhu kālaya — is above the fold and never more than a glance
/// away.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final panchanga = ref.watch(panchangaProvider);

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nakshatra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: L10n.of(context).homeBirthChart,
            onPressed: () => context.push(Routes.chart),
          ),
          const _AccountAction(),
          // The language switcher stays in the bar even though settings now
          // carries one too. Someone stuck in a language they cannot read
          // would have to find a settings screen labelled in that same
          // language — the header button is the escape hatch, and burying it
          // would defeat the point of having it.
          const LanguageButton(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: L10n.of(context).settingsTitle,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        // Recomputing is cheap, but a pull-to-refresh is what users reach for
        // when a day rolls over while the app is open.
        onRefresh: () async {
          ref.invalidate(panchangaProvider);
          await Future<void>.delayed(const Duration(milliseconds: 250));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _DateSwitcher(),
            const SizedBox(height: 16),
            if (dayLocked)
              RewardedUnlockCard(
                unlock: RewardedUnlock.futureDay,
                title: L10n.of(context).unlockFutureTitle,
                body: L10n.of(context).unlockFutureBody,
              )
            else ...[
              const _PoyaTodayBanner(),
              const _NowBanner(),
              _RahuKalayaCard(panchanga: panchanga),
              const SizedBox(height: 16),
              _PanchangaStrip(panchanga: panchanga),
              const SizedBox(height: 16),
              _SunMoonCard(panchanga: panchanga),
              const SizedBox(height: 16),
              const _OtherPeriods(),
              const SizedBox(height: 16),
              const _AuspiciousCard(),
            ],
            const SizedBox(height: 16),
            const _NextPoyaCard(),
            const SizedBox(height: 16),
            const _CalendarCard(),
            const SizedBox(height: 8),
            const _CompatibilityCard(),
            const SizedBox(height: 8),
            const _HoroscopeCard(),
            const SizedBox(height: 24),
            const _ComingSoon(),
            const SizedBox(height: 24),
            Text(
              L10n.of(context).entertainmentOnly,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            // Last thing on the page, well below the rāhu kālaya card and
            // every other control. Nothing here reveals a reading, so there
            // is no button an accidental tap could be mistaken for.
            const BannerAdSlot(),
          ],
        ),
      ),
    );
  }
}

/// The month view, and the activity lookup that sits under it.
class _CalendarCard extends ConsumerWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        leading: Icon(Icons.calendar_month, color: AppColors.accent),
        title: Text(L10n.of(context).calendarTitle),
        subtitle: Text(
          L10n.of(context).calendarPickActivity,
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.calendar),
      ),
    );
  }
}

/// Marriage matching, reached from the daily screen.
///
/// A card rather than a fourth app-bar icon: three actions is already the
/// most a 360 dp bar carries comfortably, and this is a thing people come to
/// the app for deliberately rather than glance at each morning.
class _CompatibilityCard extends ConsumerWidget {
  const _CompatibilityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        leading: Icon(Icons.favorite_outline, color: AppColors.accent),
        title: Text(L10n.of(context).compatTitle),
        subtitle: Text(
          L10n.of(context).compatIntro,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.compatibility),
      ),
    );
  }
}

/// Entry point to the account screen.
///
/// An anonymous account gets a dot on the icon. It is the only hint that the
/// backup dies with the phone, and a quiet marker is the right weight for it —
/// the app works perfectly without an account, so nagging would be dishonest,
/// but saying nothing until the phone is lost would be worse.
/// The daily reading (KAN-31).
class _HoroscopeCard extends ConsumerWidget {
  const _HoroscopeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        leading: Icon(Icons.auto_awesome_outlined, color: AppColors.accent),
        title: Text(L10n.of(context).horoscopeTitle),
        subtitle: Text(
          L10n.of(context).homeHoroscopeSubtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.horoscope),
      ),
    );
  }
}

class _AccountAction extends ConsumerWidget {
  const _AccountAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind =
        ref.watch(accountStatusProvider).value?.kind ?? AccountKind.none;

    return IconButton(
      tooltip: L10n.of(context).homeAccount,
      onPressed: () => context.push(Routes.account),
      icon: Badge(
        isLabelVisible: kind == AccountKind.anonymous,
        backgroundColor: Theme.of(context).colorScheme.error,
        smallSize: 8,
        child: Icon(
          kind == AccountKind.permanent
              ? Icons.verified_user_outlined
              : Icons.account_circle_outlined,
        ),
      ),
    );
  }
}

class _DateSwitcher extends ConsumerWidget {
  const _DateSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final notifier = ref.read(selectedDateProvider.notifier);
    final isToday = ref.watch(selectedDateProvider.notifier).isToday;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => notifier.shift(-1),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                DateFormat('EEEE').format(date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                DateFormat('d MMMM yyyy').format(date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => notifier.shift(1),
        ),
        if (!isToday)
          TextButton(
            onPressed: notifier.today,
            child: Text(L10n.of(context).today),
          ),
      ],
    );
  }
}

/// Shown only when an inauspicious period is running right now.
class _NowBanner extends ConsumerWidget {
  const _NowBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentlyInauspiciousProvider);
    if (current == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inauspicious.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.inauspicious.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.inauspicious),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              // Was an English sentence built inline, so the one banner that
              // interrupts a reader mid-day spoke English at them whatever
              // language the app was in (KAN-59).
              L10n.of(context).homeWindowRunningNow(
                current.kind.label(AppLocale.of(context)),
                DateFormat('h:mm a').format(current.end),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// The headline. This is what the app is opened for.
class _RahuKalayaCard extends ConsumerWidget {
  const _RahuKalayaCard({required this.panchanga});
  final Panchanga panchanga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(inauspiciousProvider);
    final rahu = windows.firstWhere((w) => w.kind == WindowKind.rahu);
    final fmt = DateFormat('h:mm a');
    final theme = Theme.of(context);

    // A flat red tint over the light surface reads as muddy brown. A plain
    // surface with a red rule and red type keeps the warning legible without
    // discolouring the whole card.
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.inauspicious.withValues(alpha: 0.45)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: AppColors.inauspicious, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            // The Sinhala spelling is the form people recognise on a
            // This used to lead with the Sinhala රාහු කාලය in every language,
            // on the reasoning that it is the form printed on every litha and
            // is recognised on sight. That holds for a Sinhala reader. For a
            // Tamil one it put a script they do not read at the top of the
            // card the app is opened for, with ராகு காலம் — the form their
            // own almanacs use — demoted to small grey type underneath.
            Text(
              L10n.of(context).homeRahuKalaya,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.inauspicious,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${fmt.format(rahu.start)}  —  ${fmt.format(rahu.end)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.inauspicious,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              L10n.of(context).durationMinutes(rahu.duration.inMinutes),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              L10n.of(context).homeAvoidImportant,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanchangaStrip extends StatelessWidget {
  const _PanchangaStrip({required this.panchanga});

  final Panchanga panchanga;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('h:mm a');

    String until(DateTime? end) =>
        end == null ? '' : L10n.of(context).homeRunningUntil(fmt.format(end));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // AppLocale.of(context) rather than a locale handed down from
            // the parent. Both say the same thing in the app — MaterialApp's
            // locale is driven by the same provider — but two sources of
            // truth is how a screen ends up half-translated, and this one
            // was already the odd row out.
            _row(
              context,
              L10n.of(context).panchangaVara,
              panchanga.vara.label(AppLocale.of(context)),
              '',
            ),
            _row(
              context,
              L10n.of(context).panchangaTithi,
              '${panchanga.tithi.value.label(AppLocale.of(context))} '
              '(${panchanga.paksha.describe(AppLocale.of(context))})',
              until(panchanga.tithi.endsAt),
            ),
            _row(
              context,
              L10n.of(context).panchangaNakshatra,
              panchanga.nakshatra.value.label(AppLocale.of(context)),
              until(panchanga.nakshatra.endsAt),
            ),
            _row(
              context,
              L10n.of(context).panchangaYoga,
              panchanga.yoga.value.label(AppLocale.of(context)),
              until(panchanga.yoga.endsAt),
            ),
            _row(
              context,
              L10n.of(context).panchangaKarana,
              panchanga.karana.value.label(AppLocale.of(context)) +
                  (panchanga.karana.value.isInauspicious ? '  ⚠' : ''),
              until(panchanga.karana.endsAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, String sub) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub.isNotEmpty) Text(sub, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
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
    final fmt = DateFormat('h:mm a');
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        // IntrinsicHeight so the three columns share the tallest one's height
        // and the times can sit on a common bottom edge. Without it a label
        // that wraps to two lines — சூரிய அஸ்தமனம் does, its neighbours do
        // not — drops its time a line below the other two.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _item(
                context,
                Icons.wb_twilight,
                L10n.of(context).homeSunrise,
                fmt.format(panchanga.sunrise),
              ),
              _item(
                context,
                Icons.wb_sunny_outlined,
                L10n.of(context).homeSunset,
                fmt.format(panchanga.sunset),
              ),
              _item(
                context,
                Icons.nightlight_outlined,
                L10n.of(context).homeMoonrise,
                panchanga.moonrise == null
                    ? '—'
                    : fmt.format(panchanga.moonrise!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One of the three columns.
  ///
  /// [Expanded] rather than intrinsic width: three unconstrained columns fit
  /// "Sunrise / Sunset / Moonrise" and overflowed the row by 7px on
  /// சூரிய அஸ்தமனம், which is the same word in a longer script. Sharing
  /// the width in thirds and letting the label wrap costs nothing in English
  /// and cannot overflow in any language.
  Widget _item(BuildContext c, IconData icon, String label, String value) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(c).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(
                c,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

class _OtherPeriods extends ConsumerWidget {
  const _OtherPeriods();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref
        .watch(inauspiciousProvider)
        .where((w) => w.kind != WindowKind.rahu)
        .toList();
    final fmt = DateFormat('h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.of(context).homeOtherInauspicious,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final w in windows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                // A Wrap, not a Row: the name and the time sit on one line
                // when they fit and on two when they do not. Sharing one line
                // was fine while the names were English, overflowed the card
                // once the times were Tamil, and then — with the names
                // translated too — broke யமகண்டம் across a line in the middle
                // of the word. Neither half of this can be made short enough
                // for one line in every language, so it stops trying.
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 2,
                    children: [
                      Text(w.kind.label(AppLocale.of(context))),
                      Text(
                        '${fmt.format(w.start)} – ${fmt.format(w.end)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuspiciousCard extends ConsumerWidget {
  const _AuspiciousCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(auspiciousProvider);
    final fmt = DateFormat('h:mm a');

    return Card(
      color: AppColors.auspicious.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.of(context).homeClearTimes,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppColors.auspicious),
            ),
            const SizedBox(height: 4),
            Text(
              L10n.of(context).homeClearTimesHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            for (final w in windows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.auspicious,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${fmt.format(w.start)} – ${fmt.format(w.end)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            poya.label(AppLocale.of(context)),
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          // No English name underneath. The place list keeps one because a
          // reader may know the town by its English name and not by its
          // Sinhala one; a poya is the same word either way — பினர is Binara
          // — so the second line was only repeating itself in Latin letters.
          const SizedBox(height: 6),
          Text(
            poya.note ?? '',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            L10n.of(
              context,
            ).homeFullMoonAt(DateFormat('h:mm a').format(poya.fullMoon)),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Countdown to the next poya, and the next festival if that is sooner.
class _NextPoyaCard extends ConsumerWidget {
  const _NextPoyaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final poya = ref.watch(nextPoyaProvider);
    final festival = ref.watch(nextFestivalProvider);
    if (poya == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final entries = <Festival>[
      poya,
      if (festival != null && festival.date != poya.date) festival,
    ]..sort((a, b) => a.date.compareTo(b.date));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.of(context).homeComingUp,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final f in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      f.kind == FestivalKind.poya
                          ? Icons.brightness_1
                          : Icons.celebration_outlined,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.label(AppLocale.of(context)),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, d MMMM').format(f.date),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _countdown(L10n.of(context), f.daysFrom(date)),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _countdown(L10n l, int days) => switch (days) {
    0 => l.todayLower,
    1 => l.tomorrowLower,
    _ => l.inDays(days),
  };
}

/// Honest placeholder for the sections whose engines do not exist yet.
///
/// Deliberately not filled with invented readings: showing made-up astrology
/// would undermine the accuracy the rest of the app is built on.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.of(context).homeStillToCome,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            L10n.of(context).homeFestivalsExcluded,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
