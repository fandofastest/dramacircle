import 'package:cached_network_image/cached_network_image.dart';
import 'package:dramacircle/src/core/providers.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';
import 'package:dramacircle/src/features/auth/presentation/login_screen.dart';
import 'package:dramacircle/src/features/auth/providers/auth_controller.dart';
import 'package:dramacircle/src/features/auth/providers/guest_access_controller.dart';
import 'package:dramacircle/src/features/fyp/providers/fyp_controller.dart';
import 'package:dramacircle/src/features/player/presentation/player_screen.dart';
import 'package:dramacircle/src/features/premium/presentation/premium_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.bookId});
  final String bookId;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _loading = true;
  Map<String, dynamic> _detail = <String, dynamic>{};
  List<EpisodeItem> _episodes = <EpisodeItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(dramaRepositoryProvider);
    final detail = await repo.detail(widget.bookId);
    final episodes = await repo.episodes(widget.bookId);
    final fallbackTitle = (detail['title'] ?? 'Drama').toString();
    final fallbackDescription = (detail['description'] ?? '').toString();
    final mapped = episodes
        .map(
          (e) => EpisodeItem(
            episodeId: e.episodeId,
            bookId: e.bookId,
            episodeNumber: e.episodeNumber,
            videoUrl: e.videoUrl,
            isPremium: e.isPremium || e.episodeNumber > 3,
            title: fallbackTitle,
            description: fallbackDescription,
            cover: e.cover,
          ),
        )
        .toList();
    if (mounted) {
      setState(() {
        _detail = detail;
        _episodes = mapped;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final guestAccess = ref.watch(guestAccessProvider);
    final store = ref.watch(localStoreProvider);
    final watchedSet = store.history.toSet();
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cover = _detail['cover']?.toString() ?? '';
    final title = _detail['title']?.toString() ?? 'Drama Detail';
    final desc = _detail['description']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: cover,
              height: 220,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(height: 220, color: Colors.grey.shade900),
            ),
          ),
          const SizedBox(height: 12),
          Text(desc),
          const SizedBox(height: 18),
          const Text('Episodes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: _episodes.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, index) {
              final episode = _episodes[index];
              final premiumLocked = episode.isPremium && !(user?.isPremium ?? false);
              final guestLocked = user == null && guestAccess.used && guestAccess.unlockedEpisodeId != episode.episodeId;
              final locked = premiumLocked || guestLocked;
              final watched = watchedSet.contains(episode.episodeId);
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: locked
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => guestLocked ? const LoginScreen() : const PremiumScreen()),
                        )
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              episodes: _episodes,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: watched ? Colors.green.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: watched ? Colors.green.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ep ${episode.episodeNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (watched) const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      if (locked) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock_outline, size: 16)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
