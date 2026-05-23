import 'package:flutter/foundation.dart';

import '../../../data/repositories/favorites_repository.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/favorites_repository_contract.dart';

class FavouritesViewModel extends ChangeNotifier {
  FavouritesViewModel({
    FavoritesRepositoryContract? favoritesRepository,
  }) : _favoritesRepository = favoritesRepository ?? FavoritesRepository();

  final FavoritesRepositoryContract _favoritesRepository;

  List<Event> _favorites = [];
  bool _isLoading = true;

  List<Event> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isEmpty => !_isLoading && _favorites.isEmpty;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    _favorites = await _favoritesRepository.getFavorites();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeFavorite(Event event) async {
    await _favoritesRepository.toggleFavorite(event);
    await loadFavorites();
  }
}
