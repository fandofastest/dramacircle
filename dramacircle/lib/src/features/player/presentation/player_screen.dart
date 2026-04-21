import 'package:dramacircle/src/core/providers.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';
import 'package:dramacircle/src/features/auth/providers/auth_controller.dart';
import 'package:dramacircle/src/features/fyp/presentation/fyp_video_page.dart';
import 'package:dramacircle/src/features/fyp/providers/fyp_controller.dart';
import 'package:dramacircle/src/features/premium/presentation/premium_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.episodes,
    this.initialIndex = 0,
  });

  final List<EpisodeItem> episodes;
  final int initialIndex;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final PageController _pageController;
  late List<EpisodeItem> _episodes;
  final Set<int> _resolvingIndexes = <int>{};
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _episodes = List<EpisodeItem>.from(widget.episodes);
    _currentIndex = widget.initialIndex;
    _resolveForIndex(widget.initialIndex);
    _resolveForIndex(widget.initialIndex + 1);
  }

  bool _needsDecrypt(String url) {
    if (url.isEmpty) {
      return false;
    }
    final lower = url.toLowerCase();
    if (lower.contains('decrypt-stream')) {
      return false;
    }
    return lower.contains('.encrypt.');
  }

  Future<void> _resolveForIndex(int index) async {
    if (index < 0 || index >= _episodes.length || _resolvingIndexes.contains(index)) {
      return;
    }
    final item = _episodes[index];
    if (item.videoUrl.isEmpty || !_needsDecrypt(item.videoUrl)) {
      return;
    }
    _resolvingIndexes.add(index);
    final stream = await ref.read(dramaRepositoryProvider).decryptStream(item.videoUrl);
    if (!mounted) {
      return;
    }
    _resolvingIndexes.remove(index);
    if (stream.isEmpty) {
      return;
    }
    setState(() {
      _episodes[index] = _episodes[index].copyWith(videoUrl: stream);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _resolveForIndex(index);
          _resolveForIndex(index + 1);
        },
        itemCount: _episodes.length,
        itemBuilder: (context, index) {
          final episode = _episodes[index];
          final store = ref.read(localStoreProvider);
          final premiumLocked = episode.isPremium && !(user?.isPremium ?? false);
          final unresolved = _needsDecrypt(episode.videoUrl);
          if (unresolved) {
            _resolveForIndex(index);
          }
          return FypVideoPage(
            episode: unresolved ? episode.copyWith(videoUrl: '') : episode,
            userPremium: user?.isPremium ?? false,
            isLocked: premiumLocked,
            lockTitle: 'Unlock this episode 🔒',
            lockButtonText: 'Go Premium',
            onGoPremium: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
            onPlaybackStarted: () {},
            onSaveProgress: (positionMs) async {
              await store.pushHistory(episode.episodeId);
              await store.setEpisodePositionMs(episodeId: episode.episodeId, positionMs: positionMs);
              await store.setContinueWatching(
                    dramaId: episode.bookId,
                    episodeId: episode.episodeId,
                    positionMs: positionMs,
                  );
            },
            initialPositionMs: store.getEpisodePositionMs(episode.episodeId),
            showSeekBar: true,
            onWatchFull: null,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEpisodePicker(user: user),
        icon: const Icon(Icons.grid_view_rounded),
        label: const Text('Episodes'),
      ),
    );
  }

  Future<void> _openEpisodePicker({
    required UserProfile? user,
  }) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pilih Episode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 320,
                  child: GridView.builder(
                    itemCount: _episodes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.45,
                    ),
                    itemBuilder: (context, index) {
                      final episode = _episodes[index];
                      final premiumLocked = episode.isPremium && !(user?.isPremium ?? false);
                      final locked = premiumLocked;
                      final active = index == _currentIndex;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (!locked) {
                            Navigator.of(context).pop(index);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: active ? Colors.deepPurple.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: active ? Colors.deepPurpleAccent : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Ep ${episode.episodeNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (locked) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_outline, size: 14)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) {
      return;
    }
    _resolveForIndex(picked);
    _resolveForIndex(picked + 1);
    await _pageController.animateToPage(
      picked,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}
