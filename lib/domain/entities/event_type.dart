/// Categorías de evento para búsqueda y filtros.
enum EventType {
  music('Música'),
  comedy('Comedia'),
  food('Gastronomía'),
  culture('Cultura'),
  sports('Deportes'),
  tech('Tecnología'),
  nightlife('Vida nocturna'),
  other('Otros');

  const EventType(this.label);

  final String label;

  static const List<EventType> filterable = EventType.values;
}
