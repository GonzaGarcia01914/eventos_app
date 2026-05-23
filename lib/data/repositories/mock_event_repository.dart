import 'dart:math';

import '../../domain/entities/event.dart';
import '../../domain/entities/event_type.dart';
import '../../domain/repositories/event_repository_contract.dart';

/// Eventos de prueba con posiciones aleatorias cerca del centro de búsqueda.
class MockEventRepository implements EventRepositoryContract {
  MockEventRepository({Random? random}) : _random = random ?? Random();

  final Random _random;

  static final List<({String title, EventType type})> _eventTemplates = [
    (title: 'Festival de Jazz en la Costanera', type: EventType.music),
    (title: 'Noche de Stand-up Comedy', type: EventType.comedy),
    (title: 'Feria Gastronómica Internacional', type: EventType.food),
    (title: 'Concierto Acústico al Aire Libre', type: EventType.music),
    (title: 'Mercado de Artesanías', type: EventType.culture),
    (title: 'Maratón de Cine Independiente', type: EventType.culture),
    (title: 'Expo de Tecnología y Startups', type: EventType.tech),
    (title: 'Clase Maestra de Danza', type: EventType.culture),
    (title: 'Tour Nocturno por el Centro Histórico', type: EventType.nightlife),
    (title: 'Festival de Cerveza Artesanal', type: EventType.food),
    (title: 'Concierto de Rock Nacional', type: EventType.music),
    (title: 'Feria del Libro', type: EventType.culture),
    (title: 'Sesión de Yoga al Amanecer', type: EventType.sports),
    (title: 'Noche de Karaoke', type: EventType.nightlife),
    (title: 'Exposición de Fotografía Urbana', type: EventType.culture),
    (title: 'Torneo Amateur de Fútbol', type: EventType.sports),
    (title: 'Hackathon Ciudad Inteligente', type: EventType.tech),
  ];

  static const _venues = [
    'Costanera de Asunción',
    'Teatro Municipal',
    'Centro Cultural Paraguayo',
    'Parque Ñu Guasu',
    'Paseo La Galería',
    'Estación del Ferrocarril',
    'Plaza de la República',
    'Jardín Botánico',
    'Villa Morra',
    'Recoleta',
  ];

  static const _priceOptions = [
    (label: 'Gratis', amount: 0),
    (label: '₲ 35.000', amount: 35000),
    (label: '₲ 80.000', amount: 80000),
    (label: '₲ 120.000', amount: 120000),
    (label: '₲ 200.000', amount: 200000),
  ];

  static const _sampleVideos = [
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
  ];

  @override
  Future<List<Event>> searchNearby({
    required double latitude,
    required double longitude,
    String within = '50km',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final count = 12 + _random.nextInt(6);
    return List.generate(count, (index) {
      return _buildEvent(
        index: index,
        centerLat: latitude,
        centerLng: longitude,
      );
    });
  }

  Event _buildEvent({
    required int index,
    required double centerLat,
    required double centerLng,
  }) {
    final id = 'mock-$index-${_random.nextInt(99999)}';
    final template = _eventTemplates[_random.nextInt(_eventTemplates.length)];
    final location = _venues[_random.nextInt(_venues.length)];
    final daysAhead = 1 + _random.nextInt(45);
    final hour = 10 + _random.nextInt(12);
    final startAt = DateTime.now().add(Duration(days: daysAhead)).copyWith(
      hour: hour,
      minute: [0, 30][_random.nextInt(2)],
    );
    final price = _priceOptions[_random.nextInt(_priceOptions.length)];

    final latOffset = (_random.nextDouble() - 0.5) * 0.072;
    final lngOffset = (_random.nextDouble() - 0.5) * 0.072;
    final hasVideo = _random.nextInt(3) == 0;

    return Event(
      id: id,
      title: template.title,
      imageUrl: 'https://picsum.photos/seed/$id/800/500',
      videoUrl: hasVideo
          ? _sampleVideos[_random.nextInt(_sampleVideos.length)]
          : null,
      location: location,
      startAt: startAt,
      priceLabel: price.label,
      priceAmount: price.amount,
      type: template.type,
      latitude: centerLat + latOffset,
      longitude: centerLng + lngOffset,
    );
  }
}
