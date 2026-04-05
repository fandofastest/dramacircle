import 'package:dramacircle/src/core/providers.dart';
import 'package:dramacircle/src/features/auth/presentation/login_screen.dart';
import 'package:dramacircle/src/features/auth/providers/auth_controller.dart';
import 'package:dramacircle/src/features/auth/providers/guest_access_controller.dart';
import 'package:dramacircle/src/features/detail/presentation/detail_screen.dart';
import 'package:dramacircle/src/features/fyp/providers/fyp_controller.dart';
import 'package:dramacircle/src/features/fyp/presentation/fyp_video_page.dart';
import 'package:dramacircle/src/features/premium/presentation/premium_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class FypHomeScreen extends ConsumerStatefulWidget {
  const FypHomeScreen({super.key});

  @override
  ConsumerState<FypHomeScreen> createState() => _FypHomeScreenState();
}

class _FypHomeScreenState extends ConsumerState<FypHomeScreen> {
  final _controller = PageController();

  @override
  Widget build(BuildContext context) {
    final fypState = ref.watch(fypControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final guestAccess = ref.watch(guestAccessProvider);

    if (fypState.loading && fypState.items.isEmpty) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade900,
        highlightColor: Colors.grey.shade700,
        child: Container(color: Colors.black),
      );
    }

    if (fypState.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_disabled_outlined, size: 44),
              const SizedBox(height: 10),
              const Text('Home feed belum tersedia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                (fypState.errorMessage == null || fypState.errorMessage!.isEmpty)
                    ? 'Coba refresh untuk memuat video.'
                    : fypState.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => ref.read(fypControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _controller,
      scrollDirection: Axis.vertical,
      itemCount: fypState.items.length,
      onPageChanged: (index) => ref.read(fypControllerProvider.notifier).loadMoreIfNeeded(index),
      itemBuilder: (context, index) {
        final episode = fypState.items[index];
        final store = ref.read(localStoreProvider);
        final premiumLocked = episode.isPremium && !(user?.isPremium ?? false);
        final guestLocked = user == null && guestAccess.used && guestAccess.unlockedEpisodeId != episode.episodeId;
        final isLocked = premiumLocked || guestLocked;
        return FypVideoPage(
          episode: episode,
          userPremium: user?.isPremium ?? false,
          isLocked: isLocked,
          lockTitle: guestLocked ? 'Login untuk lanjut nonton 🔐' : 'Unlock this episode 🔒',
          lockButtonText: guestLocked ? 'Login' : 'Go Premium',
          onGoPremium: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => guestLocked ? const LoginScreen() : const PremiumScreen()),
            );
          },
          onPlaybackStarted: () {
            if (user == null && !guestAccess.used) {
              ref.read(guestAccessProvider.notifier).consumeIfNeeded(episode.episodeId);
            }
          },
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
          onWatchFull: episode.bookId.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DetailScreen(bookId: episode.bookId)),
                  );
                },
        );
      },
    );
  }
}
