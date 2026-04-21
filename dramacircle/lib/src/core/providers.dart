import 'package:dio/dio.dart';
import 'package:dramacircle/src/core/config/app_config.dart';
import 'package:dramacircle/src/core/storage/local_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final localStoreProvider = Provider<LocalStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  if (prefs == null) {
    throw StateError('LocalStore is not ready');
  }
  return LocalStore(prefs);
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final store = ref.watch(localStoreProvider);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = store.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await store.setToken(null);
        }
        handler.next(error);
      },
    ),
  );
  return dio;
});
