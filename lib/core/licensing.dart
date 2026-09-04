/// Licensing facts the app must surface to its users.
///
/// Nakshatra links the Swiss Ephemeris, which is dual-licensed: AGPL-3.0 or a
/// paid commercial licence. We use the AGPL edition, so this app is itself
/// AGPL-3.0 and every user who receives a binary is entitled to its source.
///
/// The AGPL permits commercial use — advertising and paid features are fine.
/// The obligation is source availability, nothing else.
abstract final class Licensing {
  static const String appLicense = 'AGPL-3.0-or-later';

  /// Where the corresponding source for this build can be obtained.
  ///
  /// This must stay reachable and must point at the source for the version
  /// actually shipped. Satisfying the AGPL is the entire reason the repository
  /// is public.
  static const String sourceUrl =
      'https://github.com/chamod-ishankha/helocode-nakshatra';

  static const String licenseUrl = 'https://www.gnu.org/licenses/agpl-3.0.html';

  /// Third-party components whose licences must be shown to users.
  static const List<Attribution> attributions = [
    Attribution(
      name: 'Swiss Ephemeris',
      author: 'Astrodienst AG',
      license: 'AGPL-3.0',
      url: 'https://www.astro.com/swisseph/',
      note:
          'Planetary positions, houses and ayanamsa. Used under the AGPL '
          'edition, which is why this app is also AGPL.',
    ),
    Attribution(
      name: 'IANA Time Zone Database',
      author: 'IANA',
      license: 'Public domain',
      url: 'https://www.iana.org/time-zones',
      note: 'Historical timezone offsets, including Sri Lanka 1996-2006.',
    ),
    Attribution(
      name: 'Flutter',
      author: 'Google LLC',
      license: 'BSD-3-Clause',
      url: 'https://flutter.dev',
    ),
  ];

  /// Short notice for the about screen and the Play Store listing.
  static const String notice =
      'Nakshatra is free software licensed under the GNU Affero General '
      'Public License v3. It uses the Swiss Ephemeris by Astrodienst AG. '
      'The complete source code is available at $sourceUrl';
}

class Attribution {
  const Attribution({
    required this.name,
    required this.author,
    required this.license,
    required this.url,
    this.note,
  });

  final String name;
  final String author;
  final String license;
  final String url;
  final String? note;
}
