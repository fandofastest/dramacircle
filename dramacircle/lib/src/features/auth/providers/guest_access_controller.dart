import 'package:dramacircle/src/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuestAccessState {
  const GuestAccessState({
    required this.used,
    required this.unlockedEpisodeId,
  });

  final bool used;
  final String? unlockedEpisodeId;
}

class GuestAccessController extends Notifier<GuestAccessState> {
  @override
  GuestAccessState build() {
    final store = ref.watch(localStoreProvider);
    return GuestAccessState(
      used: store.guestFreePlayUsed,
      unlockedEpisodeId: store.guestUnlockedEpisodeId,
    );
  }

  bool isLockedForGuest(String episodeId) {
    if (!state.used) return false;
    return state.unlockedEpisodeId != episodeId;
  }

  Future<void> consumeIfNeeded(String episodeId) async {
    if (state.used) return;
    state = GuestAccessState(used: true, unlockedEpisodeId: episodeId);
    final store = ref.read(localStoreProvider);
    await store.setGuestFreePlayUsed(true);
    await store.setGuestUnlockedEpisodeId(episodeId);
  }
}

final guestAccessProvider = NotifierProvider<GuestAccessController, GuestAccessState>(GuestAccessController.new);
