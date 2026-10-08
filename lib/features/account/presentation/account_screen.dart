import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/router/app_router.dart';
import '../../../core/sync/auth_service.dart';
import '../../../core/sync/profile_sync.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/brand_button.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/brand_field.dart';
import '../../../core/ui/info_notice.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/domain/birth_profile.dart';
import 'auth_messages.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/config/app_config_service.dart';

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

  /// The last failure was the network, not the account.
  bool _offline = false;

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
      _offline = false;
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
        final l = L10n.of(context);
        _confirm(_signingIn ? l.accountSignedInToast : l.accountCreatedToast);
      case FailureResult(:final failure):
        final taken =
            failure is AuthFailure && AuthService.isEmailTaken(failure.code);
        final text = failure is AuthFailure
            ? authMessage(context, failure)
            : L10n.of(context).authErrorGeneric;
        setState(() {
          _busy = false;
          _error = text;
          _offline = isNoConnection(failure);
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
      _offline = false;
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

    final f = result.failureOrNull;
    // Backing out of the Google sheet is not an error. Showing one would
    // accuse the user of a mistake they did not make.
    // Only a first cancellation is silent. A repeat is reported, because on
    // Android a rejected signing certificate arrives as a cancellation too.
    final text = (f is! AuthFailure || f.code == 'google-canceled')
        ? null
        : authMessage(context, f);

    setState(() {
      _busy = false;
      _error = text;
      _offline = isNoConnection(f);
    });

    if (result.isSuccess) _confirm(L10n.of(context).accountSignedInGoogleToast);
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
    final f = result.failureOrNull;
    final text = f is AuthFailure ? authMessage(context, f) : null;
    setState(() {
      _busy = false;
      _error = text;
      _offline = isNoConnection(f);
    });
    if (result.isSuccess) _confirm(L10n.of(context).accountSignedOutToast);
  }

  void _confirm(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final l = L10n.of(context);
    final status = ref.watch(accountStatusProvider).value;
    final kind = status?.kind ?? AccountKind.none;

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backdrop),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => popOrHome(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.accountTitle,
                      style: BrandFonts.displayStyle(
                        context,
                        size: 26,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _StatusCard(kind: kind, email: status?.email),
              const SizedBox(height: AppSpacing.lg),
              if (kind == AccountKind.permanent)
                _SignedIn(busy: _busy, onSignOut: _signOut)
              else if (kind == AccountKind.none)
                const _Unavailable()
              else ...[
                if (AuthService.googleAvailable &&
                    ref.watch(switchesProvider).googleSignInEnabled) ...[
                  BrandButton(
                    tone: BrandButtonTone.outline,
                    expand: true,
                    onPressed: _busy ? null : _google,
                    leading: const Icon(Icons.account_circle_outlined),
                    label: l.accountContinueWithGoogle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(child: Divider(color: palette.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l.accountOr,
                          style: TextStyle(fontSize: 13, color: palette.muted),
                        ),
                      ),
                      Expanded(child: Divider(color: palette.line)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _Form(
                  formKey: _formKey,
                  email: _email,
                  password: _password,
                  signingIn: _signingIn,
                  busy: _busy,
                  error: _error,
                  offline: _offline,
                  onSubmit: _submit,
                  onToggleMode: () => setState(() {
                    _signingIn = !_signingIn;
                    _error = null;
                    _offline = false;
                  }),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                l.accountFooter,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.entertainmentOnly,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
        ),
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
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final l = L10n.of(context);

    // The icon and the words say the state; the tile colour only supports
    // them.
    final (
      IconData icon,
      String title,
      String body,
      Color colour,
      Color wash,
    ) = switch (kind) {
      AccountKind.permanent => (
        Icons.verified_user_outlined,
        l.accountSavedToEmail(email ?? ''),
        l.accountSavedToEmailHelp,
        semantic.auspicious,
        semantic.auspiciousSurface,
      ),
      AccountKind.anonymous => (
        Icons.phonelink_lock_outlined,
        l.accountPhoneOnly,
        l.accountPhoneOnlyHelp,
        semantic.inauspicious,
        semantic.inauspiciousSurface,
      ),
      AccountKind.none => (
        Icons.cloud_off_outlined,
        l.accountUnavailable,
        l.accountUnavailableHelp,
        palette.muted,
        palette.surfaceHigh,
      ),
    };

    return BrandCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: wash,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colour),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: palette.muted,
                  ),
                ),
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
    required this.offline,
    required this.onSubmit,
    required this.onToggleMode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool signingIn;
  final bool busy;
  final String? error;
  final bool offline;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final l = L10n.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            signingIn ? l.accountSignIn : l.accountKeepSafe,
            style: BrandFonts.displayStyle(
              context,
              size: 20,
              color: palette.text,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: palette.text),
            decoration: brandFieldDecoration(context, label: l.accountEmail),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return l.accountEnterEmail;
              // Deliberately loose. Anything stricter rejects addresses that
              // are perfectly valid, and Firebase checks it properly anyway.
              if (!value.contains('@') || !value.contains('.')) {
                return l.accountInvalidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: password,
            enabled: !busy,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            style: TextStyle(color: palette.text),
            decoration: brandFieldDecoration(context, label: l.accountPassword),
            validator: (v) {
              if ((v ?? '').isEmpty) return l.accountEnterPassword;
              // Firebase's own minimum. Checking it here turns a round trip
              // and a raw error code into an instant, readable one.
              if (!signingIn && v!.length < 6) {
                return l.accountPasswordTooShort;
              }
              return null;
            },
          ),
          if (!signingIn) ...[
            const SizedBox(height: AppSpacing.md),
            _VerificationNotice(),
          ],
          if (offline) ...[
            const SizedBox(height: AppSpacing.md),
            const OfflineNotice(),
          ] else if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoNotice(text: error!, tone: NoticeTone.caution),
          ],
          const SizedBox(height: 20),
          BrandButton(
            expand: true,
            onPressed: busy ? null : onSubmit,
            leading: busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            label: signingIn ? l.accountSignIn : l.accountCreate,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: busy ? null : onToggleMode,
            child: Text(
              signingIn ? l.accountToggleToCreate : l.accountToggleToSignIn,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.semantic.accent),
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
  Widget build(BuildContext context) => InfoNotice(
    text: L10n.of(context).accountNoVerification,
    icon: Icons.info_outline,
  );
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
        BrandButton(
          tone: BrandButtonTone.outline,
          expand: true,
          onPressed: busy ? null : onSignOut,
          leading: const Icon(Icons.logout_rounded),
          label: L10n.of(context).accountSignOut,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          L10n.of(context).accountSignedOutHelp,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: BrandPalette.of(context).muted,
          ),
        ),
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      child: Text(
        L10n.of(context).accountOfflineNotice,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: BrandPalette.of(context).text,
        ),
      ),
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
    final l = L10n.of(context);
    final name = remote.name.isEmpty ? l.accountConflictUnnamed : remote.name;

    return AlertDialog(
      backgroundColor: BrandPalette.of(context).background,
      title: Text(l.accountConflictTitle),
      content: Text(l.accountConflictBody(name)),
      // Stacked full-width rather than two buttons in a row: both choices are
      // sentences, and in Tamil they did not fit side by side.
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrandButton(
              tone: BrandButtonTone.outline,
              expand: true,
              onPressed: () => Navigator.of(context).pop(false),
              label: l.accountConflictKeepPhone,
            ),
            const SizedBox(height: AppSpacing.sm),
            BrandButton(
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
              label: l.accountConflictKeepAccount,
            ),
          ],
        ),
      ],
    );
  }
}
