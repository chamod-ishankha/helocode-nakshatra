import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/purchases/entitlements.dart';
import '../../../core/purchases/nudges.dart';
import '../../../core/purchases/purchase_controller.dart';
import '../../../core/router/app_router.dart';
import '../../purchases/presentation/paywall.dart';

/// Adding a second (or later) person's chart, from wherever the door is
/// (KAN-74).
///
/// One function so Home and the Profiles screen cannot drift apart on the
/// gate. Somebody with Pro goes straight to the birth-details wizard; anybody
/// else meets the paywall, opened for this reason so family charts lead its
/// list of benefits.
///
/// Only ever reached with at least one chart saved, so this never gates the
/// first chart. That one is free, always — see the Profiles screen.
Future<void> addFamilyMember(BuildContext context, WidgetRef ref) async {
  if (!ref.read(featureProvider(PaidFeature.multipleProfiles))) {
    // The attempt is what a later family nudge answers (KAN-75).
    await ref.read(nudgeRevisionProvider.notifier).familyAttempt();
    if (!context.mounted) return;
    await showPaywall(context, ref, reason: PaywallReason.multipleProfiles);
    return;
  }
  if (!context.mounted) return;

  // Straight into onboarding, which is already the only birth-details editor
  // there is. It writes through ProfileNotifier.add rather than save when it
  // was opened this way.
  context.push(Routes.addProfile);
}

/// Whether Home should show the "Add a family member" card (KAN-74).
///
/// Exactly one saved chart. With none the database is unavailable — a build
/// with no store falls back to a single profile in preferences and cannot hold
/// a second, so the card would lead nowhere. With two or more the user has
/// already found the feature, and Home is the habit screen: it should not
/// keep advertising something they use.
///
/// And only if tapping it can go somewhere: they own the feature, or this
/// build can sell it. A card that opens a paywall with nothing to buy is a
/// door painted on a wall.
bool showFamilyCard({
  required int savedCharts,
  required bool ownsFeature,
  required bool canBuy,
}) => savedCharts == 1 && (ownsFeature || canBuy);
