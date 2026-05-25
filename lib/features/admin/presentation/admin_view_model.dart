import 'package:flutter/foundation.dart';

import '../../../data/repositories/evento_repository.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/event_repository_contract.dart';

class AdminViewModel extends ChangeNotifier {
  AdminViewModel({EventRepositoryContract? eventRepository})
    : _eventRepository = eventRepository ?? EventoRepository();

  final EventRepositoryContract _eventRepository;

  List<Event> _pendingEvents = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get pendingEvents => _pendingEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _pendingEvents.isEmpty;

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
    try {
      final success = await _eventRepository.eliminarEvento(eventId);
      if (success) {
        _pendingEvents.removeWhere((e) => int.tryParse(e.id) == eventId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}
