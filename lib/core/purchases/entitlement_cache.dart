import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import 'entitlements.dart';

/// The last answer the store gave, on disk.
///
/// Read synchronously before the first frame. The alternative — asking the
/// network first — means either a hole in the layout while it loads or, worse,
/// a banner ad shown to somebody who paid to remove it, which is the exact
/// complaint that gets a refund and a one-star review on the same afternoon.
///
/// Deliberately in SharedPreferences rather than the Drift database: it is one
/// small value, it is read before anything else is open, and losing it costs
/// nothing — the next refresh rebuilds it.
class EntitlementCache {
  const EntitlementCache(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'entitlements_v1';

  /// What the store last said, or null if it has never been asked here.
  EntitlementSnapshot? read() {
    final snapshot = EntitlementSnapshot.decode(_prefs.getString(_key));
    if (snapshot == null && _prefs.containsKey(_key)) {
      // Unreadable rather than absent. Say so: silently behaving like a fresh
      // install would hide a serialisation change that costs paying users
      // their entitlement on upgrade.
      AppLogger.warn('Entitlement cache unreadable, treating as empty');
    }
    return snapshot;
  }

  Future<void> write(EntitlementSnapshot snapshot) async {
    try {
      await _prefs.setString(_key, snapshot.encode());
    } on Object catch (e, s) {
      // A cache that will not write is a slow app, not a broken one.
      AppLogger.warn('Could not cache entitlements', e, s);
    }
  }

  Future<void> clear() => _prefs.remove(_key);
}
