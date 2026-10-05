import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/data/profile_repository.dart';
import '../../../core/theme/brand_palette.dart';
import '../domain/launch_plan.dart';
import 'launch_scenes.dart';

/// Plays the launch scenes over the app, then gets out of the way (KAN-81).
///
/// An overlay above the router rather than a route of its own. The first real
/// screen builds underneath while the scenes play, so the fade at the end
/// reveals a finished screen instead of starting to build one — and the
/// router's redirect, which decides between Welcome and Home, stays the only
/// place that decision is made.
///
/// Bootstrap has already finished by the time this is on screen. The scenes
/// never hold up startup; they are shown over work that is done.
class LaunchOverlay extends ConsumerStatefulWidget {
  const LaunchOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LaunchOverlay> createState() => _LaunchOverlayState();
}

class _LaunchOverlayState extends ConsumerState<LaunchOverlay>
    with TickerProviderStateMixin {
  LaunchPlan? _plan;
  int _index = 0;
  AnimationController? _scene;

  /// Every scene's controller, kept until the overlay goes. The outgoing scene
  /// is still on screen during the cross-fade and must keep its last frame
  /// rather than reading the incoming scene's clock.
  final _controllers = <AnimationController>[];
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: LaunchPlan.exitFade,
  );
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decided once, on the first frame. A profile saved mid-sequence must not
    // turn a first launch into a returning one halfway through.
    if (_plan != null) return;
    _plan = LaunchPlan.forStart(
      hasProfile: ref.read(profileProvider) != null,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    _play(0);
  }

  void _play(int index) {
    final plan = _plan!;
    final controller = AnimationController(
      vsync: this,
      duration: plan.durationOf(plan.scenes[index]),
      // Reduced motion shows each scene's finished frame for its duration.
      value: plan.reduceMotion ? 1 : 0,
    );
    _controllers.add(controller);
    _scene = controller;
    _index = index;

    final finished = plan.reduceMotion
        ? Future<void>.delayed(controller.duration!)
        : controller.forward().orCancel.catchError((_) {});
    finished.then((_) {
      if (!mounted || _scene != controller) return;
      if (index + 1 < plan.scenes.length) {
        setState(() => _play(index + 1));
      } else {
        _exit.forward().whenComplete(() {
          if (mounted) setState(() => _done = true);
        });
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done || _scene == null) return widget.child;

    final scene = _plan!.scenes[_index];
    final clock = _scene!;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        FadeTransition(
          opacity: ReverseAnimation(_exit),
          // Nothing underneath can be tapped until the scenes are gone: a tap
          // landing on the hidden language list would choose for the user.
          child: AbsorbPointer(
            // Above the navigator, so nothing here has a Material yet. Without
            // one every Text falls back to the debug style — yellow underlines
            // and a monospace face, seen on the device and invisible in tests.
            child: Material(
              type: MaterialType.transparency,
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value:
                    scene == LaunchScene.heloCode ||
                        Theme.of(context).brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                // An opaque backing behind the cross-fade. Mid-fade both
                // scenes are half transparent, and without it the first screen
                // showed through between the publisher and the splash. Only
                // the exit fade may reveal the app.
                child: ColoredBox(
                  color: BrandPalette.of(context).background,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: AnimatedBuilder(
                      key: ValueKey(scene),
                      animation: clock,
                      builder: (context, _) => switch (scene) {
                        LaunchScene.heloCode => HeloCodePresents(
                          progress: clock.value,
                        ),
                        LaunchScene.splash => NakshatraSplash(
                          progress: clock.value,
                          brief: false,
                        ),
                        LaunchScene.splashBrief => NakshatraSplash(
                          progress: clock.value,
                          brief: true,
                        ),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
