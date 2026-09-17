part of '../../jellyfin_client.dart';

mixin _JellyfinSubtitleMethods on _JellyfinClientInternals {
  /// Jellyfin takes a three-letter code in the path while the picker holds a
  /// two-letter one. Either 639-2 form is accepted (`deu` and `ger` return the
  /// same results), so the /T form the table yields is fine, and an unmappable
  /// code is passed through rather than dropped.
  String _remoteSubtitleLanguage(String language) =>
      LanguageCodes.getIso6392Code(language) ?? language.toLowerCase().trim();

  @override
  Future<List<SubtitleSearchResult>> searchSubtitles(
    String itemId, {
    required String language,
    String? title,
  }) async {
    final response = await _http.get(
      '/Items/${_segment(itemId)}/RemoteSearch/Subtitles/${_segment(_remoteSubtitleLanguage(language))}',
    );
    throwIfHttpError(response);

    final data = response.data;
    if (data is! List) return const [];

    return [
      for (final entry in data)
        if (entry is Map<String, dynamic>) _mapRemoteSubtitle(entry),
    ];
  }

  /// [language] is unused: the provider id in [SubtitleSearchResult.key] already
  /// names the exact file to fetch.
  @override
  Future<bool> downloadSubtitle(String itemId, SubtitleSearchResult result, {String? language}) async {
    final response = await _http.post(
      '/Items/${_segment(itemId)}/RemoteSearch/Subtitles/${_segment(result.key)}',
    );
    throwIfHttpError(response);
    return true;
  }

  SubtitleSearchResult _mapRemoteSubtitle(Map<String, dynamic> entry) {
    final provider = entry['ProviderName'] as String?;
    final author = entry['Author'] as String?;
    final downloads = flexibleInt(entry['DownloadCount']);

    // Jellyfin has no single display line, so build one from what tells two
    // results from the same release apart.
    final details = <String>[
      ?provider,
      ?(author != null && author.isNotEmpty ? author : null),
      ?(downloads != null && downloads > 0 ? '$downloads' : null),
    ];

    return SubtitleSearchResult(
      key: entry['Id'] as String? ?? '',
      title: entry['Name'] as String?,
      displayTitle: details.isEmpty ? null : details.join(' - '),
      codec: entry['Format'] as String?,
      languageCode: entry['ThreeLetterISOLanguageName'] as String?,
      score: flexibleDouble(entry['CommunityRating']),
      providerTitle: provider,
      hearingImpaired: flexibleBool(entry['HearingImpaired']),
      forced: flexibleBool(entry['Forced']),
      perfectMatch: flexibleBool(entry['IsHashMatch']),
    );
  }
}
