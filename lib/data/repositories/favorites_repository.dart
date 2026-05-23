import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/event.dart';
import '../../domain/repositories/favorites_repository_contract.dart';

class FavoritesRepository implements FavoritesRepositoryContract {
  static const _storageKey = 'favorite_events';

  @override
  Future<List<Event>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map((item) => Event.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> isFavorite(String eventId) async {
    final favorites = await getFavorites();
    return favorites.any((event) => event.id == eventId);
  }

  @override
  Future<void> toggleFavorite(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    final exists = favorites.any((item) => item.id == event.id);

    final updated = exists
        ? favorites.where((item) => item.id != event.id).toList()
        : [...favorites, event];

    await prefs.setStringList(
      _storageKey,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
