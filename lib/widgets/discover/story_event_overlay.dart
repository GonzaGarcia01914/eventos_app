import 'package:flutter/material.dart';

import '../../domain/entities/event.dart';
import 'story_event_info_card.dart';

class StoryEventOverlay extends StatelessWidget {
  const StoryEventOverlay({
    super.key,
    required this.event,
    this.bottomInset = 0,
    this.onInfoTap,
  });

  final Event event;
  final double bottomInset;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 48, 20, 28 + bottomInset),
          child: StoryEventInfoCard(event: event, onTap: onInfoTap),
        ),
      ),
    );
  }
}
