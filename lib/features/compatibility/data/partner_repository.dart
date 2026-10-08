import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../../onboarding/domain/birth_profile.dart';

/// The last partner a match was checked against, kept on this phone.
///
/// Local only, on purpose. It is someone else's birth data, entered without
/// their say, so it is never added to the cloud backup the way the reader's
/// own profiles are; and "delete my data" removes it with everything else.
///
/// One partner, not a list: the screen compares the reader with one person
/// at a time, and anyone the reader wants to keep for good can already be a
/// saved chart, which the partner form offers to pick from.
class PartnerRepository {
  PartnerRepository(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'compat_partner_v1';

  BirthProfile? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return BirthProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (e) {
      // A partner this build cannot read is worth less than the error it
      // would raise on every visit to the screen.
      AppLogger.warn('Saved partner unreadable, discarding: $e');
      _prefs.remove(key);
      return null;
    }
  }

  Future<void> save(BirthProfile partner) =>
      _prefs.setString(key, jsonEncode(partner.toJson()));

  Future<void> clear() => _prefs.remove(key);
}
