import 'package:dio/dio.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';

class DramaRepository {
  DramaRepository(this._dio);
  final Dio _dio;
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
      final response = await _dio.get('/drama/episodes/$bookId');
      final payload = (response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final list = (payload['episodes'] as List<dynamic>? ?? <dynamic>[]);
      final mapped = list
          .map((item) {
            final map = (item ?? <String, dynamic>{}) as Map<String, dynamic>;
            return EpisodeItem(
              episodeId: (map['episodeNumber'] ?? '').toString(),
              bookId: (map['bookId'] ?? bookId).toString(),
              episodeNumber: (map['episodeNumber'] is num) ? (map['episodeNumber'] as num).toInt() : 1,
              videoUrl: (map['encryptedUrl'] ?? map['videoUrl'] ?? '').toString(),
              isPremium: (map['isPremium'] == true || map['vip'] == true || map['isVip'] == true),
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
    final response = await _dio.get('/drama/randomdrama');
    final raw = response.data['data'];
    final list = _extractRandomList(raw);
    final episodes = list
        .map((item) => EpisodeItem.fromRandomJson((item ?? <String, dynamic>{}) as Map<String, dynamic>))
        .where((item) => item.episodeId.isNotEmpty || item.bookId.isNotEmpty)
        .toList();

    final resolved = <EpisodeItem>[];
    for (final item in episodes) {
      var candidate = item;
      if (candidate.videoUrl.isEmpty && candidate.bookId.isNotEmpty) {
        final eps = await episodesByBook(candidate.bookId, fallbackTitle: candidate.title, fallbackDescription: candidate.description);
        if (eps.isNotEmpty) {
          candidate = eps.first;
        }
      }
      if (candidate.videoUrl.isEmpty) {
        continue;
      }
      final stream = await decryptStream(candidate.videoUrl);
      resolved.add(candidate.copyWith(videoUrl: stream));
    }
    if (resolved.isNotEmpty) {
      return resolved;
    }

    final fallbackDramas = await latest();
    final fallback = <EpisodeItem>[];
    for (final drama in fallbackDramas.take(8)) {
      final eps = await episodesByBook(drama.bookId, fallbackTitle: drama.title, fallbackDescription: drama.description ?? '');
      if (eps.isEmpty) {
        continue;
      }
      final first = eps.first;
      final stream = await decryptStream(first.videoUrl);
      fallback.add(first.copyWith(videoUrl: stream));
    }
    return fallback;
  }

  List<dynamic> _extractRandomList(dynamic raw) {
    if (raw is List) {
      return raw;
    }
    if (raw is Map<String, dynamic>) {
      final direct = raw['items'] ?? raw['results'] ?? raw['episodes'] ?? raw['data'];
      if (direct is List) {
        return direct;
      }
    }
    return <dynamic>[];
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
          isPremium: episode.isPremium || episode.episodeNumber > 3,
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
