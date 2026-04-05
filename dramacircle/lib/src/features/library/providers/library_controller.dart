import 'package:dramacircle/src/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return ref.watch(localStoreProvider).favorites;
  }

  Future<void> toggleFavorite(String id) async {
    final next = Set<String>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    await ref.read(localStoreProvider).setFavorites(next);
  }
}

final favoritesProvider = NotifierProvider<LibraryController, Set<String>>(LibraryController.new);
