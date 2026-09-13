import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/analytics_service.dart';
import 'rewarded_unlock.dart';

/// What gets recorded about rewarded ads (KAN-70).
///
/// ## Why this exists before any change to the rewards
///
/// Every rewarded unlock resets at the user's own midnight, so a patient user
/// gets the navāṁśa and the full daśā free every day — two of the four things
/// Play is told Pro sells. Tightening that is the obvious fix, and it is a bet:
/// it moves money from AdMob to Pro only if enough of the people watching ads
/// would pay instead, and the ones who would not simply stop watching.
///
/// Nobody knows which way that goes, because nothing measured it. These events
/// are the measurement. With Firebase's own daily-active-user count they give
/// the one number the decision turns on: what share of users watch, for which
/// unlock, and how often the ad they asked for actually pays out.
///
/// ## What is recorded
///
/// The unlock's name and where it was offered. Never the user, the chart, the
/// birth details, or anything else about them — the same rule as the purchase
/// events, which record a product id and nothing more.
abstract final class RewardedEvent {
  /// A watch button was on screen and usable.
  static const offered = 'rewarded_offered';

  /// The ad paid out and the unlock opened.
  static const earned = 'rewarded_earned';

  /// Tapped, but no reward: no fill, or dismissed before the end. The SDK does
  /// not say which, so neither does this.
  static const notEarned = 'rewarded_not_earned';

  /// The chart screen's full-screen rewarded ad, whatever became of it.
  static const interstitial = 'rewarded_interstitial';
}

/// Where a watch button was offered.
enum RewardedSurface {
  /// The blurred lock over content that is also sold under Pro.
  lock,

  /// The inline card for an unlock that only an ad opens.
  card,
}

typedef RewardedLog = void Function(String name, Map<String, Object> params);

/// Sends a rewarded-ad event. Overridden in tests to capture instead.
///
/// Fire and forget: analytics is something we would like to know, never
/// something an unlock waits on.
final rewardedLogProvider = Provider<RewardedLog>(
  (ref) =>
      (name, params) => unawaited(AnalyticsService.log(name, params)),
);

/// Does nothing. The default where no logger is supplied.
void noRewardedLog(String name, Map<String, Object> params) {}

/// The parameters every rewarded event carries.
Map<String, Object> rewardedParams(
  RewardedUnlock unlock, [
  RewardedSurface? surface,
]) => {'unlock': unlock.name, 'surface': ?surface?.name};
