import 'event_type.dart';

/// Entidad de dominio: evento.
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.location,
    required this.startAt,
    required this.priceLabel,
    required this.priceAmount,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.videoUrl,
    this.timezone,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? videoUrl;
  final String location;
  final DateTime startAt;
  final String priceLabel;
  final int priceAmount;
  final EventType type;
  final double latitude;
  final double longitude;
  final String? timezone;

  bool get isFree => priceAmount == 0;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  Event copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? videoUrl,
    String? location,
    DateTime? startAt,
    String? priceLabel,
    int? priceAmount,
    EventType? type,
    double? latitude,
    double? longitude,
    String? timezone,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      location: location ?? this.location,
      startAt: startAt ?? this.startAt,
      priceLabel: priceLabel ?? this.priceLabel,
      priceAmount: priceAmount ?? this.priceAmount,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'location': location,
        'startAt': startAt.toIso8601String(),
        'priceLabel': priceLabel,
        'priceAmount': priceAmount,
        'type': type.name,
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

    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      location: json['location'] as String,
      startAt: DateTime.parse(json['startAt'] as String),
      priceLabel: json['priceLabel'] as String,
      priceAmount: json['priceAmount'] as int? ?? 0,
      type: type,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String?,
    );
  }
}
