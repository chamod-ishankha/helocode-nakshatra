import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/astro/compatibility/ashtakoota.dart';
import '../../../core/astro/compatibility/porondam.dart';
import '../../../core/ads/rewarded_unlock.dart';
import '../../../core/ads/rewarded_unlock_card.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../onboarding/domain/birth_profile.dart';
import '../domain/compatibility_providers.dart';
import 'partner_form.dart';

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
    final theme = Theme.of(context);
    final mine = ref.watch(profileProvider);
    final partner = ref.watch(partnerProvider);
    final match = ref.watch(matchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.compatTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrHome(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            l.compatIntro,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          if (mine != null)
            _PersonCard(label: l.compatYourDetails, profile: mine),
          const SizedBox(height: 8),
          _PartnerCard(partner: partner),

          if (partner != null) ...[
            const SizedBox(height: 20),
            const _RoleSelector(),
            const SizedBox(height: 20),
            const _SystemToggle(),
            const SizedBox(height: 16),
          ],

          if (match == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l.compatNeedPartner,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            _Results(match: match),

          const SizedBox(height: 24),
          _Caveat(text: l.compatCaveat),
          const SizedBox(height: 12),
          Text(
            l.entertainmentOnly,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.label, required this.profile});

  final String label;
  final BirthProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.name.isEmpty ? '—' : profile.name,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${DateFormat.yMMMd().format(profile.birthDate)} · '
                  '${profile.place.en}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _PartnerCard extends ConsumerWidget {
  const _PartnerCard({required this.partner});

  final BirthProfile? partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);

    if (partner == null) {
      return FilledButton.icon(
        onPressed: () => showPartnerForm(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l.compatPartnerDetails),
      );
    }

    return Column(
      children: [
        _PersonCard(label: l.compatPartnerDetails, profile: partner!),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => showPartnerForm(context, ref),
            child: Text(l.compatChangePartner),
          ),
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
    final theme = Theme.of(context);
    final role = ref.watch(brideRoleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.compatRoleQuestion, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<BrideRole>(
          segments: [
            ButtonSegment(value: BrideRole.me, label: Text(l.compatRoleYou)),
            ButtonSegment(
              value: BrideRole.partner,
              label: Text(l.compatRolePartner),
            ),
          ],
          selected: {role},
          onSelectionChanged: (s) =>
              ref.read(brideRoleProvider.notifier).set(s.first),
        ),
        const SizedBox(height: 6),
        Text(
          l.compatRoleHelp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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

    return SegmentedButton<MatchSystem>(
      segments: [
        ButtonSegment(
          value: MatchSystem.porondam,
          label: Text(l.compatSystemPorondam),
        ),
        ButtonSegment(
          value: MatchSystem.ashtakoota,
          label: Text(l.compatSystemAshtakoota),
        ),
      ],
      selected: {system},
      onSelectionChanged: (s) =>
          ref.read(matchSystemProvider.notifier).set(s.first),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final system = ref.watch(matchSystemProvider);
    // The score and the doshas stay free. Locking the number would leave a
    // screen with nothing on it, and a warning nobody can read is worse than
    // no warning at all — only the per-factor working is the reward.
    final detail = ref
        .watch(unlockStoreProvider)
        .isOpen(RewardedUnlock.compatibilityDetail);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (match.anyTimeUnknown) ...[
          _Warning(text: l.compatTimeUnknown),
          const SizedBox(height: 12),
        ],

        if (system == MatchSystem.ashtakoota) ...[
          _ScoreHeadline(
            value: l.compatScoreOutOf(
              match.ashtakoota.total.toStringAsFixed(1),
              AshtakootaResult.maximum,
            ),
            fraction: match.ashtakoota.total / AshtakootaResult.maximum,
          ),
          if (match.ashtakoota.hasNadiDosha) _Warning(text: l.compatNadiDosha),
          if (match.ashtakoota.hasBhakootDosha)
            _Warning(text: l.compatBhakootDosha),
          const SizedBox(height: 12),
          if (detail)
            for (final s in match.ashtakoota.scores) _KootaRow(score: s)
          else
            RewardedUnlockCard(
              unlock: RewardedUnlock.compatibilityDetail,
              title: l.unlockCompatTitle,
              body: l.unlockCompatBody,
            ),
        ] else ...[
          _ScoreHeadline(
            value: l.compatMatchedOutOf(
              match.porondam.matched,
              match.porondam.judged,
            ),
            fraction: match.porondam.matched / match.porondam.judged,
          ),
          if (match.porondam.hasRajjuDosha) _Warning(text: l.factorRajjuAbout),
          const SizedBox(height: 12),
          if (detail)
            for (final s in match.porondam.scores) _PorondamRow(score: s)
          else
            RewardedUnlockCard(
              unlock: RewardedUnlock.compatibilityDetail,
              title: l.unlockCompatTitle,
              body: l.unlockCompatBody,
            ),
          const SizedBox(height: 12),
          // The gap to twenty is stated on screen, not only in the code.
          Text(
            l.compatPorondamIncomplete,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        const SizedBox(height: 20),
        _KujaSection(match: match),
      ],
    );
  }
}

class _ScoreHeadline extends StatelessWidget {
  const _ScoreHeadline({required this.value, required this.fraction});

  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Colour by band rather than a single accent: a score is the one thing on
    // this screen a reader takes at a glance.
    final colour = fraction >= 0.7
        ? AppColors.auspicious
        : fraction >= 0.5
        ? AppColors.accent
        : AppColors.inauspicious;

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(color: colour),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            color: colour,
          ),
        ),
      ],
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
          ? AppColors.inauspicious
          : score.isFull
          ? AppColors.auspicious
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

    return _FactorRow(
      name: name,
      about: about,
      trailing: switch (score.verdict) {
        PorondamVerdict.good => l.verdictGood,
        PorondamVerdict.partial => l.verdictPartial,
        PorondamVerdict.poor => l.verdictPoor,
      },
      colour: switch (score.verdict) {
        PorondamVerdict.good => AppColors.auspicious,
        PorondamVerdict.partial => null,
        PorondamVerdict.poor => AppColors.inauspicious,
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium),
                Text(
                  about,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colour ?? theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final kuja = match.kuja;

    final text = kuja.cancelsOut
        ? l.compatKujaBoth
        : kuja.isUnmatched
        ? l.compatKujaUnmatched
        : l.compatKujaNeither;

    final severe = kuja.bride.isSevere || kuja.groom.isSevere;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.compatKujaTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(text, style: theme.textTheme.bodyMedium),
        if (severe && kuja.isUnmatched)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l.compatKujaSevere,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inauspicious,
              ),
            ),
          ),
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.inauspicious.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.inauspicious,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Text(text, style: theme.textTheme.bodySmall),
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
