/// The three languages the app ships in.
///
/// Kept as a plain enum rather than relying on [Locale] so the rest of the app
/// can switch exhaustively and the compiler catches a missed translation.
enum AppLocale {
  si('si', 'සිංහල', 'Sinhala'),
  ta('ta', 'தமிழ்', 'Tamil'),
  en('en', 'English', 'English');

  const AppLocale(this.code, this.nativeName, this.englishName);

  final String code;

  /// The language's own name, which is what a language picker must show — a
  /// Tamil speaker looks for "தமிழ்", not "Tamil".
  final String nativeName;

  final String englishName;

  static AppLocale fromCode(String? code) => AppLocale.values.firstWhere(
    (l) => l.code == code,
    orElse: () => AppLocale.en,
  );
}
