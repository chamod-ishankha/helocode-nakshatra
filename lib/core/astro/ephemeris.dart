import 'package:sweph/sweph.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../error/result.dart';
import '../logging/app_logger.dart';
import 'models.dart';

/// Swiss Ephemeris wrapper.
///
/// Everything runs on-device. No birth data is ever sent anywhere, which is
/// both the product promise and what the privacy policy commits us to.
///
/// ## Ephemeris choice
///
/// We use the **Moshier** analytical ephemeris ([SwephFlag.SEFLG_MOSEPH]),
/// which is compiled into the native library and needs no data files. The
/// alternative, SEFLG_SWIEPH, is marginally more precise but requires shipping
/// several megabytes of `.se1` files.
///
/// Moshier is accurate to roughly one arc-second between 1800 and 2400. The
/// accuracy gate for this project (KAN-17) is one arc-minute — sixty times
/// looser — so the extra megabytes buy nothing a user could ever perceive.
/// Revisit only if validation against a printed litha actually fails.
///
/// ## Ayanāṃśa
///
/// Lahiri (Chitrapaksha), the official ayanāṃśa of the Indian government and
/// the standard across Sri Lanka and India. Using the tropical zodiac here
/// would place most people in the wrong rāśi entirely.
abstract final class Ephemeris {
  static bool _ready = false;

  static const SwephFlag _baseFlags = SwephFlag(
    4 | 256 | (64 * 1024), // SEFLG_MOSEPH | SEFLG_SPEED | SEFLG_SIDEREAL
  );

  static bool get isReady => _ready;

  /// Loads the native library and the timezone database.
  ///
  /// Safe to call more than once; later calls are no-ops.
  static Future<void> initialize() async {
    if (_ready) return;

    await Sweph.init();
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
    tzdata.initializeTimeZones();

    _ready = true;
    AppLogger.info('Ephemeris ready (Moshier, Lahiri ayanamsa)');
  }

  /// Converts a wall-clock birth time in [zoneName] to a Julian day in UT.
  ///
  /// This must go through the IANA timezone database rather than a fixed
  /// offset. Sri Lanka moved from +05:30 to +06:30 in 1996, to +06:00 later
  /// that year, and back to +05:30 in 2006. Anyone born inside that window
  /// gets a chart up to an hour wrong if the offset is hardcoded — which
  /// shifts the ascendant by roughly 15 degrees, half a rāśi.
  static double julianDayFromLocal({
    required DateTime localWallClock,
    required String zoneName,
  }) {
    final location = tz.getLocation(zoneName);
    final local = tz.TZDateTime(
      location,
      localWallClock.year,
      localWallClock.month,
      localWallClock.day,
      localWallClock.hour,
      localWallClock.minute,
      localWallClock.second,
    );
    final utc = local.toUtc();

    final hours = utc.hour + utc.minute / 60.0 + utc.second / 3600.0;

    return Sweph.swe_julday(
      utc.year,
      utc.month,
      utc.day,
      hours,
      CalendarType.SE_GREG_CAL,
    );
  }

  /// Computes a sidereal birth chart.
  ///
  /// Returns a [Failure] rather than throwing: an out-of-range date or a bad
  /// coordinate is an expected user-input problem, not a programmer error.
  static Result<BirthChart> computeChart({
    required DateTime localWallClock,
    required String zoneName,
    required double latitude,
    required double longitude,
  }) {
    if (!_ready) {
      return const Result.failure(
        EphemerisFailure('Ephemeris not initialised — call initialize() first'),
      );
    }
    if (latitude < -90 || latitude > 90) {
      return Result.failure(
        InvalidBirthDataFailure('Latitude out of range: $latitude'),
      );
    }
    if (longitude < -180 || longitude > 180) {
      return Result.failure(
        InvalidBirthDataFailure('Longitude out of range: $longitude'),
      );
    }
    // Moshier is only defined over roughly 3000 BCE - 3000 CE, and our
    // validation only covers modern dates.
    if (localWallClock.year < 1800 || localWallClock.year > 2399) {
      return Result.failure(
        InvalidBirthDataFailure(
          'Birth year ${localWallClock.year} is outside the supported '
          'range 1800-2399',
        ),
      );
    }

    try {
      final jd = julianDayFromLocal(
        localWallClock: localWallClock,
        zoneName: zoneName,
      );

      // Whole-sign houses (Hsys.W): the Sri Lankan and Indian convention, where
      // house 1 is the entire rāśi holding the lagna. Quadrant systems such as
      // Placidus would give different house placements and wrong readings.
      final houses = Sweph.swe_houses_ex(
        jd,
        _baseFlags,
        latitude,
        longitude,
        Hsys.W,
      );

      final ascendant = houses.ascmc[0];
      final midheaven = houses.ascmc[1];
      final ayanamsa = Sweph.swe_get_ayanamsa_ex_ut(jd, _baseFlags);
      final lagnaSign = (ascendant ~/ 30) % 12;

      final positions = <Graha, GrahaPosition>{};
      for (final graha in Graha.values) {
        if (graha == Graha.ketu) continue;

        final coords = Sweph.swe_calc_ut(jd, graha.body!, _baseFlags);
        positions[graha] = _position(
          graha,
          coords.longitude,
          coords.latitude,
          coords.speedInLongitude,
          lagnaSign,
        );
      }

      // Ketu is always exactly opposite Rahu.
      final rahu = positions[Graha.rahu]!;
      positions[Graha.ketu] = _position(
        Graha.ketu,
        (rahu.longitude + 180) % 360,
        -rahu.latitude,
        rahu.speed,
        lagnaSign,
      );

      return Result.success(
        BirthChart(
          julianDayUt: jd,
          ascendant: ascendant,
          midheaven: midheaven,
          ayanamsa: ayanamsa,
          positions: positions,
        ),
      );
    } on Exception catch (e, s) {
      AppLogger.error('Chart calculation failed', e, s);
      return Result.failure(
        EphemerisFailure('Could not calculate the chart', cause: e),
      );
    }
  }

  static GrahaPosition _position(
    Graha graha,
    double longitude,
    double latitude,
    double speed,
    int lagnaSign,
  ) {
    final lon = longitude % 360;
    final sign = (lon ~/ 30) % 12;
    return GrahaPosition(
      graha: graha,
      longitude: lon < 0 ? lon + 360 : lon,
      latitude: latitude,
      speed: speed,
      house: ((sign - lagnaSign + 12) % 12) + 1,
    );
  }
}
