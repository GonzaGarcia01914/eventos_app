import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/repositories/favorites_repository.dart';
import '../../../data/repositories/map_style_repository.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/favorites_repository_contract.dart';
import '../../../domain/repositories/map_style_repository_contract.dart';
import '../../../presentation/events/events_catalog_view_model.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required EventsCatalogViewModel eventsCatalog,
    MapStyleRepositoryContract? mapStyleRepository,
    FavoritesRepositoryContract? favoritesRepository,
  })  : _eventsCatalog = eventsCatalog,
        _mapStyleRepository = mapStyleRepository ?? const MapStyleRepository(),
        _favoritesRepository = favoritesRepository ?? FavoritesRepository() {
    _eventsCatalog.addListener(_onCatalogChanged);
  }

  final EventsCatalogViewModel _eventsCatalog;
  final MapStyleRepositoryContract _mapStyleRepository;
  final FavoritesRepositoryContract _favoritesRepository;

  String? _mapStyle;
  bool _isLoadingStyle = true;

  Set<Marker> _markers = {};

  Event? _selectedEvent;
  bool _isSelectedFavorite = false;
  bool _isTogglingFavorite = false;

  final Set<String> _favoriteIds = {};

  EventsCatalogViewModel get eventsCatalog => _eventsCatalog;

  String? get mapStyle => _mapStyle;
  bool get isLoadingStyle => _isLoadingStyle;
  Set<Marker> get markers => _markers;
  Event? get selectedEvent => _selectedEvent;
  bool get isSelectedFavorite => _isSelectedFavorite;
  bool get isTogglingFavorite => _isTogglingFavorite;
  bool get hasSelectedEvent => _selectedEvent != null;

  Future<void> initialize() async {
    await Future.wait([
      _loadMapStyle(),
      _loadFavoriteIds(),
    ]);
    _rebuildMarkers();
    notifyListeners();
  }

  void _onCatalogChanged() {
    _rebuildMarkers();
    notifyListeners();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await _mapStyleRepository.loadDarkStyle();
    _isLoadingStyle = false;
    notifyListeners();
  }

  Future<void> _loadFavoriteIds() async {
    final favorites = await _favoritesRepository.getFavorites();
    _favoriteIds
      ..clear()
      ..addAll(favorites.map((event) => event.id));
  }

  void _rebuildMarkers() {
    _markers = _eventsCatalog.visibleEvents.map(_buildMarker).toSet();
  }

  Marker _buildMarker(Event event) {
    return Marker(
      markerId: MarkerId(event.id),
      position: LatLng(event.latitude, event.longitude),
      infoWindow: InfoWindow(title: event.title),
      onTap: () => selectEvent(event),
    );
  }

  Future<void> selectEvent(Event event) async {
    _selectedEvent = event;
    _isSelectedFavorite = _favoriteIds.contains(event.id);
    notifyListeners();
  }

  void clearSelectedEvent() {
    _selectedEvent = null;
    _isSelectedFavorite = false;
    notifyListeners();
  }

  Future<void> toggleSelectedFavorite() async {
    final event = _selectedEvent;
    if (event == null || _isTogglingFavorite) return;

    _isTogglingFavorite = true;
    notifyListeners();

    await _favoritesRepository.toggleFavorite(event);

    if (_favoriteIds.contains(event.id)) {
      _favoriteIds.remove(event.id);
      _isSelectedFavorite = false;
    } else {
      _favoriteIds.add(event.id);
      _isSelectedFavorite = true;
    }

    _isTogglingFavorite = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _eventsCatalog.removeListener(_onCatalogChanged);
    super.dispose();
  }
}
