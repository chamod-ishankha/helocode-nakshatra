import 'app_locale.dart';
import 'flavor.dart';

/// The `config/app` document the admin panel publishes (KAN-49), as the app
/// reads it.
///
/// ## It is a dial, never a dependency
///
/// The rule that governed Remote Config governs this: every value has a
/// compiled-in default equal to "nothing happens", and a phone that has never
/// reached Firestore runs on exactly those. [AppConfig.none] is that default.
/// Nothing in here can stop a screen from rendering — with one deliberate
/// exception, the version gate, which exists precisely to stop a build the
/// owner has judged harmful. See [VersionGate].
///
/// Parsing is forgiving by design: a field the app does not understand is
/// skipped, a malformed one falls back to its default, and only a document
/// that is not an object at all is rejected. A publish from a newer panel
/// must never break an older app.
class AppConfig {
  const AppConfig({
    required this.publishedAt,
    required this.versions,
    required this.announcement,
    required this.switches,
    required this.contentVersion,
  });

  /// What the app runs on with no config: no gate, no notice, all on.
  static const none = AppConfig(
    publishedAt: null,
    versions: {},
    announcement: null,
    switches: Switches.allOn,
    contentVersion: 0,
  );

  final DateTime? publishedAt;
  final Map<Flavor, VersionGate> versions;
  final Announcement? announcement;
  final Switches switches;

  /// The content bundle version the app should hold; 0 = bundled only.
  final int contentVersion;

  VersionGate gateFor(Flavor flavor) => versions[flavor] ?? VersionGate.none;

  static AppConfig fromJson(Map<String, dynamic> json) {
    final versions = <Flavor, VersionGate>{};
    final rawVersions = json['versions'];
    if (rawVersions is Map) {
      for (final flavor in Flavor.values) {
        final raw = rawVersions[flavor.name];
        if (raw is Map) {
          versions[flavor] = VersionGate.fromJson(
            Map<String, dynamic>.from(raw),
          );
        }
      }
    }
    final rawAnnouncement = json['announcement'];
    final rawSwitches = json['switches'];
    final rawContent = json['content'];
    return AppConfig(
      publishedAt: _date(json['publishedAt']),
      versions: versions,
      announcement: rawAnnouncement is Map
          ? Announcement.fromJson(Map<String, dynamic>.from(rawAnnouncement))
          : null,
      switches: rawSwitches is Map
          ? Switches.fromJson(Map<String, dynamic>.from(rawSwitches))
          : Switches.allOn,
      contentVersion: rawContent is Map ? _int(rawContent['latest']) : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'publishedAt': publishedAt?.toIso8601String(),
    'versions': {
      for (final e in versions.entries) e.key.name: e.value.toJson(),
    },
    'announcement': announcement?.toJson(),
    'switches': switches.toJson(),
    'content': {'latest': contentVersion},
  };
}

/// What a build below a threshold is told (KAN-49 §8.2).
class VersionGate {
  const VersionGate({
    required this.minimumBuild,
    required this.latestBuild,
    required this.storeUrl,
    required this.message,
  });

  static const none = VersionGate(
    minimumBuild: 0,
    latestBuild: 0,
    storeUrl: _playUrl,
    message: null,
  );

  static const _playUrl =
      'https://play.google.com/store/apps/details?id=io.helocode.nakshatra';

  /// Below this the app blocks. 0 means never.
  final int minimumBuild;

  /// Below this the app suggests an update, once. 0 means never.
  final int latestBuild;

  final String storeUrl;
  final Localised? message;

  /// What [build] should see.
  ///
  /// A build *equal* to the minimum passes: the minimum is the oldest build
  /// still allowed, not the first one refused. A gate of 0 never fires.
  GateVerdict verdictFor(int build) {
    if (minimumBuild > 0 && build < minimumBuild) return GateVerdict.blocked;
    if (latestBuild > 0 && build < latestBuild) {
      return GateVerdict.updateAvailable;
    }
    return GateVerdict.current;
  }

  static VersionGate fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    return VersionGate(
      minimumBuild: _int(json['minimumBuild']),
      latestBuild: _int(json['latestBuild']),
      storeUrl: _url(json['storeUrl']) ?? _playUrl,
      message: message is Map
          ? Localised.fromJson(Map<String, dynamic>.from(message))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'minimumBuild': minimumBuild,
    'latestBuild': latestBuild,
    'storeUrl': storeUrl,
    if (message != null) 'message': message!.toJson(),
  };
}

enum GateVerdict { current, updateAvailable, blocked }

/// A notice on Home, inside its window (KAN-49 §8.3).
class Announcement {
  const Announcement({
    required this.enabled,
    required this.id,
    required this.from,
    required this.until,
    required this.dismissible,
    required this.link,
    required this.title,
    required this.body,
  });

  final bool enabled;

  /// What a dismissal remembers. The panel changes it to show the notice
  /// again; editing the words alone does not.
  final String id;
  final DateTime from;
  final DateTime until;
  final bool dismissible;
  final Uri? link;
  final Localised title;
  final Localised body;

  /// Whether to show at [now], given the id last dismissed.
  ///
  /// The window is half-open: shown at [from], gone at [until]. A notice that
  /// cannot be dismissed ignores any dismissal that may have been recorded
  /// for the same id by an earlier, dismissible publish.
  bool isLiveAt(DateTime now, {String? dismissedId}) {
    if (!enabled) return false;
    if (now.isBefore(from) || !now.isBefore(until)) return false;
    if (dismissible && dismissedId == id) return false;
    return true;
  }

  static Announcement? fromJson(Map<String, dynamic> json) {
    final from = _date(json['from']);
    final until = _date(json['until']);
    final title = json['title'];
    final body = json['body'];
    final id = json['id'];
    // Without the pieces that decide whether it shows, there is no notice.
    if (from == null ||
        until == null ||
        title is! Map ||
        body is! Map ||
        id is! String ||
        id.isEmpty) {
      return null;
    }
    return Announcement(
      enabled: json['enabled'] == true,
      id: id,
      from: from,
      until: until,
      dismissible: json['dismissible'] != false,
      link: _url(json['link']) == null
          ? null
          : Uri.tryParse(_url(json['link'])!),
      title: Localised.fromJson(Map<String, dynamic>.from(title)),
      body: Localised.fromJson(Map<String, dynamic>.from(body)),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'id': id,
    'from': from.toIso8601String(),
    'until': until.toIso8601String(),
    'dismissible': dismissible,
    'link': link?.toString(),
    'title': title.toJson(),
    'body': body.toJson(),
  };
}

/// The things worth turning off in the field without a release (KAN-49 §8.4).
///
/// Each defaults to on, so a config that forgets one changes nothing. Off is
/// always the safer failure for the app's income and never for its readers:
/// a switch can take away an ad or a store button, never the almanac.
class Switches {
  const Switches({
    required this.adsEnabled,
    required this.purchasesEnabled,
    required this.googleSignInEnabled,
  });

  static const allOn = Switches(
    adsEnabled: true,
    purchasesEnabled: true,
    googleSignInEnabled: true,
  );

  final bool adsEnabled;
  final bool purchasesEnabled;
  final bool googleSignInEnabled;

  static Switches fromJson(Map<String, dynamic> json) => Switches(
    adsEnabled: json['adsEnabled'] != false,
    purchasesEnabled: json['purchasesEnabled'] != false,
    googleSignInEnabled: json['googleSignInEnabled'] != false,
  );

  Map<String, dynamic> toJson() => {
    'adsEnabled': adsEnabled,
    'purchasesEnabled': purchasesEnabled,
    'googleSignInEnabled': googleSignInEnabled,
  };
}

/// Copy in the three languages, read in the reader's own.
class Localised {
  const Localised({required this.en, required this.si, required this.ta});

  final String en;
  final String si;
  final String ta;

  /// The reader's language, or English when that one is blank: a half-filled
  /// notice is better shown in English than as an empty card.
  String of(AppLocale locale) {
    final own = switch (locale) {
      AppLocale.si => si,
      AppLocale.ta => ta,
      AppLocale.en => en,
    };
    return own.trim().isEmpty ? en : own;
  }

  static Localised fromJson(Map<String, dynamic> json) => Localised(
    en: _string(json['en']),
    si: _string(json['si']),
    ta: _string(json['ta']),
  );

  Map<String, dynamic> toJson() => {'en': en, 'si': si, 'ta': ta};
}

int _int(Object? v) => switch (v) {
  int n when n >= 0 => n,
  num n when n >= 0 => n.toInt(),
  _ => 0,
};

String _string(Object? v) => v is String ? v : '';

String? _url(Object? v) {
  if (v is! String || v.isEmpty) return null;
  final uri = Uri.tryParse(v);
  // Only web links: a config must not be able to open an arbitrary scheme.
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
    return null;
  }
  return v;
}

DateTime? _date(Object? v) {
  if (v is! String) return null;
  return DateTime.tryParse(v)?.toUtc();
}
