/// Categorias de evento para busqueda y filtros.
enum EventType {
  music('Musica'),
  movies('Peliculas'),
  social('Social'),
  food('Gastronomia'),
  culture('Cultura'),
  sports('Deportes'),
  tech('Tecnologia'),
  nightlife('Vida nocturna'),
  other('Otros');

  const EventType(this.label);

  final String label;

  static const List<EventType> filterable = EventType.values;
}
