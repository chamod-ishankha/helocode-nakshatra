import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';

/// The entitlement rules (KAN-35).
///
/// This is the money logic. Every case here is one where being wrong costs
/// something real: withholding Pro from somebody who paid, or handing out a
/// subscription that has lapsed. None of it needs a device or a store, which
/// is the whole reason the SDK sits behind a gateway.
void main() {
  final jan1 = DateTime(2026, 1, 1);

  EntitlementSnapshot snapshot(
    Map<Entitlement, DateTime?> grants, {
    required DateTime refreshedAt,
  }) => EntitlementSnapshot(grants: grants, refreshedAt: refreshedAt);

  group('a purchase that never expires', () {
    test('stays active years later', () {
      // remove_ads is bought outright. There is no date on it, and a user who
      // paid once must still be ad-free after a phone, a reinstall and a
      // decade.
      final s = snapshot({Entitlement.adFree: null}, refreshedAt: jan1);

      expect(s.isActive(Entitlement.adFree, jan1), isTrue);
      expect(s.isActive(Entitlement.adFree, DateTime(2036)), isTrue);
    });

    test('does not grant anything it was not bought with', () {
      final s = snapshot({Entitlement.adFree: null}, refreshedAt: jan1);

      expect(s.isActive(Entitlement.pro, jan1), isFalse);
    });
  });

  group('a subscription', () {
    final expires = DateTime(2026, 1, 10);

    test('is active up to the expiry the store gave us', () {
      final s = snapshot({Entitlement.pro: expires}, refreshedAt: jan1);

      expect(s.isActive(Entitlement.pro, DateTime(2026, 1, 9)), isTrue);
      expect(s.isActive(Entitlement.pro, expires), isTrue);
    });

    test('keeps working past the expiry while we cannot ask the store', () {
      // The case this exists for: a paying customer with no data for a few
      // days. Cutting them off because the phone is offline produces a refund
      // request; extending a lapsed subscription for three days costs nothing.
      final s = snapshot({Entitlement.pro: expires}, refreshedAt: jan1);

      expect(s.isActive(Entitlement.pro, DateTime(2026, 1, 12)), isTrue);
    });

    test('stops once the grace period is over', () {
      final s = snapshot({Entitlement.pro: expires}, refreshedAt: jan1);

      expect(
        s.isActive(Entitlement.pro, expires.add(EntitlementSnapshot.offlineGrace)),
        isFalse,
      );
      expect(s.isActive(Entitlement.pro, DateTime(2026, 2, 1)), isFalse);
    });

    test('gets no grace when the store has answered since it expired', () {
      // If the store replied after the expiry and still listed this, the date
      // is contradictory — a renewal would have moved it. Believing the date
      // rather than the listing is the safe reading, and it keeps the grace
      // window strictly for answers we know are stale.
      final s = snapshot(
        {Entitlement.pro: expires},
        refreshedAt: DateTime(2026, 1, 11),
      );

      expect(s.isActive(Entitlement.pro, DateTime(2026, 1, 11, 1)), isFalse);
    });
  });

  group('winding the device clock back', () {
    test('does not revive a subscription that expired before the last refresh', () {
      // Free Pro with no tools: set the date back and an expiry stops being in
      // the past. The floor at refreshedAt blocks it.
      final s = snapshot(
        {Entitlement.pro: DateTime(2026, 1, 10)},
        refreshedAt: DateTime(2026, 3, 1),
      );

      expect(s.isActive(Entitlement.pro, DateTime(2026, 1, 5)), isFalse);
    });

    test('does not disturb a purchase that never expires', () {
      final s = snapshot(
        {Entitlement.adFree: null},
        refreshedAt: DateTime(2026, 3, 1),
      );

      expect(s.isActive(Entitlement.adFree, DateTime(2020)), isTrue);
    });
  });

  group('what a feature needs', () {
    test('either Pro tier or the one-time purchase removes ads', () {
      final bought = snapshot({Entitlement.adFree: null}, refreshedAt: jan1);
      final pro = snapshot(
        {Entitlement.pro: DateTime(2026, 6, 1)},
        refreshedAt: jan1,
      );

      expect(bought.has(PaidFeature.removeAds, jan1), isTrue);
      expect(pro.has(PaidFeature.removeAds, jan1), isTrue);
    });

    test('removing ads does not unlock Pro features', () {
      final s = snapshot({Entitlement.adFree: null}, refreshedAt: jan1);

      expect(s.has(PaidFeature.removeAds, jan1), isTrue);
      expect(s.has(PaidFeature.fullDashaTimeline, jan1), isFalse);
      expect(s.has(PaidFeature.multipleProfiles, jan1), isFalse);
    });

    test('Pro does not include the two report products', () {
      // Following the list of Pro unlocks on KAN-35 exactly. Pinned in a test
      // because it is a pricing decision that looks like an oversight: most
      // ladders fold both into the top tier.
      final pro = snapshot(
        {Entitlement.pro: DateTime(2026, 6, 1)},
        refreshedAt: jan1,
      );

      expect(pro.has(PaidFeature.birthChartPdf, jan1), isFalse);
      expect(pro.has(PaidFeature.compatibilityReport, jan1), isFalse);
    });

    test('a lapsed Pro closes every Pro feature at once', () {
      final s = snapshot(
        {Entitlement.pro: DateTime(2026, 1, 10)},
        refreshedAt: jan1,
      );
      final afterGrace = DateTime(2026, 2, 1);

      for (final feature in PaidFeature.values) {
        expect(
          s.has(feature, afterGrace),
          isFalse,
          reason: '${feature.name} should be closed',
        );
      }
    });

    test('holding nothing opens nothing', () {
      final none = EntitlementSnapshot.unknown();

      for (final feature in PaidFeature.values) {
        expect(none.has(feature, jan1), isFalse, reason: feature.name);
      }
    });
  });

  group('reading and writing the cache', () {
    test('a snapshot survives the round trip', () {
      final original = snapshot({
        Entitlement.adFree: null,
        Entitlement.pro: DateTime(2026, 6, 1, 14, 30),
      }, refreshedAt: DateTime(2026, 1, 1, 9));

      final back = EntitlementSnapshot.decode(original.encode())!;

      expect(back.grants[Entitlement.adFree], isNull);
      expect(back.grants.containsKey(Entitlement.adFree), isTrue);
      expect(back.grants[Entitlement.pro], DateTime(2026, 6, 1, 14, 30));
      expect(back.refreshedAt, DateTime(2026, 1, 1, 9));
    });

    test('a lifetime purchase does not come back as an expiry', () {
      // The dangerous direction of the null: a bought-outright entitlement
      // that decodes with a date would silently expire, and the user would be
      // shown ads they paid to remove.
      final back = EntitlementSnapshot.decode(
        snapshot({Entitlement.adFree: null}, refreshedAt: jan1).encode(),
      )!;

      expect(back.isActive(Entitlement.adFree, DateTime(2050)), isTrue);
    });

    test('an entitlement this build does not know is skipped, not fatal', () {
      // The dashboard can gain an entitlement before the app that understands
      // it ships. An old build must keep running.
      const raw =
          '{"refreshedAt":"2026-01-01T00:00:00.000Z",'
          '"grants":{"ad_free":null,"family_plan":null}}';

      final back = EntitlementSnapshot.decode(raw)!;

      expect(back.grants.keys, [Entitlement.adFree]);
    });

    test('unreadable cache decodes to null rather than throwing', () {
      // Read before the first frame. A throw here is a launch crash.
      for (final raw in [
        null,
        '',
        'not json',
        '[]',
        '{"grants":{}}', // no refreshedAt
        '{"refreshedAt":"never","grants":{}}',
        '{"refreshedAt":"2026-01-01T00:00:00.000Z"}', // no grants
      ]) {
        expect(EntitlementSnapshot.decode(raw), isNull, reason: '$raw');
      }
    });

    test('an unreadable expiry inside a valid cache drops that entitlement', () {
      const raw =
          '{"refreshedAt":"2026-01-01T00:00:00.000Z",'
          '"grants":{"pro":"soon"}}';

      final back = EntitlementSnapshot.decode(raw)!;

      // Present but with no date is exactly the shape of a lifetime purchase,
      // so it must not land there: an unreadable date must never become
      // "never expires".
      expect(back.isActive(Entitlement.pro, DateTime(2050)), isFalse);
    });
  });

  group('dashboard identifiers', () {
    test('every entitlement maps back from its identifier', () {
      for (final e in Entitlement.values) {
        expect(Entitlement.fromIdentifier(e.identifier), e);
      }
    });

    test('identifiers are unique and lower_snake_case', () {
      // They have to match the RevenueCat dashboard character for character.
      // A typo is invisible at compile time and shows up as a paying user who
      // still sees ads.
      final ids = Entitlement.values.map((e) => e.identifier).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[a-z][a-z0-9_]*$')), reason: id);
      }
    });

    test('an unknown identifier is null, not an exception', () {
      expect(Entitlement.fromIdentifier('lifetime_pro'), isNull);
      expect(Entitlement.fromIdentifier(''), isNull);
    });
  });
}
