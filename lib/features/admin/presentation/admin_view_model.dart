import 'package:flutter/foundation.dart';

import '../../../data/repositories/evento_repository.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/event_repository_contract.dart';

class AdminViewModel extends ChangeNotifier {
  AdminViewModel({EventRepositoryContract? eventRepository})
    : _eventRepository = eventRepository ?? EventoRepository();

  final EventRepositoryContract _eventRepository;

  List<Event> _pendingEvents = [];
  List<Event> _publishedEvents = [];
  List<Event> _filteredPublishedEvents = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Event> get pendingEvents => _pendingEvents;
  List<Event> get publishedEvents => _filteredPublishedEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPendingEmpty => _pendingEvents.isEmpty;
  bool get isPublishedEmpty => _filteredPublishedEvents.isEmpty;
  String get searchQuery => _searchQuery;

  Future<void> loadPendingEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingEvents = await _eventRepository.obtenerEventosPendientesAdmin();
    } catch (e) {
      _error = 'Error al cargar eventos pendientes';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPublishedEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _publishedEvents = await _eventRepository.obtenerEventosAprobados();
      _applySearchFilter();
    } catch (e) {
      _error = 'Error al cargar eventos publicados';
    }

    _isLoading = false;
    notifyListeners();
  }

  void searchPublishedEvents(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredPublishedEvents = _publishedEvents;
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredPublishedEvents = _publishedEvents
          .where(
            (event) =>
                event.title.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query) ||
                event.location.toLowerCase().contains(query),
          )
          .toList();
    }
  }

  Future<bool> approveEvent(int eventId) async {
    try {
      final success = await _eventRepository.aprobarEvento(eventId);
      if (success) {
        _pendingEvents.removeWhere((e) => int.tryParse(e.id) == eventId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectEvent(int eventId) async {
    return deleteEvent(eventId);
  }

  Future<bool> deleteEvent(int eventId) async {
    _logDelete("Iniciando eliminación de evento ID: $eventId");
    try {
      _logDelete("Paso 1/3: Llamando al repositorio para eliminar...");
      final success = await _eventRepository.eliminarEvento(eventId);

      if (success) {
        _logDelete("Paso 2/3: ✅ Repositorio confirmó eliminación");
        _logDelete("Paso 3/3: Actualizando listas en memoria...");
        _pendingEvents.removeWhere((e) => int.tryParse(e.id) == eventId);
        _logDelete("  - Removido de eventos pendientes");
        _publishedEvents.removeWhere((e) => int.tryParse(e.id) == eventId);
        _logDelete("  - Removido de eventos publicados");
        _applySearchFilter();
        _logDelete("  - Filtros reaplica dos");
        _logDelete("✅ Evento $eventId eliminado completamente");
        notifyListeners();
      } else {
        _logDeleteError("❌ El repositorio devolvió false para evento $eventId");
      }
      return success;
    } catch (e, stacktrace) {
      _logDeleteError("❌ Excepción durante eliminación: $e");
      _logDeleteError("Stack: $stacktrace");
      return false;
    }
  }

  void _logDelete(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    print("[DELETE] [$timestamp] $message");
  }

  void _logDeleteError(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    print("[DELETE ERROR] [$timestamp] $message");
  }
}
