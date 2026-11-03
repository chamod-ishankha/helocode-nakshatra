import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/notifications/reminder_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When Home asks the reader to allow reminders, and what each answer does.
void main() {
  late SharedPreferences prefs;
  late int settingsOpened;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settingsOpened = 0;
  });

  ReminderPrompt prompt({
    bool granted = false,
    Duration answeredAfter = const Duration(seconds: 1),
  }) => ReminderPrompt(
    prefs: prefs,
    request: () async {
      await Future<void>.delayed(answeredAfter);
      return granted;
    },
    openSettings: () async => settingsOpened++,
  );

  group('the card shows', () {
    test('when reminders are on and Android does not allow them', () {
      expect(
        prompt().shouldShow(
          remindersOn: true,
          allowed: false,
          closedThisLaunch: false,
        ),
        isTrue,
      );
    });

    test('not once notifications are allowed', () {
      expect(
        prompt().shouldShow(
          remindersOn: true,
          allowed: true,
          closedThisLaunch: false,
        ),
        isFalse,
      );
    });

    test('not when the reader turned every reminder off', () {
      expect(
        prompt().shouldShow(
          remindersOn: false,
          allowed: false,
          closedThisLaunch: false,
        ),
        isFalse,
      );
    });
  });

  group('closing the card', () {
    test('without the box hides it this launch only', () async {
      final p = prompt();
      await p.close(neverAgain: false);
      expect(
        p.shouldShow(remindersOn: true, allowed: false, closedThisLaunch: true),
        isFalse,
      );
      // Next launch: the in-memory flag starts false again.
      expect(
        prompt().shouldShow(
          remindersOn: true,
          allowed: false,
          closedThisLaunch: false,
        ),
        isTrue,
      );
    });

    test('with "Don\'t ask again" ticked hides it for good', () async {
      await prompt().close(neverAgain: true);
      expect(
        prompt().shouldShow(
          remindersOn: true,
          allowed: false,
          closedThisLaunch: false,
        ),
        isFalse,
      );
    });
  });

  group('Enable', () {
    test('allowed in the dialog needs nothing more', () async {
      expect(await prompt(granted: true).enable(), isTrue);
      expect(settingsOpened, 0);
    });

    test('refused in the dialog leaves the reader where they are', () async {
      expect(await prompt().enable(), isFalse);
      expect(settingsOpened, 0);
    });

    test(
      'refused before anyone could read a dialog opens system settings',
      () async {
        // Android stops showing the dialog after two refusals and answers no
        // at once; Enable must still lead somewhere.
        expect(await prompt(answeredAfter: Duration.zero).enable(), isFalse);
        expect(settingsOpened, 1);
      },
    );
  });
}
