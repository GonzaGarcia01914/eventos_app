import '../entities/event.dart';
import '../entities/event_search_filters.dart';

class FilterEventsUseCase {
  const FilterEventsUseCase();

  List<Event> call({
    required List<Event> events,
    required String query,
    required EventSearchFilters filters,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return events.where((event) {
      if (!_matchesQuery(event, normalizedQuery)) return false;
      if (!_matchesFilters(event, filters)) return false;
      return true;
    }).toList();
  }

  bool _matchesQuery(Event event, String query) {
    if (query.isEmpty) return true;
    return event.title.toLowerCase().contains(query) ||
        event.location.toLowerCase().contains(query) ||
        event.eventTypes.any((type) => type.label.toLowerCase().contains(query));
  }

  bool _matchesFilters(Event event, EventSearchFilters filters) {
    if (filters.eventType != null &&
        !event.eventTypes.contains(filters.eventType)) {
      return false;
    }

    if (filters.onlyFree && event.priceAmount > 0) return false;

    if (filters.minPrice != null && event.priceAmount < filters.minPrice!) {
      return false;
    }

    if (filters.maxPrice != null && event.priceAmount > filters.maxPrice!) {
      return false;
    }

    if (filters.startDateFrom != null) {
      final from = DateTime(
        filters.startDateFrom!.year,
        filters.startDateFrom!.month,
        filters.startDateFrom!.day,
      );
      final eventDay = DateTime(event.startAt.year, event.startAt.month, event.startAt.day);
      if (eventDay.isBefore(from)) return false;
    }

    if (filters.startDateTo != null) {
      final to = DateTime(
        filters.startDateTo!.year,
        filters.startDateTo!.month,
        filters.startDateTo!.day,
        23,
        59,
        59,
      );
      if (event.startAt.isAfter(to)) return false;
    }

    return true;
  }
}
