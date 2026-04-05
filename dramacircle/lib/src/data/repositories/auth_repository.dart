import 'package:dio/dio.dart';
import 'package:dramacircle/src/core/storage/local_store.dart';
import 'package:dramacircle/src/data/models/drama_models.dart';

class AuthRepository {
  AuthRepository(this._dio, this._store);
  final Dio _dio;
  final LocalStore _store;

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/member/login', data: {'email': email, 'password': password});
    final data = response.data['data'] as Map<String, dynamic>;
    final token = (data['token'] ?? '').toString();
    final member = UserProfile.fromJson((data['member'] ?? <String, dynamic>{}) as Map<String, dynamic>);
    await _store.setToken(token);
    return member;
  }

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/member/register', data: {'name': name, 'email': email, 'password': password});
    final data = response.data['data'] as Map<String, dynamic>;
    final token = (data['token'] ?? '').toString();
    final member = UserProfile.fromJson((data['member'] ?? <String, dynamic>{}) as Map<String, dynamic>);
    await _store.setToken(token);
    return member;
  }

  Future<UserProfile> me() async {
    final response = await _dio.get('/member/me');
    return UserProfile.fromJson((response.data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>);
  }

  Future<UserProfile> setPremium(bool value) async {
    final response = await _dio.patch('/member/vip', data: {'isVip': value});
    final data = response.data['data'] as Map<String, dynamic>;
    final token = (data['token'] ?? '').toString();
    if (token.isNotEmpty) {
      await _store.setToken(token);
    }
    return UserProfile.fromJson((data['member'] ?? <String, dynamic>{}) as Map<String, dynamic>);
  }

  Future<void> logout() => _store.setToken(null);
}
