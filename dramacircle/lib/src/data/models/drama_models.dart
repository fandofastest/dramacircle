class DramaItem {
  DramaItem({
    required this.bookId,
    required this.title,
    required this.cover,
    required this.description,
    required this.totalEpisodes,
  });

  final String bookId;
  final String title;
  final String? cover;
  final String? description;
  final int? totalEpisodes;

  factory DramaItem.fromJson(Map<String, dynamic> json) {
    return DramaItem(
      bookId: (json['bookId'] ?? '').toString(),
      title: (json['title'] ?? json['bookName'] ?? '').toString(),
      cover: json['cover']?.toString(),
      description: json['description']?.toString(),
      totalEpisodes: json['totalEpisodes'] is num ? (json['totalEpisodes'] as num).toInt() : null,
    );
  }
}

class EpisodeItem {
  EpisodeItem({
    required this.episodeId,
    required this.bookId,
    required this.episodeNumber,
    required this.videoUrl,
    required this.isPremium,
    required this.title,
    required this.description,
    this.cover,
  });

  final String episodeId;
  final String bookId;
  final int episodeNumber;
  final String videoUrl;
  final bool isPremium;
  final String title;
  final String description;
  final String? cover;

  factory EpisodeItem.fromRandomJson(Map<String, dynamic> json) {
    final premiumRaw = json['isPremium'] ?? json['vip'] ?? json['isVip'] ?? false;
    return EpisodeItem(
      episodeId: (json['episodeId'] ?? json['id'] ?? json['episodeNumber'] ?? '').toString(),
      bookId: (json['bookId'] ?? json['dramaId'] ?? '').toString(),
      episodeNumber: (json['episodeNumber'] is num) ? (json['episodeNumber'] as num).toInt() : 1,
      videoUrl: (json['videoUrl'] ?? json['streamUrl'] ?? json['url'] ?? '').toString(),
      isPremium: premiumRaw == true || premiumRaw == 1 || premiumRaw == 'true',
      title: (json['title'] ?? json['dramaTitle'] ?? 'Untitled Drama').toString(),
      description: (json['description'] ?? '').toString(),
      cover: json['cover']?.toString(),
    );
  }

  EpisodeItem copyWith({
    String? videoUrl,
    bool? isPremium,
  }) {
    return EpisodeItem(
      episodeId: episodeId,
      bookId: bookId,
      episodeNumber: episodeNumber,
      videoUrl: videoUrl ?? this.videoUrl,
      isPremium: isPremium ?? this.isPremium,
      title: title,
      description: description,
      cover: cover,
    );
  }
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.isPremium,
  });

  final String id;
  final String name;
  final String email;
  final bool isPremium;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      isPremium: json['isVip'] == true || json['isPremium'] == true,
    );
  }
}

class EpisodeComment {
  EpisodeComment({
    required this.memberId,
    required this.memberName,
    required this.content,
    required this.createdAt,
  });

  final String memberId;
  final String memberName;
  final String content;
  final DateTime createdAt;

  factory EpisodeComment.fromJson(Map<String, dynamic> json) {
    return EpisodeComment(
      memberId: (json['memberId'] ?? '').toString(),
      memberName: (json['memberName'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class EpisodeEngagement {
  EpisodeEngagement({
    required this.likeCount,
    required this.commentCount,
    required this.playCount,
    required this.likedByMe,
    required this.comments,
  });

  final int likeCount;
  final int commentCount;
  final int playCount;
  final bool likedByMe;
  final List<EpisodeComment> comments;

  factory EpisodeEngagement.fromJson(Map<String, dynamic> json) {
    final commentsRaw = (json['comments'] as List<dynamic>? ?? <dynamic>[]);
    return EpisodeEngagement(
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? commentsRaw.length,
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] == true,
      comments: commentsRaw
          .map((item) => EpisodeComment.fromJson((item ?? <String, dynamic>{}) as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CommentPage {
  CommentPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  final int page;
  final int limit;
  final int total;
  final List<EpisodeComment> items;

  factory CommentPage.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List<dynamic>? ?? <dynamic>[]);
    return CommentPage(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? raw.length,
      items: raw
          .map((item) => EpisodeComment.fromJson((item ?? <String, dynamic>{}) as Map<String, dynamic>))
          .toList(),
    );
  }
}
