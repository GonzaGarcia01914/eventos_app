import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/events/event_type_visuals.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../data/repositories/map_style_repository.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_type.dart';
import '../../../domain/repositories/favorites_repository_contract.dart';
import '../../../domain/repositories/map_style_repository_contract.dart';
import '../../../presentation/events/events_catalog_view_model.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required EventsCatalogViewModel eventsCatalog,
    MapStyleRepositoryContract? mapStyleRepository,
    FavoritesRepositoryContract? favoritesRepository,
  }) : _eventsCatalog = eventsCatalog,
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
  final Map<EventType, BitmapDescriptor> _markerIconCache = {};

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
    await Future.wait([_loadMapStyle(), _loadFavoriteIds()]);
    await _rebuildMarkers();
    notifyListeners();
  }

  void _onCatalogChanged() {
    _rebuildMarkers();
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

  Future<void> _rebuildMarkers() async {
    final markers = <Marker>{};
    for (final event in _eventsCatalog.visibleEvents) {
      markers.add(await _buildMarker(event));
    }

    _markers = markers;
    notifyListeners();
  }

  Future<Marker> _buildMarker(Event event) async {
    return Marker(
      markerId: MarkerId(event.id),
      position: LatLng(event.latitude, event.longitude),
      icon: await _markerIconFor(event.type),
      infoWindow: InfoWindow(title: event.title),
      onTap: () => selectEvent(event),
    );
  }

  Future<BitmapDescriptor> _markerIconFor(EventType type) async {
    final cached = _markerIconCache[type];
    if (cached != null) return cached;

    final icon = await _buildCategoryMarkerIcon(
      EventTypeVisuals.icon(type),
      EventTypeVisuals.color(type),
    );
    _markerIconCache[type] = icon;
    return icon;
  }

  Future<BitmapDescriptor> _buildCategoryMarkerIcon(
    IconData icon,
    Color color,
  ) async {
    const size = 64.0;
    const iconSize = 30.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center.translate(0, 2),
      27,
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawCircle(center, 25, Paint()..color = Colors.white);
    canvas.drawCircle(center, 21, Paint()..color = color);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: Colors.white,
        fontSize: iconSize,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
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
