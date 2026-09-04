import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/app.dart';
import 'package:nakshatra/core/config/flavor.dart';

void main() {
  testWidgets('app boots and renders the home screen', (tester) async {
    FlavorConfig.initialize(Flavor.dev);

    await tester.pumpWidget(const ProviderScope(child: NakshatraApp()));
    await tester.pumpAndSettle();

    // Trilingual title proves the theme's font fallback renders Sinhala and
    // Tamil glyphs rather than tofu boxes.
    expect(find.text('නැකත්'), findsOneWidget);
    expect(find.text('நட்சத்திரம்'), findsOneWidget);
    expect(find.text('Nakshatra'), findsOneWidget);
  });

  testWidgets('dev builds show the debug banner, prod does not', (
    tester,
  ) async {
    FlavorConfig.initialize(Flavor.prod);
    await tester.pumpWidget(const ProviderScope(child: NakshatraApp()));
    await tester.pumpAndSettle();
    expect(find.text('Flavor: prod'), findsOneWidget);

    FlavorConfig.initialize(Flavor.dev);
  });
}
