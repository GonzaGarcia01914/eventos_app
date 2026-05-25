import 'dart:io';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_type.dart';
import '../../domain/repositories/event_repository_contract.dart';
import '../services/evento_service.dart';

class EventoRepository implements EventRepositoryContract {
  final EventoService _service;

  EventoRepository({EventoService? service})
    : _service = service ?? EventoService();

  @override
  Future<List<Event>> searchNearby({
    required double latitude,
    required double longitude,
    String within = '50km',
  }) async {
    return obtenerEventosAprobados();
  }

  @override
  Future<List<Event>> obtenerEventosAprobados() async {
    try {
      final eventosJson = await _service.obtenerEventosAprobados();
      return eventosJson
          .map((json) => _mapJsonToEvent(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> crearEvento({
    required String nombre,
    required String descripcion,
    required double precio,
    required List<String> categorias,
    required String ubicacionMaps,
    required File fotoOriginal,
    required String fecha,
    required String hora,
  }) async {
    return _service.crearEvento(
      nombre: nombre,
      descripcion: descripcion,
      precio: precio,
      categorias: categorias,
      ubicacionMaps: ubicacionMaps,
      fotoOriginal: fotoOriginal,
      fecha: fecha,
      hora: hora,
    );
  }

  @override
  Future<List<Event>> obtenerEventosPendientesAdmin() async {
    try {
      final eventosJson = await _service.obtenerEventosPendientesAdmin();
      return eventosJson
          .map((json) => _mapJsonToEvent(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> aprobarEvento(int idEvento) async {
    return _service.aprobarEvento(idEvento);
  }

  Event _mapJsonToEvent(Map<String, dynamic> json) {
    final nombre = json['nombre'] as String? ?? 'Sin nombre';
    final precio = (json['precio'] as num?)?.toDouble() ?? 0.0;
    final categorias =
        (json['categorias'] as List<dynamic>?)?.cast<String>() ?? [];
    final ubicacionMaps = json['ubicacion_maps'] as String? ?? '';
    final imagenUrl = json['imagen_url'] as String?;
    final fecha = json['fecha'] as String? ?? '';
    final hora = json['hora'] as String? ?? '';
    final id = json['id']?.toString() ?? DateTime.now().toString();
    final latitude = (json['latitude'] as num?)?.toDouble() ?? -25.2637;
    final longitude = (json['longitude'] as num?)?.toDouble() ?? -57.5759;

    EventType type = EventType.other;
    if (categorias.isNotEmpty) {
      type = EventType.values.firstWhere(
        (e) => e.name == categorias[0].toLowerCase(),
        orElse: () => EventType.other,
      );
    }

    final List<EventType> types = categorias
        .map(
          (cat) => EventType.values.firstWhere(
            (e) => e.name == cat.toLowerCase(),
            orElse: () => EventType.other,
          ),
        )
        .toList();

    final priceLabel = precio == 0
        ? 'Gratis'
        : '₲ ${_formatCurrency(precio.toInt())}';

    DateTime startAt;
    try {
      startAt = _parseDateTime(fecha, hora);
    } catch (e) {
      startAt = DateTime.now();
    }

    return Event(
      id: id,
      title: nombre,
      location: ubicacionMaps,
      startAt: startAt,
      priceLabel: priceLabel,
      priceAmount: precio.toInt(),
      type: type,
      types: types.isEmpty ? [type] : types,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imagenUrl,
      videoUrl: null,
    );
  }

  DateTime _parseDateTime(String fecha, String hora) {
    final dateParts = fecha.split('-');
    final timeParts = hora.split(':');

    if (dateParts.length != 3 || timeParts.length < 2) {
      return DateTime.now();
    }

    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  String _formatCurrency(int value) {
    final parts = <String>[];
    var num = value;
    while (num > 0) {
      parts.insert(
        0,
        (num % 1000).toString().padLeft(parts.isEmpty ? 1 : 3, '0'),
      );
      num ~/= 1000;
    }
    return parts.join(',');
  }
}
