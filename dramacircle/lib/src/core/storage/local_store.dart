import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;

  static const _tokenKey = 'auth_token';
  static const _favoritesKey = 'favorite_ids';
  static const _historyKey = 'watch_history';
  static const _continueWatchingKey = 'continue_watching';
  static const _episodePositionsKey = 'episode_positions';
  static const _guestFreeUsedKey = 'guest_free_play_used';
  static const _guestUnlockedEpisodeKey = 'guest_unlocked_episode_id';

  String? get token => _prefs.getString(_tokenKey);
  Future<void> setToken(String? value) async {
    if (value == null) {
      await _prefs.remove(_tokenKey);
      return;
    }
    await _prefs.setString(_tokenKey, value);
  }

  Set<String> get favorites => (_prefs.getStringList(_favoritesKey) ?? []).toSet();
  Future<void> setFavorites(Set<String> ids) => _prefs.setStringList(_favoritesKey, ids.toList());

  List<String> get history => _prefs.getStringList(_historyKey) ?? <String>[];
  Future<void> pushHistory(String episodeId) async {
    final list = history.where((item) => item != episodeId).toList();
    list.insert(0, episodeId);
    await _prefs.setStringList(_historyKey, list.take(100).toList());
  }

  Map<String, dynamic> get continueWatching {
    final value = _prefs.getString(_continueWatchingKey);
    if (value == null || value.isEmpty) return <String, dynamic>{};
    final map = jsonDecode(value) as Map<String, dynamic>;
    return map;
  }

  Future<void> setContinueWatching({
    required String dramaId,
    required String episodeId,
    required int positionMs,
  }) async {
    final map = continueWatching;
    map[dramaId] = {
      'episodeId': episodeId,
      'positionMs': positionMs,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_continueWatchingKey, jsonEncode(map));
  }

  Map<String, dynamic> get episodePositions {
    final value = _prefs.getString(_episodePositionsKey);
    if (value == null || value.isEmpty) return <String, dynamic>{};
    return jsonDecode(value) as Map<String, dynamic>;
  }

  int getEpisodePositionMs(String episodeId) {
    final value = episodePositions[episodeId];
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  Future<void> setEpisodePositionMs({
    required String episodeId,
    required int positionMs,
  }) async {
    final map = episodePositions;
    map[episodeId] = positionMs;
    await _prefs.setString(_episodePositionsKey, jsonEncode(map));
  }

  bool get guestFreePlayUsed => _prefs.getBool(_guestFreeUsedKey) ?? false;
  Future<void> setGuestFreePlayUsed(bool value) => _prefs.setBool(_guestFreeUsedKey, value);

  String? get guestUnlockedEpisodeId => _prefs.getString(_guestUnlockedEpisodeKey);
  Future<void> setGuestUnlockedEpisodeId(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_guestUnlockedEpisodeKey);
      return;
    }
    await _prefs.setString(_guestUnlockedEpisodeKey, value);
  }
}
