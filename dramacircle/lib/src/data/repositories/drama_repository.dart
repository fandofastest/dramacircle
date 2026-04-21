import 'package:dio/dio.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';

class DramaRepository {
  DramaRepository(this._dio);
  final Dio _dio;
  int _forYouPageCursor = 1;
  final Map<String, String> _streamCache = <String, String>{};
  final Map<String, Map<String, dynamic>> _detailCache = <String, Map<String, dynamic>>{};
  final Map<String, List<EpisodeItem>> _episodesCache = <String, List<EpisodeItem>>{};
  final Map<String, EpisodeEngagement> _engagementCache = <String, EpisodeEngagement>{};
  final Map<String, Future<Map<String, dynamic>>> _detailInFlight = <String, Future<Map<String, dynamic>>>{};
  final Map<String, Future<List<EpisodeItem>>> _episodesInFlight = <String, Future<List<EpisodeItem>>>{};

  Future<List<DramaItem>> trending() async {
    final response = await _dio.get('/drama/trending');
    final list = (response.data['data'] as List<dynamic>? ?? <dynamic>[]);
    return list.map((e) => DramaItem.fromJson((e ?? <String, dynamic>{}) as Map<String, dynamic>)).toList();
  }

  Future<List<DramaItem>> latest() async {
    final response = await _dio.get('/drama/latest');
    final list = (response.data['data'] as List<dynamic>? ?? <dynamic>[]);
    return list.map((e) => DramaItem.fromJson((e ?? <String, dynamic>{}) as Map<String, dynamic>)).toList();
  }

  Future<List<DramaItem>> forYou({int page = 1}) async {
    final response = await _dio.get('/drama/foryou', queryParameters: {'page': page});
    final payload = (response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final list = (payload['items'] as List<dynamic>? ?? <dynamic>[]);
    return list.map((e) => DramaItem.fromJson((e ?? <String, dynamic>{}) as Map<String, dynamic>)).toList();
  }

  Future<List<DramaItem>> dubindo({String classify = 'terpopuler'}) async {
    final response = await _dio.get('/drama/dubindo', queryParameters: {'classify': classify});
    final payload = (response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final list = (payload['items'] as List<dynamic>? ?? <dynamic>[]);
    return list.map((e) => DramaItem.fromJson((e ?? <String, dynamic>{}) as Map<String, dynamic>)).toList();
  }

  Future<List<DramaItem>> search(String query) async {
    final response = await _dio.get('/drama/search', queryParameters: {'query': query});
    final payload = (response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final list = (payload['results'] as List<dynamic>? ?? <dynamic>[]);
    return list.map((e) => DramaItem.fromJson((e ?? <String, dynamic>{}) as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> detail(String bookId) async {
    final cached = _detailCache[bookId];
    if (cached != null) {
      return cached;
    }
    final inFlight = _detailInFlight[bookId];
    if (inFlight != null) {
      return inFlight;
    }

    final task = () async {
      final response = await _dio.get('/drama/detail/$bookId');
      final payload = (response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      _detailCache[bookId] = payload;
      return payload;
    }();
    _detailInFlight[bookId] = task;
    try {
      return await task;
    } finally {
      _detailInFlight.remove(bookId);
    }
  }

  Future<List<EpisodeItem>> episodes(String bookId) async {
    final cached = _episodesCache[bookId];
    if (cached != null) {
      return cached;
    }
    final inFlight = _episodesInFlight[bookId];
    if (inFlight != null) {
      return inFlight;
    }

    final task = () async {
      final response = await _dio.get('/drama/allepisode/$bookId');
      final payload = (response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final list = (payload['items'] as List<dynamic>? ?? <dynamic>[]);
      final mapped = list
          .map((item) {
            final map = (item ?? <String, dynamic>{}) as Map<String, dynamic>;
            final chapterIndexRaw = map['chapterIndex'] ?? map['episodeNumber'] ?? 1;
            final chapterIndex =
                (chapterIndexRaw is num) ? chapterIndexRaw.toInt() : int.tryParse(chapterIndexRaw.toString()) ?? 1;
            return EpisodeItem(
              episodeId: (map['chapterId'] ?? map['episodeId'] ?? chapterIndex).toString(),
              bookId: (map['bookId'] ?? bookId).toString(),
              episodeNumber: chapterIndex,
              videoUrl: (map['videoUrl'] ?? map['encryptedUrl'] ?? '').toString(),
              isPremium: (map['isCharge'] == true || map['isPremium'] == true || map['vip'] == true || map['isVip'] == true),
              title: '',
              description: '',
            );
          })
          .toList();
      _episodesCache[bookId] = mapped;
      return mapped;
    }();
    _episodesInFlight[bookId] = task;
    try {
      return await task;
    } finally {
      _episodesInFlight.remove(bookId);
    }
  }

  Future<String> decryptStream(String encryptedUrl) async {
    final cached = _streamCache[encryptedUrl];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (encryptedUrl.startsWith('http')) {
      if (!encryptedUrl.contains('.encrypt.')) {
        _streamCache[encryptedUrl] = encryptedUrl;
        return encryptedUrl;
      }
    }

    final candidate = await _decryptWithRetry(encryptedUrl);
    final resolved = candidate ?? (encryptedUrl.contains('.encrypt.') ? '' : encryptedUrl);
    _streamCache[encryptedUrl] = resolved;
    return resolved;
  }

  Future<String?> _decryptWithRetry(String encryptedUrl) async {
    const delays = <Duration>[
      Duration(milliseconds: 350),
      Duration(milliseconds: 900),
      Duration(milliseconds: 1600),
    ];

    for (var i = 0; i < delays.length; i++) {
      try {
        final response = await _dio.get('/drama/stream', queryParameters: {'url': encryptedUrl});
        final candidate = _pickStreamUrl(response.data);
        if (candidate != null && candidate.isNotEmpty) {
          return candidate;
        }
        return null;
      } on DioException catch (error) {
        final code = error.response?.statusCode;
        if (code == 429 && i < delays.length - 1) {
          await Future<void>.delayed(delays[i]);
          continue;
        }
        return null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String? _pickStreamUrl(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is String && data.startsWith('http')) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final direct = data['streamUrl'] ?? data['url'] ?? data['videoUrl'];
      if (direct is String && direct.startsWith('http')) {
        return direct;
      }
      final nestedData = data['data'];
      final nestedResult = _pickStreamUrl(nestedData);
      if (nestedResult != null) {
        return nestedResult;
      }
      final nestedPayload = data['payload'];
      return _pickStreamUrl(nestedPayload);
    }
    if (data is List) {
      for (final item in data) {
        final candidate = _pickStreamUrl(item);
        if (candidate != null) {
          return candidate;
        }
      }
    }
    return null;
  }

  Future<List<EpisodeItem>> randomDrama() async {
    const targetMinItems = 6;
    final resolved = <EpisodeItem>[];
    final seenEpisodeKeys = <String>{};
    final triedBookIds = <String>{};

    Future<void> appendFromDramaList(List<DramaItem> dramas) async {
      for (final drama in dramas) {
        if (resolved.length >= targetMinItems) {
          return;
        }
        if (drama.bookId.isEmpty || triedBookIds.contains(drama.bookId)) {
          continue;
        }
        triedBookIds.add(drama.bookId);
        List<EpisodeItem> eps = <EpisodeItem>[];
        try {
          eps = await episodesByBook(
            drama.bookId,
            fallbackTitle: drama.title,
            fallbackDescription: drama.description ?? '',
          );
        } catch (_) {
          continue;
        }
        if (eps.isEmpty) {
          continue;
        }
        final firstPlayable = eps.firstWhere((episode) => episode.videoUrl.isNotEmpty, orElse: () => eps.first);
        if (firstPlayable.videoUrl.isEmpty) {
          continue;
        }
        final key = firstPlayable.episodeId.isNotEmpty
            ? firstPlayable.episodeId
            : '${firstPlayable.bookId}-${firstPlayable.episodeNumber}';
        if (key.isEmpty || seenEpisodeKeys.contains(key)) {
          continue;
        }
        var stream = firstPlayable.videoUrl;
        if (stream.contains('.encrypt.')) {
          try {
            stream = await decryptStream(stream);
          } catch (_) {
            continue;
          }
        }
        if (stream.isEmpty) {
          continue;
        }
        seenEpisodeKeys.add(key);
        resolved.add(firstPlayable.copyWith(videoUrl: stream));
      }
    }

    for (var i = 0; i < 4 && resolved.length < targetMinItems; i++) {
      List<DramaItem> forYouPage = <DramaItem>[];
      try {
        forYouPage = await _fetchForYouPage(_forYouPageCursor);
      } catch (_) {
        forYouPage = <DramaItem>[];
      }
      _forYouPageCursor += 1;
      if (_forYouPageCursor > 50) {
        _forYouPageCursor = 1;
      }
      if (forYouPage.isEmpty) {
        break;
      }
      await appendFromDramaList(forYouPage);
    }

    if (resolved.length < targetMinItems) {
      try {
        final fallbackDramas = await latest();
        await appendFromDramaList(fallbackDramas);
      } catch (_) {}
    }

    return resolved;
  }

  Future<List<DramaItem>> _fetchForYouPage(int page) async {
    final response = await _dio.get('/drama/foryou', queryParameters: {'page': page});
    final payload = (response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final list = (payload['items'] as List<dynamic>? ?? <dynamic>[]);
    return list.map((e) => DramaItem.fromJson((e ?? <String, dynamic>{}) as Map<String, dynamic>)).toList();
  }

  Future<List<EpisodeItem>> episodesByBook(
    String bookId, {
    required String fallbackTitle,
    required String fallbackDescription,
  }) async {
    final eps = await episodes(bookId);
    final mapped = <EpisodeItem>[];
    for (final episode in eps) {
      mapped.add(
        EpisodeItem(
          episodeId: episode.episodeId,
          bookId: episode.bookId,
          episodeNumber: episode.episodeNumber,
          videoUrl: episode.videoUrl,
          isPremium: episode.isPremium,
          title: fallbackTitle,
          description: fallbackDescription,
          cover: null,
        ),
      );
    }
    return mapped;
  }

  String _engagementKey(String bookId, String episodeId) => '$bookId::$episodeId';

  Future<EpisodeEngagement> getEngagement({
    required String bookId,
    required String episodeId,
    bool forceRefresh = false,
  }) async {
    final key = _engagementKey(bookId, episodeId);
    if (!forceRefresh) {
      final cached = _engagementCache[key];
      if (cached != null) {
        return cached;
      }
    }
    final response = await _dio.get('/drama/engagement/$bookId/$episodeId');
    final data = (response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final mapped = EpisodeEngagement.fromJson(data);
    _engagementCache[key] = mapped;
    return mapped;
  }

  Future<EpisodeEngagement> toggleLike({
    required String bookId,
    required String episodeId,
  }) async {
    await _dio.post('/drama/engagement/$bookId/$episodeId/like');
    return getEngagement(bookId: bookId, episodeId: episodeId, forceRefresh: true);
  }

  Future<EpisodeEngagement> addComment({
    required String bookId,
    required String episodeId,
    required String content,
  }) async {
    await _dio.post('/drama/engagement/$bookId/$episodeId/comment', data: {'content': content});
    return getEngagement(bookId: bookId, episodeId: episodeId, forceRefresh: true);
  }

  Future<void> trackPlay({
    required String bookId,
    required String episodeId,
  }) async {
    await _dio.post('/drama/engagement/$bookId/$episodeId/play');
    final key = _engagementKey(bookId, episodeId);
    final cached = _engagementCache[key];
    if (cached != null) {
      _engagementCache[key] = EpisodeEngagement(
        likeCount: cached.likeCount,
        commentCount: cached.commentCount,
        playCount: cached.playCount + 1,
        likedByMe: cached.likedByMe,
        comments: cached.comments,
      );
    }
  }

  Future<CommentPage> getCommentsPage({
    required String bookId,
    required String episodeId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/drama/engagement/$bookId/$episodeId/comments',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = (response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    return CommentPage.fromJson(data);
  }
}
