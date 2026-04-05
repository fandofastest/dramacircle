import 'package:dramacircle/src/core/providers.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';
import 'package:dramacircle/src/data/repositories/drama_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dramaRepositoryProvider = Provider<DramaRepository>((ref) => DramaRepository(ref.watch(dioProvider)));

class FypState {
  FypState({
    required this.items,
    required this.loading,
    required this.loadingMore,
    required this.errorMessage,
  });

  final List<EpisodeItem> items;
  final bool loading;
  final bool loadingMore;
  final String? errorMessage;

  FypState copyWith({
    List<EpisodeItem>? items,
    bool? loading,
    bool? loadingMore,
    String? errorMessage,
  }) {
    return FypState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FypController extends Notifier<FypState> {
  @override
  FypState build() {
    Future<void>(() => refresh());
    return FypState(items: const <EpisodeItem>[], loading: true, loadingMore: false, errorMessage: null);
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, errorMessage: '');
    try {
      final list = await ref.read(dramaRepositoryProvider).randomDrama();
      state = state.copyWith(items: list, loading: false, errorMessage: '');
    } catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.toString());
    }
  }

  Future<void> loadMoreIfNeeded(int index) async {
    if (state.loadingMore || index < state.items.length - 3) {
      return;
    }
    state = state.copyWith(loadingMore: true);
    try {
      final list = await ref.read(dramaRepositoryProvider).randomDrama();
      state = state.copyWith(items: <EpisodeItem>[...state.items, ...list], loadingMore: false);
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }
}

final fypControllerProvider = NotifierProvider<FypController, FypState>(FypController.new);
