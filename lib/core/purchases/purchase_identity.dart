import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../sync/auth_service.dart';
import 'purchase_controller.dart';

/// The account purchases are filed under, or null while nobody is signed in
/// to a real one.
///
/// [AccountStatus] carries only a kind and an email — no uid — so the value
/// still has to come from the service. What watching it buys is the
/// *recompute*: this re-reads on every sign-in, link, sign-out and account
/// deletion, because all four go through `userChanges()`.
///
/// Its own provider rather than a read inside the listener below, and it
/// carries a plain `String?` on purpose. Riverpod does not notify when a
/// provider rebuilds to an equal value, so deriving the bare id is what makes
/// `userChanges()` safe to listen to at all: that stream also fires on every
/// token refresh, and each one would otherwise be a redundant round trip to
/// the store. Return anything without a meaningful `==` here and that silently
/// stops being true.
final purchasesUserIdProvider = Provider<String?>((ref) {
  ref.watch(accountStatusProvider);
  return ref.watch(authServiceProvider).purchasesUserId;
});

/// Keeps RevenueCat's idea of who is signed in matching Firebase's (KAN-64).
///
/// ## The bug this exists to close
///
/// [EntitlementNotifier.identify] and [EntitlementNotifier.forget] were
/// written, documented and correct, and nothing called either. RevenueCat was
/// told who the user was exactly once, in `bootstrap`, at launch. Two things
/// followed, both about money:
///
/// Signing out did not release the purchase. The cache stayed, and the store
/// stayed configured with the previous account until the app was restarted —
/// so on a shared phone, which is normal in this market, the next person to
/// sign in saw somebody else's Pro.
///
/// Signing in did not claim one. Somebody who bought while anonymous and then
/// signed in kept it only on that install, and found out on their next phone
/// when Restore brought back nothing.
///
/// ## Why it watches the transition, not the value
///
/// [AuthService.purchasesUserId] is null for an *anonymous* user as well as a
/// signed-out one, so acting on the current value would call [forget] on every
/// launch for every anonymous user — throwing away a legitimate purchase made
/// through their Play account. Acting on the change instead gives the right
/// answer in all four cases, with the anonymous one falling out for free:
///
/// | was    | now    | what it means            | action       |
/// |--------|--------|--------------------------|--------------|
/// | `null` | `X`    | signed in, or linked     | `identify(X)`|
/// | `X`    | `null` | signed out, or deleted   | `forget()`   |
/// | `X`    | `Y`    | swapped accounts         | `identify(Y)`|
/// | `null` | `null` | anonymous throughout     | nothing      |
///
/// The first read seeds without firing — `ref.listen` does not fire
/// immediately unless asked, and it must not: at launch there is no
/// transition, only a starting position, and `bootstrap` has already
/// configured the store with it.
///
/// A single listener rather than a call at each of the six identity changes
/// (link email, sign in email, link Google, sign in Google, sign out, delete
/// account). Wiring those individually is how the seventh gets missed.
///
/// ## Why this is a function and not a provider
///
/// The obvious shape is a `Provider<void>` holding a `ref.listen`, read once
/// from `bootstrap` to bring it to life. Under Riverpod 3 that silently does
/// nothing: a provider is paused when all of its listeners are paused, and a
/// provider that has only ever been `read` has no listeners at all. The
/// listener is attached, the subscription is paused, and not one sign-in ever
/// reaches the store — which is the same bug this file exists to fix, wearing
/// a different hat.
///
/// Listening on the container instead has no such state. It also puts the
/// side effect at the composition root, where it is visible, rather than
/// inside a provider nothing appears to use.
ProviderSubscription<String?> linkPurchasesToAccount(
  ProviderContainer container,
) {
  return container.listen<String?>(purchasesUserIdProvider, (was, now) {
    unawaited(_follow(container.read(entitlementsProvider.notifier), now));
  });
}

/// Tells the store about the change, and never lets it break the app.
///
/// Not awaited by the listener: this is a network round trip, and the screen
/// that triggered it — the account screen, mid sign-in — must not wait on the
/// store to finish showing what it was doing.
Future<void> _follow(EntitlementNotifier purchases, String? now) async {
  try {
    if (now == null) {
      await purchases.forget();
    } else {
      await purchases.identify(now);
    }
  } on Object catch (e, s) {
    // Same rule as sync and crash reporting: an enhancement, never a
    // dependency. A user who cannot reach RevenueCat mid sign-in keeps the
    // app, and the next launch reconciles.
    AppLogger.warn('Could not follow the account change in purchases', e, s);
  }
}
