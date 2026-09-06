import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/dignity.dart';
import 'package:nakshatra/core/astro/models.dart';

/// Sign dignity (KAN-53).
void main() {
  test('every exaltation sits opposite its debilitation', () {
    // Debilitation is derived rather than tabled, so this checks the
    // derivation rather than restating a second table.
    for (final graha in Graha.values) {
      final exalted = GrahaDignity.exaltationSign(graha);
      final debilitated = GrahaDignity.debilitationSign(graha);
      if (exalted == null) continue;

      expect(
        (debilitated!.index - exalted.index) % 12,
        6,
        reason: '${graha.en} is not debilitated opposite its exaltation',
      );
    }
  });

  test('the classical exaltations are right', () {
    expect(GrahaDignity.exaltationSign(Graha.sun), Rasi.mesha);
    expect(GrahaDignity.exaltationSign(Graha.moon), Rasi.vrishabha);
    expect(GrahaDignity.exaltationSign(Graha.mars), Rasi.makara);
    expect(GrahaDignity.exaltationSign(Graha.mercury), Rasi.kanya);
    expect(GrahaDignity.exaltationSign(Graha.jupiter), Rasi.karka);
    expect(GrahaDignity.exaltationSign(Graha.venus), Rasi.meena);
    expect(GrahaDignity.exaltationSign(Graha.saturn), Rasi.tula);
  });

  test('the classical debilitations follow', () {
    expect(GrahaDignity.debilitationSign(Graha.sun), Rasi.tula);
    expect(GrahaDignity.debilitationSign(Graha.moon), Rasi.vrischika);
    expect(GrahaDignity.debilitationSign(Graha.mars), Rasi.karka);
    expect(GrahaDignity.debilitationSign(Graha.mercury), Rasi.meena);
    expect(GrahaDignity.debilitationSign(Graha.jupiter), Rasi.makara);
    expect(GrahaDignity.debilitationSign(Graha.venus), Rasi.kanya);
    expect(GrahaDignity.debilitationSign(Graha.saturn), Rasi.mesha);
  });

  test('the twelve signs are ruled by the seven graha, no gaps', () {
    final ruled = <Rasi>{};
    for (final graha in Graha.values) {
      ruled.addAll(GrahaDignity.ownSigns(graha));
    }
    expect(ruled.length, 12, reason: 'every sign must have a ruler');
  });

  test('Mercury in Virgo reads as exalted, not merely own', () {
    // The one graha exalted in a sign it also rules. Reporting "own" here
    // would understate the strongest placement Mercury can have.
    expect(GrahaDignity.of(Graha.mercury, Rasi.kanya), Dignity.exalted);
    expect(GrahaDignity.ownSigns(Graha.mercury), contains(Rasi.kanya));
  });

  test('ordinary placements are neutral', () {
    expect(GrahaDignity.of(Graha.sun, Rasi.mithuna), Dignity.neutral);
    expect(GrahaDignity.of(Graha.saturn, Rasi.dhanu), Dignity.neutral);
  });

  test('own signs are recognised', () {
    expect(GrahaDignity.of(Graha.mars, Rasi.mesha), Dignity.own);
    expect(GrahaDignity.of(Graha.mars, Rasi.vrischika), Dignity.own);
    expect(GrahaDignity.of(Graha.venus, Rasi.tula), Dignity.own);
  });

  test('the nodes are given no dignity at all', () {
    // Traditions disagree on where Rāhu and Ketu are exalted, and some hold
    // they have no dignity. Null says "no judgement offered" rather than
    // silently picking a school.
    for (final rasi in Rasi.values) {
      expect(GrahaDignity.of(Graha.rahu, rasi), isNull);
      expect(GrahaDignity.of(Graha.ketu, rasi), isNull);
    }
    expect(GrahaDignity.exaltationSign(Graha.rahu), isNull);
    expect(GrahaDignity.ownSigns(Graha.ketu), isEmpty);
  });

  test('every graha with a dignity has an exaltation degree', () {
    for (final graha in Graha.values) {
      final hasSign = GrahaDignity.exaltationSign(graha) != null;
      expect(GrahaDignity.exaltationDegree(graha) != null, hasSign);
    }
  });
}
