import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/guarani_formatter.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_type.dart';
import '../../domain/repositories/event_repository_contract.dart';
import '../services/evento_service.dart';

class EventoRepository implements EventRepositoryContract {
  final EventoService _service;

  EventoRepository({EventoService? service})
    : _service = service ?? EventoService();

  static const Duration _approvedEventsCacheTtl = Duration(minutes: 5);
  static const String _approvedEventsCacheKey = 'approved_events_cache';
  static const String _approvedEventsCachedAtKey = 'approved_events_cached_at';
  static List<Event>? _cachedApprovedEvents;
  static DateTime? _approvedEventsCachedAt;

  @override
  Future<List<Event>> searchNearby({
    required double latitude,
    required double longitude,
    String within = '50km',
    bool forceRefresh = false,
  }) async {
    return obtenerEventosAprobados(forceRefresh: forceRefresh);
  }

  @override
  Future<List<Event>> obtenerEventosAprobados({
    bool forceRefresh = false,
  }) async {
    try {
      final cached = _cachedApprovedEvents;
      final cachedAt = _approvedEventsCachedAt;
      if (!forceRefresh && cached != null && cachedAt != null) {
        final cacheAge = DateTime.now().difference(cachedAt);
        if (cacheAge < _approvedEventsCacheTtl) {
          return List<Event>.unmodifiable(cached);
        }
      }

      if (!forceRefresh) {
        final persistedCache = await _readPersistedApprovedEventsCache();
        if (persistedCache != null) return persistedCache;
      }

      final eventosJson = await _service.obtenerEventosAprobados();
      final events = eventosJson
          .map((json) => _mapJsonToEvent(json as Map<String, dynamic>))
          .toList();
      _cachedApprovedEvents = List<Event>.unmodifiable(events);
      _approvedEventsCachedAt = DateTime.now();
      await _writePersistedApprovedEventsCache(
        events,
        _approvedEventsCachedAt!,
      );
      return events;
    } catch (e) {
      return _cachedApprovedEvents ?? [];
    }
  }

  Future<List<Event>?> _readPersistedApprovedEventsCache() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedEvents = preferences.getString(_approvedEventsCacheKey);
    final cachedAtMillis = preferences.getInt(_approvedEventsCachedAtKey);
    if (encodedEvents == null || cachedAtMillis == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMillis);
    final cacheAge = DateTime.now().difference(cachedAt);
    if (cacheAge >= _approvedEventsCacheTtl) return null;

    try {
      final decoded = jsonDecode(encodedEvents) as List<dynamic>;
      final events = decoded
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
      _cachedApprovedEvents = List<Event>.unmodifiable(events);
      _approvedEventsCachedAt = cachedAt;
      return events;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePersistedApprovedEventsCache(
    List<Event> events,
    DateTime cachedAt,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _approvedEventsCacheKey,
      jsonEncode(events.map((event) => event.toJson()).toList()),
    );
    await preferences.setInt(
      _approvedEventsCachedAtKey,
      cachedAt.millisecondsSinceEpoch,
    );
  }

  @override
  Future<bool> crearEvento({
    required String nombre,
    required String descripcion,
    required double precio,
    required List<String> categorias,
    required String ubicacionMaps,
    required XFile fotoOriginal,
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

  @override
  Future<bool> eliminarEvento(int idEvento) async {
    _logDelete("Repositorio: Iniciando eliminación del evento $idEvento");
    try {
      _logDelete("Repositorio: Llamando al servicio...");
      final success = await _service.eliminarEvento(idEvento);

      if (success) {
        _logDelete("Repositorio: ✅ Servicio confirmó eliminación");
        _logDelete("Repositorio: Limpiando cache de eventos aprobados...");
        _cachedApprovedEvents = null;
        _approvedEventsCachedAt = null;
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove(_approvedEventsCacheKey);
        _logDelete("  - Cache en memoria limpiado");
        await preferences.remove(_approvedEventsCachedAtKey);
        _logDelete("  - Cache en SharedPreferences limpiado");
        _logDelete(
          "✅ Repositorio: Evento $idEvento eliminado y cache actualizado",
        );
      } else {
        _logDeleteError("❌ Repositorio: El servicio devolvió false");
      }
      return success;
    } catch (e, stacktrace) {
      _logDeleteError("❌ Repositorio: Excepción - $e");
      _logDeleteError("Stack: $stacktrace");
      return false;
    }
  }

  void _logDelete(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    print("[REPO DELETE] [$timestamp] $message");
  }

  void _logDeleteError(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    print("[REPO DELETE ERROR] [$timestamp] $message");
  }

  Event _mapJsonToEvent(Map<String, dynamic> json) {
    final nombre = json['nombre'] as String? ?? 'Sin nombre';
    final descripcion = json['descripcion'] as String? ?? '';
    final precio = _parsePrecio(json['precio']);
    final categorias = _parseCategories(json['categorias']);
    final ubicacionMaps = json['ubicacion_maps'] as String? ?? '';
    final parsedLocation = _parseLocation(ubicacionMaps, json);
    final imagenUrl = json['imagen_url'] as String?;
    final fecha = json['fecha'] as String? ?? '';
    final hora = json['hora'] as String? ?? '';
    final id = json['id']?.toString() ?? DateTime.now().toString();

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

    final priceAmount = precio.round();
    final priceLabel = GuaraniFormatter.formatInWords(priceAmount);

    DateTime startAt;
    try {
      startAt = _parseDateTime(fecha, hora);
    } catch (e) {
      startAt = DateTime.now();
    }

    return Event(
      id: id,
      title: nombre,
      description: descripcion,
      location: parsedLocation.label,
      startAt: startAt,
      priceLabel: priceLabel,
      priceAmount: priceAmount,
      type: type,
      types: types.isEmpty ? [type] : types,
      latitude: parsedLocation.latitude,
      longitude: parsedLocation.longitude,
      imageUrl: imagenUrl,
      videoUrl: null,
    );
  }

  List<String> _parseCategories(Object? value) {
    if (value is List<dynamic>) {
      return value.map((category) => category.toString()).toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((category) => category.trim())
          .where((category) => category.isNotEmpty)
          .toList();
    }
    return [];
  }

  _ParsedLocation _parseLocation(
    String rawLocation,
    Map<String, dynamic> json,
  ) {
    final explicitLatitude = (json['latitude'] as num?)?.toDouble();
    final explicitLongitude = (json['longitude'] as num?)?.toDouble();
    if (explicitLatitude != null && explicitLongitude != null) {
      return _ParsedLocation(
        label: rawLocation,
        latitude: explicitLatitude,
        longitude: explicitLongitude,
      );
    }

    final encodedParts = rawLocation.split('|');
    if (encodedParts.length >= 2) {
      final coordinates = _parseCoordinates(encodedParts.last);
      if (coordinates != null) {
        return _ParsedLocation(
          label: encodedParts.first.trim().isEmpty
              ? rawLocation
              : encodedParts.first.trim(),
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
        );
      }
    }

    final coordinates = _parseCoordinates(rawLocation);
    if (coordinates != null) {
      return _ParsedLocation(
        label: rawLocation,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      );
    }

    return _ParsedLocation(
      label: rawLocation,
      latitude: -25.2637,
      longitude: -57.5759,
    );
  }

  _Coordinates? _parseCoordinates(String value) {
    final decoded = _safeDecode(value);
    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(decoded);
    if (match == null) return null;

    final first = double.tryParse(match.group(1)!);
    final second = double.tryParse(match.group(2)!);
    if (first == null || second == null) return null;

    final looksLikeLatLng =
        first >= -90 && first <= 90 && second >= -180 && second <= 180;
    if (!looksLikeLatLng) return null;

    return _Coordinates(latitude: first, longitude: second);
  }

  String _safeDecode(String value) {
    try {
      return Uri.decodeFull(value);
    } catch (_) {
      return value;
    }
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

  int _parsePrecio(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.round();
    if (value is String) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return 0;
      return int.parse(digits);
    }
    return 0;
  }
}

class _ParsedLocation {
  const _ParsedLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

class _Coordinates {
  const _Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
