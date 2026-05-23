import '../entities/event.dart';

abstract interface class FavoritesRepositoryContract {
  Future<List<Event>> getFavorites();

  Future<bool> isFavorite(String eventId);

  Future<void> toggleFavorite(Event event);
}
