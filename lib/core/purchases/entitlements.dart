import 'dart:convert';

/// What the user has paid for (KAN-35).
///
/// These are *entitlements*, not products. Several products grant the same
/// one — monthly and yearly both grant [pro] — and no feature gate anywhere in
/// the app asks what was bought, only what is held. That indirection is most
/// of the reason for using RevenueCat at all: the price ladder can be
/// rearranged in a dashboard without touching a line of gating code.
///
/// [identifier] must match the entitlement identifier configured in the
/// RevenueCat dashboard exactly, character for character. A typo there is
/// invisible at compile time and shows up as a paying user who still sees ads.
enum Entitlement {
  adFree('ad_free'),
  pro('pro'),
  pdfReport('pdf_report'),
  compatibilityReport('compatibility_report');

  const Entitlement(this.identifier);

  final String identifier;

  /// The entitlement with this dashboard identifier, or null if we do not
  /// know it.
  ///
  /// Unknown identifiers are ignored rather than thrown on. The dashboard can
  /// gain an entitlement before the app that understands it has shipped, and
  /// an old build must keep working — silently, since there is nothing the
  /// user could do about it.
  static Entitlement? fromIdentifier(String identifier) {
    for (final e in Entitlement.values) {
      if (e.identifier == identifier) return e;
    }
    return null;
  }
}

/// Something a screen wants to know whether it may show.
///
/// The feature-gate helper KAN-36 asks for. A feature names the entitlements
/// that satisfy it, so a screen never has to reason about the ladder:
///
///     if (ref.watch(featureProvider(PaidFeature.fullDashaTimeline))) ...
///
/// ## Pro does not include the two report products
///
/// [birthChartPdf] and [compatibilityReport] are satisfied only by their own
/// one-time purchases, following the list of Pro unlocks on KAN-35 exactly.
/// That is a pricing decision rather than an engineering one — most ladders
/// would fold both into the yearly tier — and if it changes it is one entry in
/// this table.
enum PaidFeature {
  removeAds({Entitlement.adFree, Entitlement.pro}),
  unlimitedCompatibility({Entitlement.pro}),
  fullDashaTimeline({Entitlement.pro}),
  divisionalCharts({Entitlement.pro}),
  transitAlerts({Entitlement.pro}),
  multipleProfiles({Entitlement.pro}),
  birthChartPdf({Entitlement.pdfReport}),
  compatibilityReport({Entitlement.compatibilityReport});

  const PaidFeature(this.satisfiedBy);

  /// Holding any one of these opens the feature.
  final Set<Entitlement> satisfiedBy;
}

/// Everything the store last told us the user holds, and when it told us.
///
/// ## Why this is cached at all
///
/// The first frame decides whether to show a banner ad. Asking the network
/// first would mean either a blank hole in the layout for a second or, worse,
/// showing an ad to somebody who paid not to see one. So the last known answer
/// is written to preferences and read synchronously at startup, and the
/// network refresh corrects it a moment later.
///
/// ## Which way to be wrong
///
/// The two errors are not equal. Wrongly withholding Pro from a paying
/// customer on a bad connection produces a refund request and a one-star
/// review; wrongly extending it to somebody whose subscription lapsed costs
/// nothing and self-corrects the moment the device is online. Every rule below
/// is written to fail in the second direction.
class EntitlementSnapshot {
  const EntitlementSnapshot({required this.grants, required this.refreshedAt});

  /// Nothing held, as far as we know. [at] is when we last checked.
  EntitlementSnapshot.empty(DateTime at) : grants = const {}, refreshedAt = at;

  /// Nothing held, and the store has never been asked on this install.
  ///
  /// The epoch rather than "now" so that [_sane] has no opinion: a snapshot
  /// holding nothing cannot grant anything, and a floor set to today would
  /// make a device with a slow clock look like it had been tampered with.
  EntitlementSnapshot.unknown()
    : grants = const {},
      refreshedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Active entitlements, mapped to when they run out.
  ///
  /// A null value means it never does — that is a one-time purchase. A
  /// subscription always carries a date, and RevenueCat has already pushed it
  /// out to cover Play's billing-retry grace period, so this date is the point
  /// at which the store itself considers the user lapsed.
  final Map<Entitlement, DateTime?> grants;

  /// When the store last answered. Not when this object was built — a
  /// snapshot read back from the cache keeps the time of the answer it holds.
  final DateTime refreshedAt;

  /// How long a lapsed subscription keeps working when we cannot ask the store.
  ///
  /// Only ever applied to a cached answer we know predates the expiry. Three
  /// days is long enough to cover a phone that has been out of data since
  /// payday and short enough that a genuine cancellation does not linger.
  static const Duration offlineGrace = Duration(days: 3);

  bool get isEmpty => grants.isEmpty;

  /// Whether [entitlement] is live at [now].
  bool isActive(Entitlement entitlement, DateTime now) {
    if (!grants.containsKey(entitlement)) return false;

    final expires = grants[entitlement];
    if (expires == null) return true; // Bought outright; never lapses.

    final at = _sane(now);
    if (!at.isAfter(expires)) return true;

    // Past the expiry we were told about. If the store has answered since
    // then, this snapshot is that answer and the entitlement really is gone.
    // If it has not, we are guessing, and we guess in the user's favour.
    return refreshedAt.isBefore(expires) &&
        at.isBefore(expires.add(offlineGrace));
  }

  bool has(PaidFeature feature, DateTime now) =>
      feature.satisfiedBy.any((e) => isActive(e, now));

  Set<Entitlement> activeAt(DateTime now) =>
      grants.keys.where((e) => isActive(e, now)).toSet();

  /// [now], unless the device clock has moved back past the last thing the
  /// store told us.
  ///
  /// Winding the date back is the free-Pro trick that needs no tools. This
  /// blocks the obvious version of it — setting the clock to before the last
  /// refresh — and it costs nothing: no extra storage, and it cannot get stuck,
  /// because a clock that is wrong the other way is corrected by the next
  /// successful refresh, which rewrites [refreshedAt] too.
  ///
  /// It is a speed bump, not a lock. Someone offline who sets the date to a
  /// point after the last refresh but before the expiry still gets those days
  /// back. Closing that needs a trusted clock, which means asking the store —
  /// which is what a refresh does, and why one is attempted at every launch.
  /// Real receipt enforcement lives on RevenueCat's side; nothing on the
  /// device can be more than an inconvenience.
  DateTime _sane(DateTime now) => now.isBefore(refreshedAt) ? refreshedAt : now;

  Map<String, Object?> toJson() => {
    'refreshedAt': refreshedAt.toUtc().toIso8601String(),
    'grants': {
      for (final entry in grants.entries)
        entry.key.identifier: entry.value?.toUtc().toIso8601String(),
    },
  };

  String encode() => jsonEncode(toJson());

  /// Reads a snapshot back, returning null for anything unreadable.
  ///
  /// A cache that cannot be parsed must not throw: it is read before the first
  /// frame, and the only sane response to a corrupt one is to behave like a
  /// fresh install and re-ask the store.
  static EntitlementSnapshot? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;

      final refreshedAt = DateTime.tryParse('${json['refreshedAt']}');
      if (refreshedAt == null) return null;

      final rawGrants = json['grants'];
      if (rawGrants is! Map) return null;

      final grants = <Entitlement, DateTime?>{};
      for (final entry in rawGrants.entries) {
        final entitlement = Entitlement.fromIdentifier('${entry.key}');
        if (entitlement == null) continue;

        if (entry.value == null) {
          grants[entitlement] = null; // Bought outright.
          continue;
        }

        // A date that is present but unreadable must not fall through to
        // null: null is the shape of a lifetime purchase, so a mangled cache
        // would quietly grant a permanent subscription to everyone it touched.
        // Dropping it costs an offline user this entitlement until the next
        // successful refresh, which is the cheaper of the two mistakes.
        final expires = DateTime.tryParse('${entry.value}');
        if (expires == null) continue;

        grants[entitlement] = expires.toLocal();
      }

      return EntitlementSnapshot(
        grants: grants,
        refreshedAt: refreshedAt.toLocal(),
      );
    } on Object {
      return null;
    }
  }

  @override
  String toString() {
    if (grants.isEmpty) return 'EntitlementSnapshot(none @ $refreshedAt)';
    final held = grants.keys.map((e) => e.identifier).join(', ');
    return 'EntitlementSnapshot($held @ $refreshedAt)';
  }
}
