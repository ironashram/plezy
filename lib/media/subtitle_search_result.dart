/// One subtitle offered by a provider the media server queries on our behalf
/// (OpenSubtitles and friends), shaped the same whichever backend searched.
///
/// [key] is opaque and backend-specific: it is handed straight back to
/// [MediaServerClient.downloadSubtitle] rather than parsed here.
class SubtitleSearchResult {
  const SubtitleSearchResult({
    required this.key,
    this.title,
    this.displayTitle,
    this.codec,
    this.languageCode,
    this.score,
    this.providerTitle,
    this.hearingImpaired = false,
    this.forced = false,
    this.perfectMatch = false,
  });

  final String key;

  /// Primary line, usually the release the subtitle was timed against.
  final String? title;

  /// Secondary line: whatever the backend offers to tell two results apart.
  final String? displayTitle;

  final String? codec;
  final String? languageCode;
  final double? score;
  final String? providerTitle;
  final bool hearingImpaired;
  final bool forced;

  /// The provider matched the file itself rather than its title, so the timing
  /// is very likely correct.
  final bool perfectMatch;
}
