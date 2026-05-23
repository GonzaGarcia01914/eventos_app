import 'package:flutter/foundation.dart';

import '../../data/repositories/mock_event_repository.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_search_filters.dart';
import '../../domain/repositories/event_repository_contract.dart';
import '../../domain/use_cases/filter_events_use_case.dart';

/// Estado compartido de eventos (mapa, filtros y Discover).
class EventsCatalogViewModel extends ChangeNotifier {
  EventsCatalogViewModel({
    EventRepositoryContract? eventRepository,
    FilterEventsUseCase? filterEventsUseCase,
    this.searchLatitude = -25.2637,
    this.searchLongitude = -57.5759,
  })  : _eventRepository = eventRepository ?? MockEventRepository(),
        _filterEventsUseCase = filterEventsUseCase ?? const FilterEventsUseCase();

  final EventRepositoryContract _eventRepository;
  final FilterEventsUseCase _filterEventsUseCase;

  final double searchLatitude;
  final double searchLongitude;

  List<Event> _allEvents = [];
  bool _isLoadingEvents = false;
  String? _eventsError;

  String _searchQuery = '';
  EventSearchFilters _appliedFilters = EventSearchFilters.empty;
  EventSearchFilters _draftFilters = EventSearchFilters.empty;
  bool _isFilterDrawerOpen = false;

  List<Event> get allEvents => _allEvents;
  List<Event> get visibleEvents => _filterEventsUseCase(
        events: _allEvents,
        query: _searchQuery,
        filters: _appliedFilters,
      );
  bool get isLoadingEvents => _isLoadingEvents;
  String? get eventsError => _eventsError;
  String get searchQuery => _searchQuery;
  EventSearchFilters get appliedFilters => _appliedFilters;
  EventSearchFilters get draftFilters => _draftFilters;
  bool get isFilterDrawerOpen => _isFilterDrawerOpen;
  bool get hasActiveFilters => _appliedFilters.hasActiveFilters;

  Future<void> initialize() => loadEvents();

  Future<void> loadEvents() async {
    _isLoadingEvents = true;
    _eventsError = null;
    notifyListeners();

    try {
      _allEvents = await _eventRepository.searchNearby(
        latitude: searchLatitude,
        longitude: searchLongitude,
      );
    } catch (error) {
      _allEvents = [];
      _eventsError = error.toString();
    } finally {
      _isLoadingEvents = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void openFilterDrawer() {
    _draftFilters = _appliedFilters;
    _isFilterDrawerOpen = true;
    notifyListeners();
  }

  void closeFilterDrawer() {
    _isFilterDrawerOpen = false;
    notifyListeners();
  }

  void updateDraftFilters(EventSearchFilters filters) {
    _draftFilters = filters;
    notifyListeners();
  }

  void applyDraftFilters() {
    _appliedFilters = _draftFilters;
    _isFilterDrawerOpen = false;
    notifyListeners();
  }

  void clearDraftFilters() {
    _draftFilters = EventSearchFilters.empty;
    notifyListeners();
  }
}
