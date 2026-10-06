import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/astro/compatibility/ashtakoota.dart';
import '../../../core/astro/compatibility/porondam.dart';
import '../../../core/ads/banner_ad_slot.dart';
import '../../../core/ads/rewarded_unlock.dart';
import '../../../core/ads/rewarded_unlock_card.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_button.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/nakshatra_star.dart';
import '../../../core/ui/pill_segments.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/info_notice.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../onboarding/domain/birth_profile.dart';
import '../domain/compatibility_providers.dart';
import 'partner_form.dart';
import '../../../core/purchases/nudges.dart';
import '../../purchases/presentation/pro_nudge.dart';
import '../../../core/ads/lock_preview.dart';

/// Marriage matching (KAN-29).
///
/// Both systems are offered rather than one converted into the other: they
/// weigh the same underlying factors differently, and a pairing can read well
/// on one and poorly on the other. Hiding that behind a single number would
/// be a claim neither tradition makes.
class CompatibilityScreen extends ConsumerWidget {
  const CompatibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final mine = ref.watch(profileProvider);
    final partner = ref.watch(partnerProvider);
    final match = ref.watch(matchProvider);

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
                  Expanded(
                    child: Text(
                      l.compatTitle,
                      style: BrandFonts.displayStyle(
                        context,
                        size: 26,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l.compatIntro,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _Pair(mine: mine, partner: partner),

              if (partner != null) ...[
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => showPartnerForm(context, ref),
                    child: Text(
                      l.compatChangePartner,
                      style: TextStyle(color: context.semantic.accent),
                    ),
                  ),
                ),
                const _RoleSelector(),
                const SizedBox(height: AppSpacing.lg),
                const _SystemToggle(),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (match == null) const _Empty() else _Results(match: match),

              const SizedBox(height: AppSpacing.xl),
              _Caveat(text: l.compatCaveat),
              const SizedBox(height: AppSpacing.md),
              Text(
                l.entertainmentOnly,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),

              // The screen's one ad, and the last thing on it (KAN-76).
              //
              // Below the result, below the caveat, below the disclaimer —
              // seen by someone who has read the whole match and scrolled
              // past the warning, never by someone still reading it. Every
              // control on this screen (the partner card, the bride selector,
              // the system toggle, the unlock buttons in the breakdown) sits
              // above that. AdMob enforces its accidental-click rule hardest
              // beside things a user taps, and the ban is account-wide.
              //
              // Only once there is a result. A screen still asking for the
              // partner's details is a form, and an ad at the foot of a form
              // sits one thumb-length from the button that fills it in.
              if (match != null) const BannerAdSlot(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The two people side by side, with a heart between them.
///
/// With no partner yet the second place is an empty, dashed "Add partner"
/// card: the screen shows the pair it needs before asking for it.
class _Pair extends ConsumerWidget {
  const _Pair({required this.mine, required this.partner});

  final BirthProfile? mine;
  final BirthProfile? partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: mine == null
                ? const SizedBox.shrink()
                : _Person(label: l.compatYourDetails, profile: mine!),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 20,
              color: context.semantic.accent,
            ),
          ),
          Expanded(
            child: partner == null
                ? _AddPartner(onTap: () => showPartnerForm(context, ref))
                : _Person(label: l.compatPartnerDetails, profile: partner!),
          ),
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.label, required this.profile});

  final String label;
  final BirthProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final name = profile.name.isEmpty ? '—' : profile.name;
    // Labelled as a whole for a screen reader, which otherwise hears two
    // names with nothing saying whose is whose; the card shows it by place.
    return Semantics(
      container: true,
      label: label,
      child: BrandCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: semantic.accentSurface,
              ),
              child: Text(
                String.fromCharCodes(name.runes.take(1)).toUpperCase(),
                style: BrandFonts.displayStyle(
                  context,
                  size: 22,
                  color: semantic.accent,
                ).copyWith(height: 1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${DateFormat.yMMMd().format(profile.birthDate)} · '
              '${profile.place.label(AppLocale.of(context))}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPartner extends StatelessWidget {
  const _AddPartner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final gold = context.semantic.accent;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BrandCard.radius),
        side: BorderSide(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gold),
                ),
                child: Icon(Icons.add_rounded, color: gold),
              ),
              const SizedBox(height: 8),
              Text(
                L10n.of(context).compatAddPartner,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Before there is a partner: what a match will show, then the way in.
class _Empty extends ConsumerWidget {
  const _Empty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;

    Widget row(String badge, String title, String body, bool first) =>
        DecoratedBox(
          decoration: BoxDecoration(
            border: first ? null : Border(top: BorderSide(color: palette.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: semantic.accentSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: semantic.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                      Text(
                        body,
                        style: TextStyle(fontSize: 13, color: palette.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: SizedBox.square(
            dimension: 88,
            child: CustomPaint(
              painter: NakshatraStarPainter(
                progress: 1,
                color: semantic.accent.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l.compatNeedPartner,
          textAlign: TextAlign.center,
          style: BrandFonts.displayStyle(
            context,
            size: 20,
            color: palette.text,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l.compatWillShow,
          style: TextStyle(fontSize: 13, color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        BrandCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              row(
                '36',
                l.compatSystemAshtakoota,
                l.compatShowsAshtakoota,
                true,
              ),
              row('12', l.compatSystemPorondam, l.compatShowsPorondam, false),
              row('!', l.compatShowsDoshasTitle, l.compatShowsDoshas, false),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BrandButton(
          expand: true,
          label: l.compatAddPartner,
          leading: const Icon(Icons.person_add_alt_1_rounded),
          onPressed: () => showPartnerForm(context, ref),
        ),
      ],
    );
  }
}

/// Which person is the bride.
///
/// Asked outright rather than inferred, because several factors are
/// direction-dependent and a wrong guess quietly changes the result.
class _RoleSelector extends ConsumerWidget {
  const _RoleSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final role = ref.watch(brideRoleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.compatRoleQuestion,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PillSegments<BrideRole>(
          segments: [
            (value: BrideRole.me, label: l.compatRoleYou),
            (value: BrideRole.partner, label: l.compatRolePartner),
          ],
          selected: role,
          onChanged: (r) => ref.read(brideRoleProvider.notifier).set(r),
        ),
        const SizedBox(height: 6),
        Text(
          l.compatRoleHelp,
          style: TextStyle(fontSize: 12, height: 1.5, color: palette.muted),
        ),
      ],
    );
  }
}

class _SystemToggle extends ConsumerWidget {
  const _SystemToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final system = ref.watch(matchSystemProvider);

    return PillSegments<MatchSystem>(
      segments: [
        (value: MatchSystem.porondam, label: l.compatSystemPorondam),
        (value: MatchSystem.ashtakoota, label: l.compatSystemAshtakoota),
      ],
      selected: system,
      onChanged: (m) => ref.read(matchSystemProvider.notifier).set(m),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final system = ref.watch(matchSystemProvider);
    // The score and the doshas stay free. Locking the number would leave a
    // screen with nothing on it, and a warning nobody can read is worse than
    // no warning at all — only the per-factor working is the reward.
    final detail = ref
        .watch(unlockStoreProvider)
        .isOpen(RewardedUnlock.compatibilityDetail);

    Widget factors(List<Widget> rows) => BrandCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: palette.line)),
              ),
              child: rows[i],
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // First in the result and keyed, so flipping between porondam and
        // koota — which swaps the locks below — cannot remount it and ask
        // twice (KAN-75).
        const ProNudge(
          key: ValueKey('compat-nudge'),
          triggers: [NudgeTrigger.compatDetail, NudgeTrigger.adWatches],
        ),
        if (match.anyTimeUnknown) ...[
          InfoNotice(text: l.compatTimeUnknown, tone: NoticeTone.caution),
          const SizedBox(height: AppSpacing.md),
        ],

        if (system == MatchSystem.ashtakoota) ...[
          _ScoreHeadline(
            label: l.compatSystemAshtakoota,
            value: l.compatScoreOutOf(
              match.ashtakoota.total.toStringAsFixed(1),
              AshtakootaResult.maximum,
            ),
            fraction: match.ashtakoota.total / AshtakootaResult.maximum,
          ),
          // Each dosha brings its own gap. Two of them stacked used to be
          // separated by the warning's own top margin; with that gone they
          // would have touched.
          if (match.ashtakoota.hasNadiDosha) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoNotice(text: l.compatNadiDosha, tone: NoticeTone.caution),
          ],
          if (match.ashtakoota.hasBhakootDosha) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoNotice(text: l.compatBhakootDosha, tone: NoticeTone.caution),
          ],
          const SizedBox(height: AppSpacing.md),
          if (detail)
            factors([
              for (final s in match.ashtakoota.scores) _KootaRow(score: s),
            ])
          else ...[
            // The first factors in the clear, so the breakdown being offered
            // is one the reader has already seen the shape of (KAN-70).
            factors([
              for (final s in match.ashtakoota.scores.take(
                previewCount(match.ashtakoota.scores.length),
              ))
                _KootaRow(score: s),
            ]),
            const SizedBox(height: AppSpacing.md),
            RewardedUnlockCard(
              unlock: RewardedUnlock.compatibilityDetail,
              title: l.unlockCompatTitle,
              body: l.unlockCompatBody,
            ),
          ],
        ] else ...[
          _ScoreHeadline(
            label: l.compatSystemPorondam,
            value: l.compatMatchedOutOf(
              match.porondam.matched,
              match.porondam.judged,
            ),
            fraction: match.porondam.matched / match.porondam.judged,
          ),
          if (match.porondam.hasRajjuDosha) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoNotice(text: l.factorRajjuAbout, tone: NoticeTone.caution),
          ],
          const SizedBox(height: AppSpacing.md),
          if (detail)
            factors([
              for (final s in match.porondam.scores) _PorondamRow(score: s),
            ])
          else ...[
            // The first factors in the clear, so the breakdown being offered
            // is one the reader has already seen the shape of (KAN-70).
            factors([
              for (final s in match.porondam.scores.take(
                previewCount(match.porondam.scores.length),
              ))
                _PorondamRow(score: s),
            ]),
            const SizedBox(height: AppSpacing.md),
            RewardedUnlockCard(
              unlock: RewardedUnlock.compatibilityDetail,
              title: l.unlockCompatTitle,
              body: l.unlockCompatBody,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // The gap to twenty is stated on screen, not only in the code.
          Text(
            l.compatPorondamIncomplete,
            style: TextStyle(fontSize: 12, height: 1.5, color: palette.muted),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        _KujaSection(match: match),
      ],
    );
  }
}

class _ScoreHeadline extends StatelessWidget {
  const _ScoreHeadline({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    // Colour by band rather than a single accent: a score is the one thing on
    // this screen a reader takes at a glance. The number itself carries the
    // meaning; the colour only groups it.
    final colour = fraction >= 0.7
        ? context.semantic.auspicious
        : fraction >= 0.5
        ? context.semantic.accent
        : context.semantic.inauspicious;

    return BrandCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: palette.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            // The body face, bold: Fraunces' open 4 reads as a 1 and its 3 as
            // a 5, and a score must not be misread (KAN-91).
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: colour,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              color: colour,
              backgroundColor: palette.line,
            ),
          ),
        ],
      ),
    );
  }
}

class _KootaRow extends StatelessWidget {
  const _KootaRow({required this.score});

  final KootaScore score;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final (name, about) = kootaLabels(l, score.koota);

    return _FactorRow(
      name: name,
      about: about,
      trailing: '${_trim(score.points)} / ${score.maximum}',
      colour: score.isZero
          ? context.semantic.inauspicious
          : score.isFull
          ? context.semantic.auspicious
          : null,
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _PorondamRow extends StatelessWidget {
  const _PorondamRow({required this.score});

  final PorondamScore score;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final (name, about) = porondamLabels(l, score.porondam);

    // A symbol before the word as well as the colour: met, partly, not met
    // must read in grey print and to a reader who cannot tell red from green.
    return _FactorRow(
      name: name,
      about: about,
      trailing: switch (score.verdict) {
        PorondamVerdict.good => '✓ ${l.verdictGood}',
        PorondamVerdict.partial => '◐ ${l.verdictPartial}',
        PorondamVerdict.poor => '✕ ${l.verdictPoor}',
      },
      colour: switch (score.verdict) {
        PorondamVerdict.good => context.semantic.auspicious,
        PorondamVerdict.partial => context.semantic.accent,
        PorondamVerdict.poor => context.semantic.inauspicious,
      },
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.name,
    required this.about,
    required this.trailing,
    this.colour,
  });

  final String name;
  final String about;
  final String trailing;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  about,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            trailing,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colour ?? palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _KujaSection extends StatelessWidget {
  const _KujaSection({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final kuja = match.kuja;

    final text = kuja.cancelsOut
        ? l.compatKujaBoth
        : kuja.isUnmatched
        ? l.compatKujaUnmatched
        : l.compatKujaNeither;

    final severe = kuja.bride.isSevere || kuja.groom.isSevere;

    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.compatKujaTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(fontSize: 14, height: 1.5, color: palette.muted),
          ),
          if (severe && kuja.isUnmatched) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoNotice(text: l.compatKujaSevere, tone: NoticeTone.caution),
          ],
        ],
      ),
    );
  }
}

/// The line that matters most on this screen.
class _Caveat extends StatelessWidget {
  const _Caveat({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, height: 1.55, color: palette.muted),
      ),
    );
  }
}

/// Factor names and one-line descriptions, kept out of the widgets so the two
/// systems can share the ones they have in common.
(String, String) kootaLabels(L10n l, Koota k) => switch (k) {
  Koota.varna => (l.factorVarna, l.factorVarnaAbout),
  Koota.vashya => (l.factorVashya, l.factorVashyaAbout),
  Koota.tara => (l.factorTara, l.factorTaraAbout),
  Koota.yoni => (l.factorYoni, l.factorYoniAbout),
  Koota.grahaMaitri => (l.factorGrahaMaitri, l.factorGrahaMaitriAbout),
  Koota.gana => (l.factorGana, l.factorGanaAbout),
  Koota.bhakoot => (l.factorBhakoot, l.factorBhakootAbout),
  Koota.nadi => (l.factorNadi, l.factorNadiAbout),
};

(String, String) porondamLabels(L10n l, Porondam p) => switch (p) {
  Porondam.dina => (l.factorDina, l.factorDinaAbout),
  Porondam.gana => (l.factorGana, l.factorGanaAbout),
  Porondam.mahendra => (l.factorMahendra, l.factorMahendraAbout),
  Porondam.streeDeergha => (l.factorStreeDeergha, l.factorStreeDeerghaAbout),
  Porondam.yoni => (l.factorYoni, l.factorYoniAbout),
  Porondam.rasi => (l.factorRasi, l.factorRasiAbout),
  Porondam.rasiadhipathi => (l.factorRasiadhipathi, l.factorRasiadhipathiAbout),
  Porondam.vashya => (l.factorVashya, l.factorVashyaAbout),
  Porondam.rajju => (l.factorRajju, l.factorRajjuAbout),
  Porondam.vedha => (l.factorVedha, l.factorVedhaAbout),
  Porondam.varna => (l.factorVarna, l.factorVarnaAbout),
  Porondam.nadi => (l.factorNadi, l.factorNadiAbout),
};
