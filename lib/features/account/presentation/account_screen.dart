import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/result.dart';
import '../../../core/router/app_router.dart';
import '../../../core/sync/auth_service.dart';
import '../../../core/sync/profile_sync.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../onboarding/domain/birth_profile.dart';

/// Attaching a real identity to the anonymous account (KAN-48).
///
/// The screen exists to answer one question — "will I lose my chart?" — so the
/// current state is stated at the top in those terms rather than as a provider
/// name or an account type.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// False shows the create-account copy, true the sign-in copy. Same fields
  /// either way, so this only changes wording and which call is made.
  bool _signingIn = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = ref.read(authServiceProvider);
    final profiles = ref.read(profileProvider.notifier);
    final sync = ref.read(profileSyncProvider);

    final result = _signingIn
        // Deleting the anonymous copy is not tidiness. That document becomes
        // permanently unreachable the moment the uid changes, and it holds
        // birth details, so leaving it would mean keeping personal data
        // nobody can ever see or delete.
        ? await auth.signInEmail(
            _email.text,
            _password.text,
            onAbandon: sync.clear,
          )
        : await auth.linkEmail(_email.text, _password.text);

    if (!mounted) return;

    switch (result) {
      case Success():
        if (_signingIn) await _reconcile(profiles);
        if (!mounted) return;
        setState(() => _busy = false);
        _confirm(
          _signingIn ? 'Signed in.' : 'Account created. Your chart is safe.',
        );
      case FailureResult(:final failure):
        final taken =
            failure is AuthFailure && AuthService.isEmailTaken(failure.code);
        setState(() {
          _busy = false;
          _error = failure.message;
          // The address existing is not a dead end, it is the sign-in case.
          // Flipping the form is the whole remedy, so do it for them.
          if (taken) _signingIn = true;
        });
    }
  }

  /// One button for both cases.
  ///
  /// Linking is tried first because it is the one that keeps the uid and so
  /// cannot lose the backup. Only when Google says the account already exists
  /// here does this fall back to signing in, which is the path that has to
  /// reconcile two profiles.
  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = ref.read(authServiceProvider);
    final profiles = ref.read(profileProvider.notifier);
    final sync = ref.read(profileSyncProvider);

    var result = await auth.linkGoogle();

    final failure = result.failureOrNull;
    if (failure is AuthFailure && AuthService.isEmailTaken(failure.code)) {
      result = await auth.signInGoogle(onAbandon: sync.clear);
      if (result.isSuccess) {
        await _reconcile(profiles);
      }
    }

    if (!mounted) return;

    setState(() {
      _busy = false;
      final f = result.failureOrNull;
      // Backing out of the Google sheet is not an error. Showing one would
      // accuse the user of a mistake they did not make.
      _error = (f is AuthFailure && f.code == 'google-canceled')
          ? null
          : f?.message;
    });

    if (result.isSuccess) _confirm('Signed in with Google.');
  }

  /// Resolves the two-profile fork, asking only when it is genuinely a choice.
  Future<void> _reconcile(ProfileNotifier profiles) async {
    final remote = await profiles.reconcileAfterSignIn();
    if (remote == null || !mounted) return;

    final keepAccount = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ConflictDialog(remote: remote),
    );

    if (keepAccount ?? false) {
      await profiles.keepAccountProfile(remote);
    } else {
      await profiles.keepDeviceProfile();
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    final result = await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.failureOrNull?.message;
    });
    if (result.isSuccess) _confirm('Signed out.');
  }

  void _confirm(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(accountStatusProvider).value;
    final kind = status?.kind ?? AccountKind.none;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(kind: kind, email: status?.email),
          const SizedBox(height: 24),
          if (kind == AccountKind.permanent)
            _SignedIn(busy: _busy, onSignOut: _signOut)
          else if (kind == AccountKind.none)
            const _Unavailable()
          else ...[
            if (AuthService.googleAvailable) ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : _google,
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: theme.textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _Form(
              formKey: _formKey,
              email: _email,
              password: _password,
              signingIn: _signingIn,
              busy: _busy,
              error: _error,
              onSubmit: _submit,
              onToggleMode: () => setState(() {
                _signingIn = !_signingIn;
                _error = null;
              }),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Your chart, nekath and the almanac are worked out on this phone '
            'and keep working with no account and no connection. An account '
            'only decides whether your birth details survive losing the phone.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.kind, this.email});

  final AccountKind kind;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (IconData icon, String title, String body, Color colour) =
        switch (kind) {
          AccountKind.permanent => (
            Icons.verified_user_outlined,
            'Saved to $email',
            'Sign in with this email on a new phone and your birth details '
                'come back.',
            theme.colorScheme.primary,
          ),
          AccountKind.anonymous => (
            Icons.phonelink_lock_outlined,
            'Saved to this phone only',
            'Your birth details are backed up, but the backup belongs to this '
                'installation. Clearing app data or moving to a new phone '
                'loses it for good.',
            theme.colorScheme.error,
          ),
          AccountKind.none => (
            Icons.cloud_off_outlined,
            'Backup unavailable',
            'No connection to the backup service. Everything else works.',
            theme.colorScheme.onSurfaceVariant,
          ),
        };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: colour, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colour),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.formKey,
    required this.email,
    required this.password,
    required this.signingIn,
    required this.busy,
    required this.error,
    required this.onSubmit,
    required this.onToggleMode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool signingIn;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            signingIn ? 'Sign in' : 'Keep your chart safe',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Enter your email';
              // Deliberately loose. Anything stricter rejects addresses that
              // are perfectly valid, and Firebase checks it properly anyway.
              if (!value.contains('@') || !value.contains('.')) {
                return 'That does not look like an email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: password,
            enabled: !busy,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if ((v ?? '').isEmpty) return 'Enter a password';
              // Firebase's own minimum. Checking it here turns a round trip
              // and a raw error code into an instant, readable one.
              if (!signingIn && v!.length < 6) {
                return 'Use at least 6 characters';
              }
              return null;
            },
          ),
          if (!signingIn) ...[
            const SizedBox(height: 12),
            _VerificationNotice(),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            child: busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(signingIn ? 'Sign in' : 'Create account'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy ? null : onToggleMode,
            child: Text(
              signingIn
                  ? 'No account yet? Create one'
                  : 'Already have an account? Sign in',
            ),
          ),
        ],
      ),
    );
  }
}

/// Stated plainly because it is the one thing a user cannot find out for
/// themselves until the day it matters, and by then it is too late.
class _VerificationNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'We do not send a confirmation email, so you can start straight '
              'away. That also means a mistyped address cannot be recovered — '
              'use one you really own.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.busy, required this.onSignOut});

  final bool busy;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: busy ? null : onSignOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 8),
        Text(
          'Signing out leaves your chart on this phone. It goes back to being '
          'backed up anonymously until you sign in again.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Accounts need a connection. Try again once you are online — nothing '
      'else in the app is waiting on it.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// The one case the app must not decide on the user's behalf: two different
/// birth profiles, one on the phone and one on the account.
class _ConflictDialog extends StatelessWidget {
  const _ConflictDialog({required this.remote});

  final BirthProfile remote;

  @override
  Widget build(BuildContext context) {
    final name = remote.name.isEmpty ? 'an unnamed profile' : remote.name;

    return AlertDialog(
      title: const Text('Two charts'),
      content: Text(
        'This account already holds $name, which is different from the chart '
        'on this phone. Only one can be kept.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep this phone’s'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Keep the account’s'),
        ),
      ],
    );
  }
}
