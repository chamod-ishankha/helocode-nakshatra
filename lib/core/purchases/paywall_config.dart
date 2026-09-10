import 'entitlements.dart';
import 'products.dart';

/// Which pre-translated headline the paywall uses (KAN-36).
///
/// A *variant key*, not the copy itself. Remote Config could deliver a string
/// straight to the screen, and it would arrive in one language — this app's
/// premise is that a Sri Lankan user reads it in their own, so an experiment
/// that ships English to a Sinhala reader is not a variant, it is a
/// regression. The copy stays in the ARB files where the translations are.
enum PaywallVariant {
  /// Leads on what is unlocked.
  value,

  /// Leads on keeping the app running. Worth testing here: buying to support
  /// a local app is a different motive from buying features, and nobody knows
  /// yet which one sells better in this market.
  support;

  static PaywallVariant parse(String? raw) {
    for (final v in PaywallVariant.values) {
      if (v.name == raw) return v;
    }
    return PaywallVariant.value;
  }
}

/// What Remote Config is allowed to change about the paywall (KAN-36).
///
/// ## Config can only ever be more generous
///
/// [freeFeatures] removes gates; nothing here adds one. A config value that is
/// wrong, stale, or fat-fingered can therefore only give something away — it
/// can never lock a user out of something the app promised, and it can never
/// take away something already paid for, because entitlements are checked
/// separately and a purchase always wins.
///
/// ## And not everything can be given away
///
/// Anything a one-time product exists to sell is off limits, so no config
/// value can switch off ads for everybody or hand out a report somebody else
/// paid LKR 1,500 for. That leaves exactly the soft Pro features, which are
/// the ones worth experimenting with anyway.
class PaywallConfig {
  const PaywallConfig({
    this.variant = PaywallVariant.value,
    this.freeFeatures = const {},
    this.highlight = PurchaseProduct.proYearly,
  });

  final PaywallVariant variant;

  /// Features currently open to everyone, whatever they have paid.
  final Set<PaidFeature> freeFeatures;

  /// The tier drawn as the recommended one.
  final PurchaseProduct highlight;

  /// What the app does with no Remote Config at all — a fetch that failed, a
  /// build with no Firebase, or the first launch before anything arrives.
  static const defaults = PaywallConfig();

  /// Features a config value may open.
  ///
  /// Derived rather than listed, so it stays right if the ladder changes: a
  /// feature that any one-time purchase can satisfy is something somebody
  /// pays for outright, and giving it away by config would be taking money
  /// for a thing that is free that week.
  static Set<PaidFeature> get freeable {
    final soldOutright = PurchaseProduct.values
        .where((p) => !p.isSubscription)
        .map((p) => p.grants)
        .toSet();

    return PaidFeature.values
        .where((f) => !f.satisfiedBy.any(soldOutright.contains))
        .toSet();
  }

  /// Reads a config, ignoring anything it does not understand.
  ///
  /// Every value is optional and every unreadable one falls back to the
  /// default. Remote Config is a dial, not a dependency: a paywall must draw
  /// correctly on a phone that has never reached Firebase.
  static PaywallConfig parse({
    String? variant,
    String? freeFeatures,
    String? highlight,
  }) => PaywallConfig(
    variant: PaywallVariant.parse(variant),
    freeFeatures: _features(freeFeatures),
    highlight: _highlight(highlight),
  );

  static Set<PaidFeature> _features(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const {};

    final allowed = freeable;
    final wanted = <PaidFeature>{};
    for (final name in raw.split(',')) {
      final trimmed = name.trim();
      for (final feature in PaidFeature.values) {
        if (feature.name == trimmed && allowed.contains(feature)) {
          wanted.add(feature);
        }
      }
    }
    return wanted;
  }

  static PurchaseProduct _highlight(String? raw) {
    for (final tier in PurchaseProduct.proTiers) {
      if (tier.id == raw || tier.name == raw) return tier;
    }
    return PurchaseProduct.proYearly;
  }

  /// Whether [feature] is open to everybody at the moment.
  bool isFree(PaidFeature feature) => freeFeatures.contains(feature);
}
