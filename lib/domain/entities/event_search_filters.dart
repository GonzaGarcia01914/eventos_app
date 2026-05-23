import 'event_type.dart';

/// Parámetros de búsqueda y filtrado de eventos.
class EventSearchFilters {
  const EventSearchFilters({
    this.eventType,
    this.startDateFrom,
    this.startDateTo,
    this.minPrice,
    this.maxPrice,
    this.onlyFree = false,
  });

  final EventType? eventType;
  final DateTime? startDateFrom;
  final DateTime? startDateTo;
  final int? minPrice;
  final int? maxPrice;
  final bool onlyFree;

  static const empty = EventSearchFilters();

  bool get hasActiveFilters =>
      eventType != null ||
      startDateFrom != null ||
      startDateTo != null ||
      minPrice != null ||
      maxPrice != null ||
      onlyFree;

  EventSearchFilters copyWith({
    EventType? eventType,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    int? minPrice,
    int? maxPrice,
    bool? onlyFree,
    bool clearEventType = false,
    bool clearStartDateFrom = false,
    bool clearStartDateTo = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return EventSearchFilters(
      eventType: clearEventType ? null : (eventType ?? this.eventType),
      startDateFrom:
          clearStartDateFrom ? null : (startDateFrom ?? this.startDateFrom),
      startDateTo: clearStartDateTo ? null : (startDateTo ?? this.startDateTo),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      onlyFree: onlyFree ?? this.onlyFree,
    );
  }

  static const int defaultMinPrice = 0;
  static const int defaultMaxPrice = 250000;
}
