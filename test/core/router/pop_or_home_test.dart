import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nakshatra/core/router/app_router.dart';

/// Back navigation.
///
/// The real screens need the Swiss Ephemeris native library and cannot render
/// under `flutter test`, so these use stand-in routes at the same paths. What
/// is under test is the navigation contract, not the screens:
///
///  * a forward move must leave something to go back to
///  * the system back button must never close the app from a sub-screen
///  * a back control must still work on a screen reached with no stack
///
/// The real flow is covered on device in
/// integration_test/back_navigation_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget stub(String label) => Scaffold(
    appBar: AppBar(
      title: Text(label),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrHome(context),
        ),
      ),
    ),
    body: Builder(
      builder: (context) => Column(
        children: [
          TextButton(
            onPressed: () => context.push(Routes.chart),
            child: const Text('push chart'),
          ),
          TextButton(
            onPressed: () => context.push(Routes.account),
            child: const Text('push account'),
          ),
        ],
      ),
    ),
  );

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    String initial = Routes.home,
  }) async {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: Routes.home, builder: (_, _) => stub('Home')),
        GoRoute(path: Routes.chart, builder: (_, _) => stub('Chart')),
        GoRoute(path: Routes.account, builder: (_, _) => stub('Account')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('the system back button returns instead of closing the app', (
    tester,
  ) async {
    await pumpRouter(tester);

    await tester.tap(find.text('push chart'));
    await tester.pumpAndSettle();
    expect(find.text('Chart'), findsOneWidget);

    // The bug this guards: context.go replaces the stack, so there was
    // nothing to pop and Android closed the app. handlePopRoute returning
    // false is precisely that — nothing handled the back.
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      handled,
      isTrue,
      reason: 'back was unhandled, which closes the app',
    );
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the same holds for the account screen', (tester) async {
    await pumpRouter(tester);

    await tester.tap(find.text('push account'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('the header back button goes back one screen', (tester) async {
    await pumpRouter(tester);

    await tester.tap(find.text('push chart'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('two pushes unwind one screen at a time', (tester) async {
    await pumpRouter(tester);

    await tester.tap(find.text('push chart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('push account'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);

    // Going straight home from a depth of two would silently discard a screen
    // the user expects to come back to.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Chart'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a screen landed on with no stack still has a way back', (
    tester,
  ) async {
    // A restart restoring this location, or a redirect, leaves nothing behind
    // it. Popping blindly there would close the app.
    final router = await pumpRouter(tester, initial: Routes.chart);
    expect(find.text('Chart'), findsOneWidget);
    expect(router.canPop(), isFalse);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
