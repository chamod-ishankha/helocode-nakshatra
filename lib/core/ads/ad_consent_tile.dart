import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import 'ads_service.dart';

/// Whether this user must be offered a way to change their ad consent.
///
/// A [FutureProvider] because UMP answers over a method channel, and the
/// answer depends on the region it decided the user is in — there is nothing
/// synchronous to read.
final privacyOptionsRequiredProvider = FutureProvider<bool>(
  (ref) => AdsService.privacyOptionsRequired(),
);

/// The Settings row that reopens the ad consent form (KAN-40).
///
/// ## Why it is conditional
///
/// UMP requires a persistent entry point wherever consent was collected — the
/// EEA and the UK — and consent that cannot be withdrawn is not consent. It
/// requires it *nowhere else*, and showing it anyway would be worse than
/// useless: a row about changing an advertising choice, offered to somebody
/// who was never asked to make one, reads as an admission that the app
/// collected something it did not.
///
/// So the row is absent unless UMP says otherwise, and absent while it is
/// still deciding. It is also absent for anyone who bought Remove Ads, since
/// there is no advertising left to have a choice about.
///
/// ## It was already promised
///
/// The published privacy policy says the choice can be changed "later in the
/// app's settings". That was not true of any build before this one, which
/// makes this a correctness fix rather than a feature.
class AdConsentTile extends ConsumerWidget {
  const AdConsentTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final required = ref.watch(privacyOptionsRequiredProvider);

    // Loading and error both collapse to nothing. A row that appears a moment
    // after the screen settles is worse than one that never appears, and an
    // error here means UMP could not tell us — which is not a reason to offer
    // a form that will not open.
    if (required.value != true) return const SizedBox.shrink();

    final l = L10n.of(context);

    return ListTile(
      leading: const Icon(Icons.ads_click_outlined),
      title: Text(l.settingsAdConsent),
      subtitle: Text(l.settingsAdConsentHint),
      onTap: () async {
        await AdsService.showPrivacyOptions();
        // The form can change the answer — a user who withdraws consent in a
        // region that then no longer requires the entry point should not be
        // left looking at it.
        ref.invalidate(privacyOptionsRequiredProvider);
      },
    );
  }
}
