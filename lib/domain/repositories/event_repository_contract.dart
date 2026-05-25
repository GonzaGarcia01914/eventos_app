import 'dart:io';
import '../entities/event.dart';

abstract interface class EventRepositoryContract {
  Future<List<Event>> searchNearby({
    required double latitude,
    required double longitude,
    String within = '50km',
  });

  Future<List<Event>> obtenerEventosAprobados();

  Future<bool> crearEvento({
    required String nombre,
    required String descripcion,
    required double precio,
    required List<String> categorias,
    required String ubicacionMaps,
    required File fotoOriginal,
    required String fecha,
    required String hora,
  });

  Future<List<Event>> obtenerEventosPendientesAdmin();

  Future<bool> aprobarEvento(int idEvento);
}
