import 'package:flutter/material.dart';

/// Transition duration for routes that carry a [Hero].
///
/// ⚠️ A [Hero] has no duration of its own. Its flight runs for exactly as long
/// as the *destination route's* transition — `Hero` takes a `curve`, not a
/// `Duration`. go_router's `builder:` wraps a route in the platform default
/// page, whose transition is 300ms, and at that speed the client-avatar flight
/// is over before the eye registers it. Routes with a Hero use [HeroPage]
/// instead, which is the same Material page on a slower clock.
///
/// 400ms is a deliberate ceiling. Past ~500ms the whole app starts to feel
/// sluggish for someone tapping through twenty clients in a row — the
/// animation is for orientation, not for show.
const Duration kHeroRouteDuration = Duration(milliseconds: 400);

/// A Material page with a configurable transition duration.
///
/// Why not go_router's `CustomTransitionPage`: it builds a bare [PageRoute]
/// around whatever `transitionsBuilder` you hand it, which means giving up
/// two things that come for free with [MaterialRouteTransitionMixin] —
///
///   1. the platform transition (Zoom on Android, Cupertino slide on iOS), and
///   2. the iOS edge-swipe-to-pop gesture, which lives in the Cupertino
///      page transition and simply isn't there on a hand-rolled route.
///
/// Mixing the Material route behaviour in and overriding *only* the duration
/// keeps both. This is the same shape as Flutter's own internal
/// `_PageBasedMaterialPageRoute`, which is what [MaterialPage] builds.
class HeroPage<T> extends Page<T> {
  const HeroPage({
    required this.child,
    this.duration = kHeroRouteDuration,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  /// Forward *and* reverse duration. Kept symmetric on purpose: an avatar that
  /// flies out in 400ms and snaps back in 200ms reads as a glitch.
  final Duration duration;

  @override
  Route<T> createRoute(BuildContext context) => _HeroPageRoute<T>(page: this);
}

class _HeroPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _HeroPageRoute({required HeroPage<T> page}) : super(settings: page);

  HeroPage<T> get _page => settings as HeroPage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _page.duration;

  @override
  Duration get reverseTransitionDuration => _page.duration;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}
