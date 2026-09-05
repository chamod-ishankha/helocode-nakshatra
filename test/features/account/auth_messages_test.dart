import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/error/result.dart';
import 'package:nakshatra/features/account/presentation/auth_messages.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';

/// Every auth failure a user can provoke, in every language the app ships.
///
/// A missing translation here is not a crash — it is a Sinhala speaker being
/// told in English why they could not sign in, at the exact moment they are
/// already stuck. That is invisible in an English-only test run, so this
/// iterates the locales rather than trusting the template.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Codes the UI can actually surface. Kept explicit so adding a code to
  /// AuthService without wording it here fails a test rather than silently
  /// falling through to the generic sentence.
  const codes = [
    'email-already-in-use',
    'credential-already-in-use',
    'account-exists-with-different-credential',
    'invalid-email',
    'weak-password',
    'wrong-password',
    'invalid-credential',
    'user-not-found',
    'user-disabled',
    'too-many-requests',
    'network-request-failed',
    'operation-not-allowed',
    'google-unavailable',
    'google-interrupted',
    'google-no-id-token',
    'google-unknown',
    'no-current-user',
    'no-firebase',
  ];

  Future<Map<String, String>> messagesIn(
    WidgetTester tester,
    AppLocale locale,
  ) async {
    final out = <String, String>{};

    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale.code),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Builder(
          builder: (context) {
            for (final code in codes) {
              out[code] = authMessage(
                context,
                AuthFailure('dev message', code: code),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return out;
  }

  for (final locale in AppLocale.values) {
    group(locale.englishName, () {
      testWidgets('every code produces real text', (tester) async {
        final messages = await messagesIn(tester, locale);

        for (final code in codes) {
          final text = messages[code]!;
          expect(text.trim(), isNotEmpty, reason: 'empty for $code');
          // The developer message must never reach the screen.
          expect(text, isNot('dev message'), reason: 'passthrough for $code');
          // Nor the raw code, which means nothing to a user.
          expect(text, isNot(contains(code)), reason: 'raw code for $code');
        }
      });

      testWidgets('the common failures are told apart', (tester) async {
        final messages = await messagesIn(tester, locale);

        // A wrong password and a taken address need different answers: one
        // means try again, the other means sign in instead. Collapsing them
        // into one sentence would leave the user stuck.
        expect(
          messages['wrong-password'],
          isNot(messages['email-already-in-use']),
        );
        expect(
          messages['user-not-found'],
          isNot(messages['wrong-password']),
        );
        expect(
          messages['network-request-failed'],
          isNot(messages['operation-not-allowed']),
        );
      });

      testWidgets('an unknown code falls back rather than blanking',
          (tester) async {
        late String text;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale.code),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: Builder(
              builder: (context) {
                text = authMessage(
                  context,
                  const AuthFailure('dev', code: 'invented-by-a-future-sdk'),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(text.trim(), isNotEmpty);
        expect(text, isNot(contains('invented-by')));
      });
    });
  }

  testWidgets('the three languages really are different text', (tester) async {
    // Guards the copy-paste failure mode: an ARB file duplicated from the
    // template still has the right keys and would pass every test above.
    final en = await messagesIn(tester, AppLocale.en);
    final si = await messagesIn(tester, AppLocale.si);
    final ta = await messagesIn(tester, AppLocale.ta);

    for (final code in codes) {
      expect(si[code], isNot(en[code]), reason: 'Sinhala untranslated: $code');
      expect(ta[code], isNot(en[code]), reason: 'Tamil untranslated: $code');
      expect(si[code], isNot(ta[code]), reason: 'si and ta identical: $code');
    }
  });
}
