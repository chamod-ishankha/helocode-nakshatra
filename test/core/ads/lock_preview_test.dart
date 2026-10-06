import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/lock_preview.dart';

/// How much of a locked list shows before the lock (KAN-70).
void main() {
  test('shows the first two rows of the lists the app locks', () {
    // Nine pratyantardaśā, eight kootas, ten porondam judged.
    for (final total in [9, 8, 10]) {
      expect(previewCount(total), 2, reason: '$total');
    }
  });

  test('always keeps at least one row behind the lock', () {
    // Two rows free of a two-row list would be the whole thing given away.
    expect(previewCount(2), 1);
    expect(previewCount(1), 0);
    expect(previewCount(0), 0);
  });
}
