import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/dasha.dart';
import '../../../core/astro/ephemeris.dart';
import '../../../core/astro/models.dart';
import '../../../core/logging/app_logger.dart';
import '../../chart/domain/chart_providers.dart';
import '../../home/domain/daily_providers.dart';
import '../../onboarding/data/profile_repository.dart';
import 'fragment.dart';
import 'horoscope_engine.dart';
import 'horoscope_signals.dart';

/// Wires the horoscope engine to the ephemeris and the authored copy (KAN-31).

/// The authored fragments for the current language.
///
/// Only English exists so far; si and ta are KAN-32. Falling back to English
/// rather than failing means the feature degrades to a readable horoscope in
/// the wrong language instead of an empty screen.
final horoscopeFragmentsProvider = FutureProvider<List<Fragment>>((ref) async {
  final locale = ref.watch(localeProvider);

  Future<String?> load(String code) async {
    try {
      return await rootBundle.loadString('assets/content/horoscope_$code.json');
    } on Object {
      return null;
    }
  }

  final raw = await load(locale.name) ?? await load('en');
  if (raw == null) {
    AppLogger.warn('No horoscope content bundled');
    return const [];
  }

  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final f in json['fragments'] as List)
        Fragment.fromJson(f as Map<String, dynamic>),
    ];
  } on Object catch (e, s) {
    // Malformed copy must not take the app down: KAN-32 will be editing this
    // file by hand, in three scripts.
    AppLogger.warn('Horoscope content failed to parse', e, s);
    return const [];
  }
});

/// Where each graha sits on the selected day.
///
/// Computed at local noon rather than at the moment the app is opened, so the
/// reading does not change during the day. The Moon moves about half a degree
/// an hour, which is enough to cross a sign boundary mid-morning and silently
/// rewrite someone's horoscope while they are reading it.
final transitingPositionsProvider = Provider<Map<Graha, Rasi>?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;

  final date = ref.watch(selectedDateProvider);
  final result = Ephemeris.computeChart(
    localWallClock: DateTime(date.year, date.month, date.day, 12),
    zoneName: profile.place.timezone,
    latitude: profile.place.latitude,
    longitude: profile.place.longitude,
  );

  final chart = result.valueOrNull;
  if (chart == null) return null;
  return {
    for (final entry in chart.positions.entries) entry.key: entry.value.rasi,
  };
});

/// The reader's janma rāśi — the sign their natal Moon occupied.
final janmaRasiProvider = Provider<Rasi?>((ref) {
  final chart = ref.watch(chartProvider)?.valueOrNull;
  return chart?[Graha.moon].rasi;
});

/// Today's signals for the reader's sign.
final horoscopeSignalsProvider = Provider<HoroscopeSignals?>((ref) {
  final rasi = ref.watch(janmaRasiProvider);
  final transiting = ref.watch(transitingPositionsProvider);
  if (rasi == null || transiting == null) return null;

  final chart = ref.watch(chartProvider)?.valueOrNull;
  final natal = chart == null
      ? null
      : <Graha, Rasi>{
          for (final e in chart.positions.entries) e.key: e.value.rasi,
        };

  final date = ref.watch(selectedDateProvider);

  DashaSnapshot? dasha;
  if (chart != null) {
    dasha = Vimshottari.at(Vimshottari.forChart(chart), date);
  }

  return HoroscopeSignals.from(
    rasi: rasi,
    date: date,
    transiting: transiting,
    natal: natal,
    dasha: dasha,
  );
});

/// The finished reading, or null before onboarding.
final horoscopeProvider = Provider<Horoscope?>((ref) {
  final signals = ref.watch(horoscopeSignalsProvider);
  if (signals == null) return null;

  final fragments = ref.watch(horoscopeFragmentsProvider).value;
  if (fragments == null || fragments.isEmpty) return null;

  return HoroscopeEngine.build(signals: signals, fragments: fragments);
});
