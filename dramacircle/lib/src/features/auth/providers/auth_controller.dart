import 'package:dramacircle/src/core/providers.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';
import 'package:dramacircle/src/data/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(localStoreProvider));
});

class AuthController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final prefsReady = ref.watch(sharedPreferencesProvider);
    if (!prefsReady.hasValue) {
      return null;
    }
    final store = ref.watch(localStoreProvider);
    final token = store.token;
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      return await ref.watch(authRepositoryProvider).me();
    } catch (_) {
      await store.setToken(null);
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).login(email: email, password: password));
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(name: name, email: email, password: password),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> setPremium(bool value) async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).setPremium(value));
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, UserProfile?>(AuthController.new);
