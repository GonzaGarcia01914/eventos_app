import 'package:flutter/material.dart';

import '../../domain/entities/event_type.dart';

abstract final class EventTypeVisuals {
  static IconData icon(EventType type) {
    return switch (type) {
      EventType.music => Icons.music_note_rounded,
      EventType.movies => Icons.movie_creation_rounded,
      EventType.social => Icons.groups_rounded,
      EventType.food => Icons.restaurant_rounded,
      EventType.culture => Icons.palette_rounded,
      EventType.sports => Icons.sports_soccer_rounded,
      EventType.tech => Icons.memory_rounded,
      EventType.nightlife => Icons.nightlife_rounded,
      EventType.other => Icons.event_rounded,
    };
  }

  static Color color(EventType type) {
    return switch (type) {
      EventType.music => const Color(0xFF8E63FF),
      EventType.movies => const Color(0xFF00B8D9),
      EventType.social => const Color(0xFFFFB020),
      EventType.food => const Color(0xFFFF7043),
      EventType.culture => const Color(0xFFE040FB),
      EventType.sports => const Color(0xFF00C853),
      EventType.tech => const Color(0xFF40C4FF),
      EventType.nightlife => const Color(0xFFFF4081),
      EventType.other => const Color(0xFF9E9E9E),
    };
  }
}
