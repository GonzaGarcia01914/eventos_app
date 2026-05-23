import 'package:flutter/material.dart';

class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.segmentCount,
    required this.currentIndex,
    required this.currentProgress,
  });

  final int segmentCount;
  final int currentIndex;
  final double currentProgress;

  @override
  Widget build(BuildContext context) {
    if (segmentCount == 0) return const SizedBox.shrink();

    return Row(
      children: List.generate(segmentCount, (index) {
        final progress = index < currentIndex
            ? 1.0
            : index == currentIndex
                ? currentProgress.clamp(0.0, 1.0)
                : 0.0;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < segmentCount - 1 ? 4 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}
