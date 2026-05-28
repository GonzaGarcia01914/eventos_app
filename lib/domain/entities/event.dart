import '../../core/utils/guarani_formatter.dart';
import 'event_type.dart';

/// Entidad de dominio: evento.
class Event {
  const Event({
    required this.id,
    required this.title,
    this.description = '',
    required this.location,
    required this.startAt,
    required this.priceLabel,
    required this.priceAmount,
    required this.type,
    required this.latitude,
    required this.longitude,
    List<EventType>? types,
    this.imageUrl,
    this.videoUrl,
    this.timezone,
  }) : types = types ?? const [];

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final String location;
  final DateTime startAt;
  final String priceLabel;
  final int priceAmount;
  final EventType type;
  final List<EventType> types;
  final double latitude;
  final double longitude;
  final String? timezone;

  bool get isFree => priceAmount == 0;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// Precio legible en guaraníes (ej. «Veinticinco mil guaraníes»).
  String get displayPrice => GuaraniFormatter.formatInWords(priceAmount);
  List<EventType> get eventTypes => types.isEmpty ? [type] : types;

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? location,
    DateTime? startAt,
    String? priceLabel,
    int? priceAmount,
    EventType? type,
    List<EventType>? types,
    double? latitude,
    double? longitude,
    String? timezone,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      location: location ?? this.location,
      startAt: startAt ?? this.startAt,
      priceLabel: priceLabel ?? this.priceLabel,
      priceAmount: priceAmount ?? this.priceAmount,
      type: type ?? this.type,
      types: types ?? this.types,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'location': location,
        'startAt': startAt.toIso8601String(),
        'priceLabel': priceLabel,
        'priceAmount': priceAmount,
        'type': type.name,
        'types': eventTypes.map((value) => value.name).toList(),
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
      };

  factory Event.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final type = EventType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => EventType.other,
    );
    final typesJson = json['types'] as List<dynamic>? ?? const [];
    final types = typesJson
        .whereType<String>()
        .map(
          (typeName) => EventType.values.firstWhere(
            (value) => value.name == typeName,
            orElse: () => EventType.other,
          ),
        )
        .toSet()
        .toList();

    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      location: json['location'] as String,
      startAt: DateTime.parse(json['startAt'] as String),
      priceLabel: json['priceLabel'] as String,
      priceAmount: json['priceAmount'] as int? ?? 0,
      type: type,
      types: types.isEmpty ? [type] : types,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String?,
    );
  }
}
