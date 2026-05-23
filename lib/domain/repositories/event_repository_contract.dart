import '../entities/event.dart';

abstract interface class EventRepositoryContract {
  Future<List<Event>> searchNearby({
    required double latitude,
    required double longitude,
    String within = '50km',
  });
}
