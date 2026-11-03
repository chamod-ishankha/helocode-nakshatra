import '../config/app_config.dart';
import '../whats_new/whats_new.dart';

/// What the admin panel publishes for readers to look back on: every notice,
/// and every release's notes (`feed/{version}`).
///
/// One document holding the lot, versioned like the content bundle, so a
/// phone reads it once per publish and keeps it. Parsing drops a notice or a
/// note it cannot show rather than refusing the whole feed: unlike the
/// horoscope copy, nothing here has to agree with anything else, and one bad
/// line should not hide every other.
class Feed {
  const Feed({
    required this.version,
    required this.notices,
    required this.releaseNotes,
  });

  final int version;

  /// Newest first.
  final List<Notice> notices;

  /// Newest build first.
  final List<ReleaseNote> releaseNotes;

  /// Throws [FormatException] only when the document is not a feed at all.
  factory Feed.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version is! int || version <= 0) {
      throw FormatException('Feed has no version: $version');
    }
    final rawNotices = json['notices'];
    final rawNotes = json['releaseNotes'];
    if (rawNotices is! List || rawNotes is! List) {
      throw const FormatException('Feed has no notices or release notes');
    }

    final notices =
        [
            for (final n in rawNotices)
              if (n is Map) Notice.fromJson(Map<String, dynamic>.from(n)),
          ].whereType<Notice>().toList()
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    final notes =
        [
            for (final n in rawNotes)
              if (n is Map) ReleaseNote.fromJson(Map<String, dynamic>.from(n)),
          ].whereType<ReleaseNote>().toList()
          ..sort((a, b) => b.build.compareTo(a.build));

    return Feed(version: version, notices: notices, releaseNotes: notes);
  }

  /// The banner Home shows at [now], or null: the newest notice whose window
  /// is open and which the reader has not dismissed.
  Announcement? bannerAt(DateTime now, {String? dismissedId}) {
    for (final notice in notices) {
      final banner = notice.asAnnouncement;
      if (banner != null && banner.isLiveAt(now, dismissedId: dismissedId)) {
        return banner;
      }
    }
    return null;
  }
}

/// Something the app has told its readers, kept so they can read it again.
class Notice {
  const Notice({
    required this.id,
    required this.publishedAt,
    required this.title,
    required this.body,
    this.link,
    this.banner,
  });

  final String id;
  final DateTime publishedAt;
  final Localised title;
  final Localised body;
  final Uri? link;

  /// While this window is open the notice is also a banner on Home, as the
  /// single announcement used to be.
  final ({DateTime from, DateTime until, bool dismissible})? banner;

  /// The banner as Home's announcement card draws it, or null.
  Announcement? get asAnnouncement => switch (banner) {
    null => null,
    final b => Announcement(
      enabled: true,
      id: id,
      from: b.from,
      until: b.until,
      dismissible: b.dismissible,
      link: link,
      title: title,
      body: body,
    ),
  };

  static Notice? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final publishedAt = configDate(json['publishedAt']);
    final title = json['title'];
    final body = json['body'];
    if (id is! String ||
        id.isEmpty ||
        publishedAt == null ||
        title is! Map ||
        body is! Map) {
      return null;
    }
    final t = Localised.fromJson(Map<String, dynamic>.from(title));
    final b = Localised.fromJson(Map<String, dynamic>.from(body));
    // English is what every language falls back to; without it there is
    // nothing to show.
    if (t.en.trim().isEmpty || b.en.trim().isEmpty) return null;

    final rawBanner = json['banner'];
    ({DateTime from, DateTime until, bool dismissible})? banner;
    if (rawBanner is Map) {
      final from = configDate(rawBanner['from']);
      final until = configDate(rawBanner['until']);
      // A window that cannot open is no banner; the notice itself stands.
      if (from != null && until != null && until.isAfter(from)) {
        banner = (
          from: from,
          until: until,
          dismissible: rawBanner['dismissible'] != false,
        );
      }
    }
    return Notice(
      id: id,
      publishedAt: publishedAt,
      title: t,
      body: b,
      link: configLink(json['link']),
      banner: banner,
    );
  }
}
